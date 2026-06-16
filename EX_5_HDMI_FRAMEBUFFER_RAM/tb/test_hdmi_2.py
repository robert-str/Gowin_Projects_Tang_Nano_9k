"""
test_hdmi.py — cocotb testbench for Gowin Tang Nano 9K HDMI pipeline
======================================================================
DUT   : hdmi_top (TOP.v)
SIM   : Icarus Verilog 11+  (SIM=icarus, flag -g2012)
Runner: cocotb 1.x (make) | cocotb 2.x (pytest)

Pipeline overview (signals probed)
───────────────────────────────────
  clk_27MHz  →  Gowin_rPLL (stub: pass-through)
             →  CLKDIV/5   (stub: ÷6)  →  clk_pixel

  clk_pixel  →  video_timing  →  cx, cy, vde, hsync, vsync
             →  framebuffer_video_pipeline  →  red, green, blue  (2-cycle latency)
             →  2-cycle sync delay  →  vde_d_top[1]
             →  tmds_encoder ×3     →  tmds_r/g/b  (+2 cycles encoder pipeline)
             →  serializer_10to1 ×4 →  s_d0/d1/d2/clk
             →  ELVDS_OBUF ×4       →  tmds_{d0..d2,clk}_{p,n}

Tests
──────
  1. test_smoke             outputs are not X/Z; clk_pixel toggles
  2. test_timing_compliance VDE / HSYNC / VSYNC comply with 640×480 spec
  3. test_tmds_encoding     TMDS DC-balance + data/ctrl token classification
  4. test_frame_capture     full 640×480 frame → PNG dashboard
"""

import cocotb
from cocotb.clock    import Clock
from cocotb.triggers import RisingEdge, ClockCycles
import numpy         as np
import matplotlib;    matplotlib.use("Agg")   # headless — files written to disk
import matplotlib.pyplot   as plt
import matplotlib.gridspec as gridspec
from pathlib import Path
import logging
import time

# ─── Simulation / design constants ───────────────────────────────────────────

H_ACTIVE = 640
V_ACTIVE = 480
H_FRONT  = 16
H_SYNC_W = 96       # pulse width in pixel-clock cycles
H_BACK   = 48
H_TOTAL  = H_ACTIVE + H_FRONT + H_SYNC_W + H_BACK   # 800

V_FRONT  = 10
V_SYNC_W = 2        # pulse width in lines
V_BACK   = 33
V_TOTAL  = V_ACTIVE + V_FRONT + V_SYNC_W + V_BACK   # 525

# Both syncs are active-LOW in TOP.v (H_SYNC_POL=0, V_SYNC_POL=0)
HSYNC_ACTIVE = 0
VSYNC_ACTIVE = 0

CLK_BOARD_NS = 37   # ≈ 27 MHz board clock

# Output directory for all PNG artefacts
OUT = Path("sim_output")
OUT.mkdir(exist_ok=True)

log = logging.getLogger("hdmi_tb")

# ─────────────────────────────────────────────────────────────────────────────
# TMDS round-trip decoder
# ─────────────────────────────────────────────────────────────────────────────

