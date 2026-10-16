#!/usr/bin/env python3
"""Dump the unified BD's clocking for clk_wiz_0 and dpu_eu_0, plus every clock pin of the DPU and
what drives it.

Why: the new DPU build reports the correct feature set (dexplorer -w) but produces
non-deterministic garbage (identical=0, every run a different checksum). The old DPU-only
bitstream that scored 8/8 is identical=1 on the same board/kernel/CMA. The remaining variables are
the DPU's clocking and the fact that the camera is now streaming into DDR in the same design, so
the first thing to pin down is exactly which clock feeds which DPU pin.
"""
import json
import re

BD = r'E:\yoloProject\vivado_projects\unified\unified.srcs\sources_1\bd\design_1\design_1.bd'
raw = open(BD, 'r', encoding='utf-8', errors='replace').read()
doc = json.loads(raw)

bd = doc['design']
comps = bd.get('components', {})

print('=' * 78)
print('clk_wiz_0 output frequencies (REQUESTED / ACTUAL)')
print('=' * 78)
cw = comps.get('clk_wiz_0', {}).get('parameters', {})
for k in sorted(cw):
    if re.search(r'CLKOUT\d_(REQUESTED_OUT_FREQ|USED)|PRIM_IN_FREQ|NUM_OUT_CLKS|MMCM_CLKOUT\d_DIVIDE|MMCM_CLKFBOUT_MULT', k):
        print('   %-44s = %s' % (k, cw[k].get('value')))

print()
print('=' * 78)
print('dpu_eu_0 clock-related CONFIG parameters')
print('=' * 78)
dp = comps.get('dpu_eu_0', {}).get('parameters', {})
for k in sorted(dp):
    if re.search(r'FREQ|CLK|CLOCK', k):
        print('   %-44s = %s' % (k, dp[k].get('value')))

print()
print('=' * 78)
print('dpu_eu_0 clock pins and what drives them')
print('=' * 78)


def find_ports(node):
    """Return {pin_path: {...}} for every port declared anywhere under this component."""
    out = {}
    ports = node.get('ports')
    if isinstance(ports, dict):
        for name, body in ports.items():
            out[name] = body
    for sub in node.get('components', {}).values():
        out.update(find_ports(sub))
    return out


dpu = comps.get('dpu_eu_0', {})
dpu_ports = find_ports(dpu)
clk_pins = sorted(p for p in dpu_ports if re.search(r'clock|clk|aclk', p, re.I))
print('   clock-ish ports on dpu_eu_0:')
for p in clk_pins:
    body = dpu_ports[p]
    extras = []
    if 'CLK_DOMAIN' in str(body):
        extras.append('CLK_DOMAIN')
    print('      %-34s dir=%-3s %s' % (p, body.get('direction', '?'), ' '.join(extras)))

print()
print('=' * 78)
print('nets carrying those pins')
print('=' * 78)
nets = bd.get('nets', {})
for netname, net in nets.items():
    pins = net.get('ports', {}) or {}
    hit = [p for p in pins if 'dpu_eu_0' in p and re.search(r'clock|clk|aclk', p, re.I)]
    if not hit:
        continue
    others = [p for p in pins if 'dpu_eu_0' not in p]
    print('   net %s' % netname)
    for p in hit:
        print('      DPU pin : %s' % p)
    for p in others:
        print('      driven by: %s' % p)

print()
print('=' * 78)
print('any pin-level FREQ_HZ / CLK_DOMAIN overrides near the DPU')
print('=' * 78)
blob = json.dumps(dp)
for m in re.finditer(r'"(FREQ_HZ|CLK_DOMAIN)"[^}]*?"value"\s*:\s*"([^"]*)"', blob):
    print('   %-12s = %s' % (m.group(1), m.group(2)))
