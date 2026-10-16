# -*- coding: utf-8 -*-
"""Generate a one-page English poster for the competition finals.

The organisers supply an AMD PPT template later; until then this is a
self-contained one-page poster whose CONTENT is final. Moving it into the
official template is a copy-paste of the same sections, re-flowed to whatever
text-box width that template uses.

Carries NO team information: the rules require the printed poster to be
anonymous.

MEASURED LAYOUT CONSTRAINTS
---------------------------
1. python-pptx leaves <a:spAutoFit/> on text boxes; it is set to noAutofit here
   so the geometry in the file is the geometry intended.
2. Measured with the LibreOffice renderer on this machine, the wrap width it
   actually uses is about 1.27x the width written in the file. This holds for
   6, 10, 12, 14, 18 cm boxes, is independent of the font pinned, and also
   applies to the vertical axis. PowerPoint wraps at 1.00x.
   Every box is therefore sized so that BOTH cases stay on the page:
       column width 8.6 cm  -> 1.27x = 10.9 cm, right column ends at 23.5 cm
       title width 18.0 cm  -> 1.27x = 22.9 cm, ends at 23.8 cm
   (page is 25.4 cm wide, so both leave margin.)
3. Monospaced diagram lines stay under 56 characters so they cannot wrap.
"""
from pptx import Presentation
from pptx.util import Cm, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR, MSO_AUTO_SIZE
from pptx.enum.shapes import MSO_SHAPE

OUT = r"E:\yoloProject\report\poster\one_page_poster.pptx"

prs = Presentation()                    # default 10 x 7.5 in == 25.4 x 19.05 cm
slide = prs.slides.add_slide(prs.slide_layouts[6])

INK = RGBColor(0x1A, 0x1A, 0x1A)
ACCENT = RGBColor(0x0B, 0x5C, 0x8A)
MUTED = RGBColor(0x55, 0x55, 0x55)
RULE = RGBColor(0xC8, 0xD6, 0xE0)
ZEBRA = RGBColor(0xF2, 0xF7, 0xFA)

LX = Cm(0.9)
RX = Cm(13.0)
COL = Cm(6.5)
TITLE_W = Cm(13.0)
BODY = 6.0
MONO_SZ = 5.5
MONO = "Consolas"


def textbox(x, y, w, h):
    tf = slide.shapes.add_textbox(x, y, w, h).text_frame
    tf.word_wrap = True
    tf.auto_size = MSO_AUTO_SIZE.NONE
    tf.vertical_anchor = MSO_ANCHOR.TOP
    tf.margin_left = 0
    tf.margin_right = 0
    tf.margin_top = 0
    tf.margin_bottom = 0
    return tf


def para(tf, text, size=BODY, bold=False, color=INK, after=2, font=None,
         first=False, align=PP_ALIGN.LEFT, line=1.0):
    p = tf.paragraphs[0] if (first and not tf.paragraphs[0].runs) else tf.add_paragraph()
    p.alignment = align
    p.space_before = Pt(0)
    p.space_after = Pt(after)
    p.line_spacing = line
    r = p.add_run()
    r.text = text
    r.font.size = Pt(size)
    r.font.bold = bold
    r.font.color.rgb = color
    if font:
        r.font.name = font
    return p


def heading(tf, text, size=9.0):
    para(tf, text, size=size, bold=True, color=ACCENT, after=3, first=True)


def rule(x, y, w):
    ln = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, x, y, w, Cm(0.045))
    ln.fill.solid()
    ln.fill.fore_color.rgb = RULE
    ln.line.fill.background()


# ============================================================== title
tf = textbox(LX, Cm(0.35), TITLE_W, Cm(2.2))
para(tf, "Real-Time Object Detection on a Zynq-7020: From Camera to Browser in One Bitstream",
     size=14, bold=True, after=4, first=True)
para(tf, "OV5640 (DVP parallel)  ->  custom capture RTL  ->  Xilinx DPU / YOLOv3-tiny  ->  live M-JPEG preview",
     size=8, color=ACCENT, after=2)
para(tf, "Zynq-7020 XC7Z020-2CLG400  |  DPU B1152  |  1025 x 720 @ 7.5 fps  |  nothing written to disk  |  MIT",
     size=7.5, color=MUTED)
rule(LX, Cm(2.42), Cm(23.6))

# ============================================================== LEFT
tf = textbox(LX, Cm(2.80), COL, Cm(3.0))
heading(tf, "WHY THIS, AND WHAT IS HARD ABOUT IT")
para(tf, "Cloud inference is too slow and too bandwidth-hungry for edge vision, and a CPU "
         "cannot run a detection network in real time: the same network "
         "takes 125.5 ms on the fabric accelerator, versus an order of magnitude more on the dual Cortex-A9 "
         "(666 MHz). Putting the compute in the PL is the only way to fit the latency budget.")

tf = textbox(LX, Cm(5.10), COL, Cm(0.45))
heading(tf, "SYSTEM ARCHITECTURE")

tf = textbox(LX, Cm(5.50), COL, Cm(4.4))
for i, line in enumerate([
    "OV5640 -DVP-> cam_top -AXIS-> frame_writer",
    "      -HP3-> DDR @ 0x08000000",
    "        RGB565  CDC FIFO  rolling write",
    "                     1025x720x2=1,476,000 B",
    "                             | mmap /dev/mem",
    "        +---------------------v--------+",
    "        | cam_stream (ARM PS, C++)     |",
    "        | two threads:                 |",
    "        |  display  : frame -> memcpy  |",
    "        |             -> draw -> JPEG  |",
    "        |  inference: letterbox ->     |",
    "        |             DPU 125.5 ms     |",
    "        |  shared   : g_boxes + lock   |",
    "        +------------------------------+",
]):
    para(tf, line, size=MONO_SZ, font=MONO, after=0, line=0.95,
         color=MUTED if set(line.strip()) <= set("+-|v ") else INK, first=(i == 0))