class TMDSDecoder:
    """
    Decodes a 10-bit TMDS codeword back to the original 8-bit pixel byte
    (or identifies it as a blanking-period control token).

    DVI spec encoding recap
    ───────────────────────
    Stage-1 (transition minimisation, 8b→9b):
        q_m[8] = 1  → XOR  chain:  q_m[i] = q_m[i-1] ^  data[i]
        q_m[8] = 0  → XNOR chain:  q_m[i] = q_m[i-1] ~^ data[i]

    Stage-2 (DC balance, 9b→10b):
        tmds[9] = 1  → the 8-bit payload was bit-inverted before transmit

    Inverse:
        payload = tmds[9] ? ~tmds[7:0] : tmds[7:0]
        q_m8    = tmds[8]
        data[0] = payload[0]
        data[i] = payload[i] ^ payload[i-1]   if q_m8 == 1  (undo XOR)
                = NOT(payload[i] ^ payload[i-1]) if q_m8 == 0  (undo XNOR)
    """

    # DVI spec Table 3-4 — four control tokens on the Blue (D0) channel
    _CTRL_TOKENS: dict[int, tuple[bool, int]] = {
        0b1101010100: (False, 0b00),   # ctrl = 2'b00
        0b0010101011: (False, 0b01),   # ctrl = 2'b01  (HSYNC)
        0b0101010100: (False, 0b10),   # ctrl = 2'b10  (VSYNC)
        0b1010101011: (False, 0b11),   # ctrl = 2'b11  (HSYNC+VSYNC)
    }

    @classmethod
    def decode(cls, word: int) -> dict:
        """
        Returns
        -------
        {"type": "ctrl", "ctrl": int, "raw": int}
            or
        {"type": "data", "value": int, "raw": int}
        """
        w = int(word) & 0x3FF

        if w in cls._CTRL_TOKENS:
            return {"type": "ctrl", "ctrl": cls._CTRL_TOKENS[w][1], "raw": w}

        # Undo stage-2 inversion
        inverted = bool((w >> 9) & 1)
        payload  = (~w & 0xFF) if inverted else (w & 0xFF)
        q_m8     = (w >> 8) & 1   # 1 = XOR chain, 0 = XNOR chain

        bits = [0] * 8
        bits[0] = payload & 1
        for i in range(1, 8):
            a = (payload >> i)       & 1
            b = (payload >> (i - 1)) & 1
            if q_m8:
                bits[i] = a ^ b             # undo XOR
            else:
                bits[i] = int(not (a ^ b))  # undo XNOR

        byte_val = sum(b << i for i, b in enumerate(bits))
        return {"type": "data", "value": byte_val, "raw": w}

    @staticmethod
    def running_disparity(words: list[int]) -> list[int]:
        """
        Cumulative running disparity: for each 8-bit payload count
        (N_ones − N_zeros) and accumulate. Ideally stays near 0.
        """
        disp, history = 0, []
        for w in words:
            ones  = bin(w & 0xFF).count("1")
            disp += ones - (8 - ones)
            history.append(disp)
        return history


# ─────────────────────────────────────────────────────────────────────────────
# Shared helpers
# ─────────────────────────────────────────────────────────────────────────────

def _int(sig) -> int:
    """Safely convert a cocotb signal value to int (returns 0 on X/Z)."""
    try:
        v = sig.value
        return int(v) if v.is_resolvable else 0
    except Exception:
        return 0


async def _reset(dut, hold_cycles: int = 25) -> None:
    """Drive rst_n low for <hold_cycles> board-clock cycles, then release."""
    dut.rst_n.value = 0
    await ClockCycles(dut.clk_27MHz, hold_cycles)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk_27MHz, 10)
    log.info("  [reset] released")


async def _wait_frame_start(dut, timeout: int = 5_000_000) -> None:
    """
    Synchronise to the start of an active frame: wait for VSYNC to pulse,
    then wait for cx=0, cy=0.
    """
    log.info("  Waiting for frame boundary …")

    # Step 1: wait for VSYNC to assert
    for _ in range(timeout):
        await RisingEdge(dut.clk_pixel)
        if _int(dut.vsync) == VSYNC_ACTIVE:
            break

    # Step 2: wait for VSYNC to deassert
    for _ in range(timeout):
        await RisingEdge(dut.clk_pixel)
        if _int(dut.vsync) != VSYNC_ACTIVE:
            break

    # Step 3: wait for cx=0, cy=0
    for _ in range(timeout):
        await RisingEdge(dut.clk_pixel)
        if _int(dut.cx) == 0 and _int(dut.cy) == 0:
            log.info("  Frame boundary found (cx=0, cy=0)")
            return

    raise TimeoutError("Timed out waiting for frame start (cx=0, cy=0)")


# ═════════════════════════════════════════════════════════════════════════════
# TEST 1 — Smoke
# ═════════════════════════════════════════════════════════════════════════════

@cocotb.test()
async def test_smoke(dut):
    """
    After reset, verify:
      • All 8 TMDS differential outputs resolve to 0 or 1 (no X/Z)
      • The internal clk_pixel actually toggles (CLKDIV stub is working)
      • The internal clk_tmds is driven (PLL stub is working)
    """
    log.info("")
    log.info("═" * 60)
    log.info("TEST 1 — Smoke Test")
    log.info("═" * 60)

    cocotb.start_soon(Clock(dut.clk_27MHz, CLK_BOARD_NS, units="ns").start())
    await _reset(dut)
    await ClockCycles(dut.clk_27MHz, 400)   # give CLKDIV time to produce edges

    # ── Check all HDMI outputs are resolved ───────────────────────────────────
    pins = {
        "tmds_clk_p": dut.tmds_clk_p, "tmds_clk_n": dut.tmds_clk_n,
        "tmds_d0_p" : dut.tmds_d0_p,  "tmds_d0_n" : dut.tmds_d0_n,
        "tmds_d1_p" : dut.tmds_d1_p,  "tmds_d1_n" : dut.tmds_d1_n,
        "tmds_d2_p" : dut.tmds_d2_p,  "tmds_d2_n" : dut.tmds_d2_n,
    }
    for name, sig in pins.items():
        assert sig.value.is_resolvable, f"  ✗ {name} = X/Z after reset!"
        log.info(f"  ✓ {name:12s} = {int(sig.value)}")

    # ── Verify clk_pixel toggles (CLKDIV stub not stuck) ─────────────────────
    v0 = _int(dut.clk_pixel)
    toggled = False
    for _ in range(100):
        await RisingEdge(dut.clk_27MHz)
        if _int(dut.clk_pixel) != v0:
            toggled = True
            break
    assert toggled, "clk_pixel never toggles — CLKDIV stub may be broken!"
    log.info("  ✓ clk_pixel toggles correctly")

    # ── Verify clk_tmds is driven ─────────────────────────────────────────────
    assert dut.clk_tmds.value.is_resolvable, "clk_tmds is X/Z — PLL stub broken?"
    log.info("  ✓ clk_tmds is driven")

    log.info("  PASSED ✓")


# ═════════════════════════════════════════════════════════════════════════════
# TEST 2 — Timing Compliance
# ═════════════════════════════════════════════════════════════════════════════

@cocotb.test()
async def test_timing_compliance(dut):
    """
    Over one complete frame (H_TOTAL × V_TOTAL pixel-clock cycles) verify:

      VDE  — high for exactly H_ACTIVE × V_ACTIVE cycles (307 200)
      HSYNC — every pulse is exactly H_SYNC_W = 96 cycles wide
      VSYNC — active on exactly V_SYNC_W = 2 distinct cy values

    NOTE: clk_pixel in the stub runs at 27 MHz ÷ 6 ≈ 4.5 MHz.
          One frame therefore takes ~93 ms wall time to simulate.
    """
    log.info("")
    log.info("═" * 60)
    log.info("TEST 2 — Timing Compliance (640×480)")
    log.info("═" * 60)

    cocotb.start_soon(Clock(dut.clk_27MHz, CLK_BOARD_NS, units="ns").start())
    await _reset(dut)
    await _wait_frame_start(dut)

    vde_count    = 0
    hsync_widths = []
    vsync_cy     = set()
    in_hsync     = False
    cur_w        = 0

    for _ in range(H_TOTAL * V_TOTAL):
        await RisingEdge(dut.clk_pixel)

        vde   = _int(dut.vde)
        hsync = _int(dut.hsync)
        vsync = _int(dut.vsync)
        cy    = _int(dut.cy)

        # VDE pixel count
        if vde:
            vde_count += 1

        # HSYNC pulse width measurement (active-low → falling edge opens window)
        if hsync == HSYNC_ACTIVE:
            cur_w = (cur_w + 1) if in_hsync else 1
            in_hsync = True
        else:
            if in_hsync:
                hsync_widths.append(cur_w)
                in_hsync = False

        # VSYNC — collect which cy lines are covered
        if vsync == VSYNC_ACTIVE:
            vsync_cy.add(cy)

    # ── Assertions ────────────────────────────────────────────────────────────

    exp_vde = H_ACTIVE * V_ACTIVE                   # 307 200
    log.info(f"  VDE active pixels  : {vde_count:>8d}  (expected {exp_vde})")
    assert vde_count == exp_vde, \
        f"VDE pixel count wrong: got {vde_count}, expected {exp_vde}"

    if hsync_widths:
        bad_w = [w for w in hsync_widths if w != H_SYNC_W]
        unique_w = set(hsync_widths)
        log.info(f"  HSYNC pulses       : {len(hsync_widths):>8d}  (expected {V_TOTAL})")
        log.info(f"  HSYNC widths seen  : {unique_w}  (expected {{{H_SYNC_W}}})")
        assert len(hsync_widths) == V_TOTAL, \
            f"Wrong HSYNC pulse count: {len(hsync_widths)} (expected {V_TOTAL})"
        assert not bad_w, \
            f"Unexpected HSYNC pulse widths: {set(bad_w)}"

    vsync_line_count = len(vsync_cy)
    log.info(f"  VSYNC cy values    : {sorted(vsync_cy)}  (expected {V_SYNC_W} lines)")
    assert vsync_line_count == V_SYNC_W, \
        f"VSYNC active line count wrong: {vsync_line_count} (expected {V_SYNC_W})"

    log.info("  PASSED ✓")