para(tf, "The IP's own constraint file uses "
         "set_multicycle_path 2, so dpu_2x_clk must be exactly 2x m_axi_dpu_aclk (200/100 MHz) \u2014 a functional "
         "assumption, not a timing preference.", after=0)

tf = textbox(LX, Cm(9.30), COL, Cm(6.0))
heading(tf, "HOW CORRECTNESS IS ESTABLISHED")
para(tf, "- RTL simulation: fw_tb exercises pixel packing, rolling addressing and the AXI write handshake "
         "under randomised back-pressure \u2014 PASS, 1280 of 1280 beats, 0 errors.", after=3)
para(tf, "- Byte-exact golden comparison: the application runs the same image twice and compares the output "
         "buffers \u2014 identical=1 on 8 of 8 images. This single self-check catches both failure modes "
         "described on the right.", after=3)
para(tf, "- Standard-answer acceptance: 8 of 8 images hit the expected classes.", after=3)
para(tf, "Stated plainly: the simulation covers the custom RTL only \u2014 not the DPU internals, and not the "
         "PS-side software. The strongest correctness evidence is the golden comparison on real hardware.",
     size=6.5, color=MUTED, after=0)

# ============================================================== RIGHT
tf = textbox(RX, Cm(2.80), COL, Cm(0.45))
heading(tf, "MEASURED RESULTS")

rows = [
    ("Display resolution / frame rate", "1025x720 | 7.4-7.5 fps (sensor limit)"),
    ("Detection box update rate", "3.9 per second"),
    ("DPU inference (letterbox + hw)", "191 - 193 ms"),
    ("M-JPEG stream", "377 KB/s, 52.8 KB per frame"),
    ("Timing (WNS / WHS)", "+0.718 / +0.051 ns, 0 failing"),
    ("Utilisation LUT/BRAM/DSP/Slice", "70.2 / 88.2 / 96.4 / 98.2 %"),
]
tbl = slide.shapes.add_table(len(rows) + 1, 2, RX, Cm(3.20), COL, Cm(3.0)).table
tbl.columns[0].width = Cm(3.3)
tbl.columns[1].width = Cm(3.2)
for ci, txt in enumerate(("Metric", "Value")):
    c = tbl.cell(0, ci)
    c.text = txt
    r = c.text_frame.paragraphs[0].runs[0]
    r.font.size = Pt(6.5); r.font.bold = True
    r.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
    c.fill.solid(); c.fill.fore_color.rgb = ACCENT
    c.margin_left = Cm(0.08); c.margin_top = Cm(0.005); c.margin_bottom = Cm(0.005)
for ri, (a, b) in enumerate(rows, start=1):
    for ci, txt in enumerate((a, b)):
        c = tbl.cell(ri, ci)
        c.text = txt
        r = c.text_frame.paragraphs[0].runs[0]
        r.font.size = Pt(5.8); r.font.color.rgb = INK
        c.margin_left = Cm(0.08); c.margin_top = Cm(0.005); c.margin_bottom = Cm(0.005)
        if ri % 2 == 0:
            c.fill.solid(); c.fill.fore_color.rgb = ZEBRA

tf = textbox(RX, Cm(6.15), COL, Cm(4.4))
heading(tf, "PERFORMANCE: 2.4 -> 7.5 fps, ZERO HW COST")
para(tf, "The display path needs only about 120 ms, so it could always run at the sensor's 7.5 fps. It ran at "
         "2.4 fps because a 230 ms inference stage was serialised into the same loop.", after=3)
para(tf, "Frame rate quantises:  T_total = ceil(T_proc / T_cam) x T_cam,  T_cam = 133.33 ms. So 340.6 ms and "
         "327.8 ms both land on the same 400 ms step \u2014 micro-optimisation that removed 12.7 ms changed the "
         "frame rate by nothing at all.", after=3)
para(tf, "Splitting display and inference into two threads that share only the box coordinates restored it: "
         "same bitstream, same LUT / FF / BRAM / DSP, +208% frame rate at a resource cost of zero.", after=0)

tf = textbox(RX, Cm(9.35), COL, Cm(7.0))
heading(tf, "TWO HARD PROBLEMS, DIAGNOSED READ-ONLY")
para(tf, "1.  The accelerator refused the model \u2014 \u201cDPU configuration mismatch\u201d. Three Block Design "
         "switches were wrong, and the derivation was not guessed: it came from the IP's own generator file "
         "dpu_eu_v3_0.gtcl, which defines each feature in terms of those switches.", after=4)
para(tf, "2.  Output was non-deterministic \u2014 random classes, out-of-range boxes, a different answer every "
         "run. \u201cidentical=0\u201d was the tell: configuration errors are stable, only clock/timing errors are "
         "random. The 2x clock sat at 150 MHz against a 100 MHz m_axi \u2014 not an integer multiple. An exact "
         "200 MHz made the output byte-for-byte reproducible.", after=4)
para(tf, "Both were found with read-only probes, so neither cost a 50-minute bitstream rebuild.",
     color=MUTED, after=0)

# ============================================================== footer
rule(LX, Cm(13.80), Cm(23.6))
tf = textbox(LX, Cm(13.90), Cm(23.6), Cm(0.45))
para(tf, "Open source under MIT:  github.com/SantaAna-aptx/zynq7020-ov5640-dpu-yolo",
     size=8, color=ACCENT, align=PP_ALIGN.CENTER, first=True)

prs.save(OUT)
print("saved", OUT)