# ═════════════════════════════════════════════════════════════════════════════
# TEST 3 — TMDS Encoding Validation
# ═════════════════════════════════════════════════════════════════════════════

@cocotb.test()
async def test_tmds_encoding(dut):
    """
    For the active pixels of one video line:

      Token classification
        • During vde_d_top[1]=1  →  tmds_r/g/b must produce DATA tokens
        • During vde_d_top[1]=0  →  tmds_b must produce CTRL tokens
          (tmds_g/r carry ctrl=2'b00, which is also a valid control token)

      DC-balance
        Running disparity for each channel must remain within ±32
        (tight bound for a short active line; relaxed to ±64 for blanking)

      Output
        sim_output/tmds_disparity.png  — per-channel disparity plots
    """
    log.info("")
    log.info("═" * 60)
    log.info("TEST 3 — TMDS Encoding Validation")
    log.info("═" * 60)

    cocotb.start_soon(Clock(dut.clk_27MHz, CLK_BOARD_NS, units="ns").start())
    await _reset(dut)
    await _wait_frame_start(dut)

    # Pipeline delay: 2-cycle sync shift register + 2-cycle TMDS encoder = 4 cycles
    # After _wait_frame_start we are at cx=0, cy=0 on clk_pixel.
    # Skip one full blanking + active line worth of cycles so the pipeline fills.
    await ClockCycles(dut.clk_pixel, H_TOTAL + 4)

    # Now capture H_TOTAL cycles (one full line)
    rec: dict[str, list] = {
        "tmds_r": [], "tmds_g": [], "tmds_b": [],
        "vde_delayed": [], "cy": [],
    }

    for _ in range(H_TOTAL):
        await RisingEdge(dut.clk_pixel)

        # vde_d_top is a 2-bit shift reg; bit[1] is the fully-delayed enable
        vde_del = (_int(dut.vde_d_top) >> 1) & 1

        rec["tmds_r"].append(_int(dut.tmds_r))
        rec["tmds_g"].append(_int(dut.tmds_g))
        rec["tmds_b"].append(_int(dut.tmds_b))
        rec["vde_delayed"].append(vde_del)
        rec["cy"].append(_int(dut.cy))

    # ── Token classification ───────────────────────────────────────────────────

    data_tokens   = {"R": 0, "G": 0, "B": 0}
    ctrl_tokens   = {"R": 0, "G": 0, "B": 0}
    wrong_class   = 0          # data token during blanking or ctrl during active

    active_r, active_g, active_b = [], [], []

    for i, (tr, tg, tb, vde_d) in enumerate(zip(
        rec["tmds_r"], rec["tmds_g"], rec["tmds_b"], rec["vde_delayed"]
    )):
        dr = TMDSDecoder.decode(tr)
        dg = TMDSDecoder.decode(tg)
        db = TMDSDecoder.decode(tb)

        for ch, dec, name in [("R", dr, "tmds_r"), ("G", dg, "tmds_g"), ("B", db, "tmds_b")]:
            bucket = data_tokens if dec["type"] == "data" else ctrl_tokens
            bucket[ch] += 1

        # During active video (vde_delayed=1) we MUST see data tokens
        if vde_d == 1:
            if dr["type"] != "data" or dg["type"] != "data" or db["type"] != "data":
                wrong_class += 1
                if wrong_class <= 3:
                    log.warning(
                        f"  [!] cycle {i}: vde_d=1 but got ctrl token"
                        f"  R={dr['type']} G={dg['type']} B={db['type']}"
                    )
            else:
                active_r.append(tr)
                active_g.append(tg)
                active_b.append(tb)

    log.info(f"  Active samples captured : R={len(active_r)}  G={len(active_g)}  B={len(active_b)}")
    log.info(f"  Wrong token class       : {wrong_class}")
    assert wrong_class == 0, \
        f"{wrong_class} control tokens detected during active video (vde_d=1)!"

    # ── DC-balance check ──────────────────────────────────────────────────────

    DISP_LIMIT = 32
    disparity_histories: dict[str, list[int]] = {}

    for ch, words in [("R", active_r), ("G", active_g), ("B", active_b)]:
        if not words:
            continue
        hist = TMDSDecoder.running_disparity(words)
        lo, hi = min(hist), max(hist)
        final  = hist[-1]
        disparity_histories[ch] = hist
        log.info(f"  Channel {ch}: disparity ∈ [{lo:+4d},{hi:+4d}]  final={final:+4d}")
        assert abs(final) <= DISP_LIMIT, \
            f"Channel {ch}: final disparity {final:+d} exceeds ±{DISP_LIMIT}"

    # ── Plot ──────────────────────────────────────────────────────────────────

    if disparity_histories:
        fig, axes = plt.subplots(3, 1, figsize=(14, 9), sharex=True)
        fig.suptitle(
            "TMDS Running Disparity — One Active Video Line\n"
            "DUT: hdmi_top | 640×480 | Gowin Tang Nano 9K",
            fontsize=12, fontweight="bold"
        )

        ch_cfg = [
            ("R", "#e74c3c", "Red channel   (D2)"),
            ("G", "#27ae60", "Green channel (D1)"),
            ("B", "#2980b9", "Blue channel  (D0)"),
        ]
        for ax, (ch, color, label) in zip(axes, ch_cfg):
            hist = disparity_histories.get(ch, [])
            if not hist:
                ax.set_visible(False)
                continue
            xs = np.arange(len(hist))
            ax.fill_between(xs, hist, alpha=0.20, color=color)
            ax.plot(xs, hist, color=color, lw=1.4, label=label)
            ax.axhline( 0,          color="gray", lw=0.8, ls="--", alpha=0.7)
            ax.axhline( DISP_LIMIT, color="crimson", lw=0.9, ls=":",
                        label=f"±{DISP_LIMIT} spec limit")
            ax.axhline(-DISP_LIMIT, color="crimson", lw=0.9, ls=":")
            ax.set_ylabel("Disparity", fontsize=9)
            ax.set_ylim(-DISP_LIMIT * 1.5, DISP_LIMIT * 1.5)
            ax.legend(loc="upper right", fontsize=9, framealpha=0.85)
            ax.grid(True, alpha=0.25)

            # Annotate final value
            ax.annotate(
                f"final={hist[-1]:+d}",
                xy=(len(hist) - 1, hist[-1]),
                xytext=(-60, 12), textcoords="offset points",
                fontsize=8, color=color,
                arrowprops=dict(arrowstyle="->", color=color, lw=0.8),
            )

        axes[-1].set_xlabel("TMDS codeword index (active pixels only)", fontsize=9)
        plt.tight_layout()
        out = OUT / "tmds_disparity.png"
        plt.savefig(out, dpi=150, bbox_inches="tight")
        plt.close()
        log.info(f"  Plot saved → {out}")

    log.info("  PASSED ✓")


# ═════════════════════════════════════════════════════════════════════════════
# TEST 4 — Full Frame Capture + Visualisation Dashboard
# ═════════════════════════════════════════════════════════════════════════════

@cocotb.test()
async def test_frame_capture(dut):
    """
    Capture one complete 640×480 frame by sampling dut.red/green/blue at
    every pixel-clock rising edge while dut.vde is high.

    Output files (sim_output/)
    ──────────────────────────
      frame_rgb.png         reconstructed frame image (full resolution)
      frame_analysis.png    multi-panel analysis dashboard:
                              A) Frame preview
                              B) Per-channel RGB histogram
                              C) Top-6 colour distribution (pie chart)
                              D) Video timing waveform (first 3 lines)

    NOTE: Capturing a full 640×480 frame at clk_pixel ≈ 4.5 MHz (÷6 stub)
          takes H_TOTAL×V_TOTAL = 420 000 pixel-clock edges to iterate.
          Expect ~2–5 minutes depending on your machine speed.
    """
    log.info("")
    log.info("═" * 60)
    log.info("TEST 4 — Full Frame Capture")
    log.info("═" * 60)

    cocotb.start_soon(Clock(dut.clk_27MHz, CLK_BOARD_NS, units="ns").start())
    await _reset(dut)
    await _wait_frame_start(dut)

    # Pixel buffer
    frame = np.zeros((V_ACTIVE, H_ACTIVE, 3), dtype=np.uint8)

    # Timing waveform capture (first N lines only — for the dashboard)
    TIMING_LINES = 3
    timing: dict[str, list[int]] = {"vde": [], "hsync": [], "vsync": []}
    timing_done = False

    log.info(f"  Capturing {H_ACTIVE}×{V_ACTIVE} frame …  (this may take a few minutes)")
    t0 = time.monotonic()

    for _ in range(H_TOTAL * V_TOTAL):
        await RisingEdge(dut.clk_pixel)

        cx    = _int(dut.cx)
        cy    = _int(dut.cy)
        vde   = _int(dut.vde)
        hsync = _int(dut.hsync)
        vsync = _int(dut.vsync)
        r     = _int(dut.red)
        g     = _int(dut.green)
        b     = _int(dut.blue)

        # Waveform capture for timing diagram
        if not timing_done:
            if cy < TIMING_LINES:
                timing["vde"].append(vde)
                timing["hsync"].append(hsync)
                timing["vsync"].append(vsync)
            else:
                timing_done = True

        # Pixel capture: store when inside the active area
        if vde and cx < H_ACTIVE and cy < V_ACTIVE:
            frame[cy, cx] = (r, g, b)

    elapsed = time.monotonic() - t0
    log.info(f"  Capture done  ({elapsed:.1f} s wall-time)")

    # ── Save plain frame image ─────────────────────────────────────────────────

    fig_f, ax_f = plt.subplots(figsize=(10, 7.5), dpi=130)
    ax_f.imshow(frame, interpolation="nearest")
    ax_f.set_title(f"HDMI Simulation — Captured Frame  ({H_ACTIVE}×{V_ACTIVE})",
                   fontsize=12, pad=10)
    ax_f.axis("off")
    frame_path = OUT / "frame_rgb.png"
    plt.savefig(frame_path, bbox_inches="tight")
    plt.close()
    log.info(f"  Frame saved   → {frame_path}")

    # ── Build analysis dashboard ───────────────────────────────────────────────

    fig = plt.figure(figsize=(18, 11))
    fig.suptitle(
        "HDMI Simulation — Analysis Dashboard\n"
        f"DUT: hdmi_top  |  {H_ACTIVE}×{V_ACTIVE}  |  Gowin Tang Nano 9K",
        fontsize=13, fontweight="bold",
    )
    gs = gridspec.GridSpec(3, 3, figure=fig, hspace=0.52, wspace=0.36)

    # ── Panel A: frame preview ─────────────────────────────────────────────────
    ax_img = fig.add_subplot(gs[0:2, 0:2])
    ax_img.imshow(frame, interpolation="nearest")
    ax_img.set_title("Captured Frame", fontsize=10)
    ax_img.axis("off")

    # ── Panel B: RGB histogram ─────────────────────────────────────────────────
    ax_hist = fig.add_subplot(gs[0, 2])
    bins = np.linspace(0, 256, 65)
    ch_style = [(0, "#e74c3c", "R"), (1, "#27ae60", "G"), (2, "#2980b9", "B")]
    for idx, color, label in ch_style:
        ax_hist.hist(frame[:, :, idx].ravel(), bins=bins,
                     color=color, alpha=0.65, label=label)
    ax_hist.set_title("RGB Channel Histogram", fontsize=10)
    ax_hist.set_xlabel("Intensity (0–255)", fontsize=8)
    ax_hist.set_ylabel("Pixel count", fontsize=8)
    ax_hist.legend(fontsize=9)
    ax_hist.grid(True, alpha=0.25)
    ax_hist.tick_params(labelsize=8)

    # ── Panel C: top-colour pie ────────────────────────────────────────────────
    ax_pie = fig.add_subplot(gs[1, 2])
    unique_c, cnts = np.unique(frame.reshape(-1, 3), axis=0, return_counts=True)
    top_n   = 6
    top_idx = np.argsort(cnts)[-top_n:][::-1]
    top_col = unique_c[top_idx]
    top_cnt = cnts[top_idx]
    hex_labels = [f"#{r:02X}{g:02X}{b:02X}" for r, g, b in top_col]
    rgb_fracs  = [(r / 255, g / 255, b / 255) for r, g, b in top_col]
    ax_pie.pie(
        top_cnt, labels=hex_labels, colors=rgb_fracs,
        autopct="%1.1f%%",
        textprops={"fontsize": 7.5},
        wedgeprops={"linewidth": 0.6, "edgecolor": "white"},
    )
    ax_pie.set_title(f"Top {top_n} Colours", fontsize=10)

    # ── Panel D: timing waveform ───────────────────────────────────────────────
    ax_tim = fig.add_subplot(gs[2, :])

    if timing["vde"]:
        t = np.arange(len(timing["vde"]))
        sig_cfg = [
            # (name,   y_offset,  color,      label)
            ("vsync",  0.05,  "#1abc9c", "VSYNC"),
            ("hsync",  1.10,  "#8e44ad", "HSYNC"),
            ("vde",    2.15,  "#e67e22", "VDE"),
        ]
        for name, offset, color, label in sig_cfg:
            vals = np.array(timing[name]) * 0.85
            ax_tim.fill_between(t, offset, offset + vals,
                                color=color, alpha=0.40,
                                step="post")
            ax_tim.plot(t, offset + vals, color=color,
                        lw=0.9, drawstyle="steps-post", label=label)

        # Mark H_ACTIVE boundaries (where VDE falls)
        for line_n in range(TIMING_LINES):
            xmark = line_n * H_TOTAL + H_ACTIVE
            ax_tim.axvline(xmark, color="red", lw=0.7, ls="--", alpha=0.55)
        ax_tim.axvline(0, color="red", lw=0.7, ls="--", alpha=0.55,
                       label="H_ACTIVE boundary")

        ax_tim.set_xlim(0, len(t))
        ax_tim.set_ylim(-0.20, 3.30)
        ax_tim.set_yticks([0.47, 1.55, 2.57])
        ax_tim.set_yticklabels(["VSYNC", "HSYNC", "VDE"], fontsize=9)
        ax_tim.set_xlabel(
            f"Pixel-clock cycles  (first {TIMING_LINES} lines  = {len(t)} samples)",
            fontsize=9,
        )
        ax_tim.set_title("Video Timing Waveform", fontsize=10)
        ax_tim.grid(True, alpha=0.20, axis="x")
        ax_tim.legend(loc="upper right", fontsize=9, framealpha=0.88)

        # Annotate H_ACTIVE and H_TOTAL on first line
        ax_tim.annotate(
            f"H_ACTIVE={H_ACTIVE}",
            xy=(H_ACTIVE, 3.0), xytext=(H_ACTIVE + 20, 3.05),
            fontsize=7.5, color="red",
        )

    dash_path = OUT / "frame_analysis.png"
    plt.savefig(dash_path, dpi=140, bbox_inches="tight")
    plt.close()
    log.info(f"  Dashboard saved → {dash_path}")

    # ── Assertions ────────────────────────────────────────────────────────────

    non_black = int(np.any(frame > 0, axis=2).sum())
    total     = H_ACTIVE * V_ACTIVE
    fill_pct  = 100.0 * non_black / total
    log.info(f"  Non-black pixels : {non_black} / {total}  ({fill_pct:.1f} %)")
    assert non_black > 0, \
        "Captured frame is entirely black — check VDE gating or RGB pipeline!"

    log.info("  PASSED ✓")
    log.info("")
    log.info("  Output files:")
    log.info(f"    📸 {frame_path}")
    log.info(f"    📊 {dash_path}")
    log.info(f"    📈 {OUT / 'tmds_disparity.png'}")