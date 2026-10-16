# scan_upload.ps1 -- work out exactly what would go into the GitHub repo, and prove the secrets
# stay out. Read-only: it lists and counts, it does not git-init or copy anything.
#
# Why a whitelist rather than a blacklist: the project is 3.17 GB / 7632 files, almost all of it
# build artefacts (Vivado runs/cache/.dcp, bitstreams, rootfs images, rootfs backups) or vendor
# SDKs. A blacklist would need to be exhaustive to be safe; a whitelist of source/config/doc
# extensions is provably safe and lands the repo in the tens of MB.
param(
  [string]$Root = 'E:\yoloProject',
  [string]$EmitList = ''      # if set, write the kept file list (repo-relative, forward slashes)
                              # so it can feed: git add --pathspec-from-file=<file>
)

# ---- never upload, no matter what -------------------------------------------------------------
# board_key is an OpenSSH PRIVATE KEY (1823 bytes) used by the SSH helpers; passwd_set.py contains
# the board's root password in plaintext and passwd_set.log echoes the passwd session.
$DENY_NAME = @('board_key', 'board_key.pub', 'passwd_set.py', 'passwd_set.log')

# ---- directories that are artefacts, vendor SDKs, or images -----------------------------------
# Note these are substring matches, not path-anchored: Vivado names its scratch dirs things like
# 'yoloproject.ip_user_files' and 'probe.cache', which do NOT start with a slash.
$DENY_SUB = @(
  'ipshared', 'ip_user_files', '.runs', '.cache', '.hw', '.sim', '.Xil',
  'hw_handoff', 'probe_prj', 'diag2_prj',
  '/backup/', '/sysroot_arm/', '/sd_delivery/', '/sdcard/',
  '/web/', '/dnndk_v3.1/', '/dpu_trd/', '/bd_probe/', '/soc_prj.gen/',
  '/vivado_session/', '__pycache__', '.agent-migration', 'petalinux_projects'
)
# ---- generated files that Vivado can always rebuild ------------------------------------------
$DENY_FILE = @('*_rfs.v', '*_rfs.vhd', '*_sim_netlist.v', '*_sim_netlist.vhdl',
               'ps7_init*', '*_stub.v', '*_stub.vhdl', '*.dcp', '*.bit', '*.bin', '*.xpr.bak',
               # Vivado xsim scratch that litters rtl/
               'xsim*', 'xelab*', 'xvlog*', 'usage_statistics*', 'webtalk*',
               'Compile_Options.txt', 'cam_sim.wdb', 'work.rlx')

# ---- board_deploy: explicit whitelist ---------------------------------------------------------
# This folder accumulated ~1000 files over weeks of debugging (peek_*, phase*, vm_*, sd_*, fclk_*,
# 493 .log files...). Those are process artefacts, not the project. Only the files that carry the
# actual work are kept.
# deephi_rel.o holds the DPU model sections in relocatable form (directly linkable); the ET_DYN
# twin deephi_tiny_yolo.o is not linkable and is dropped, as is the 9 MB compiled cam_stream.
$BD_KEEP = @(
  # --- the deliverable source ---
  'cam_stream.cpp',
  # --- on-board / host application sources ---
  'tiny_yolo_image_diag.cpp', 'video_loop.cpp', 'abi_probe.c',
  # --- build & deploy ---
  'build_cam_stream.ps1', 'deploy_stream.ps1', 'bringup_and_stream.ps1',
  'collect_sysroot.ps1', 'scan_upload.ps1', 'bit_to_swapped_bin.py',
  # --- the model, extracted from the working app (needed to link the program) ---
  'deephi_rel.o',
  # --- diagnostics / measurement tools ---
  'dpu_arch_probe.ps1', 'recon_board.ps1', 'bench_board.ps1', 'measure_cam_fps.ps1',
  'board_run.ps1', 'd4_loop.ps1', 'd5_full.ps1', 'd5_verify.ps1', 'd5_loop_only.ps1',
  'raw565_to_jpg.py', 'dump_frame.py', 'check_colour.py', 'inspect_app_model.py',
  'measure_line_width.py', 'block_width.py', 'colour_variants.py',
  'inspect_bd_clocks2.py', 'find_toolchain.py',
  # --- Vivado automation for the two DPU fixes ---
  'fix_dpu_features.tcl', 'fix_clk2x_and_build.tcl', 'unlock_regen_and_build.tcl',
  'inspect_dpu_params.tcl', 'diagnose_ip_lock.tcl', 'rebuild_force_ooc.tcl',
  'probe_dpu_features.tcl',
  # --- the live-focus preview tool ---
  'focus_ctl.ps1', 'live_focus.ps1', 'focus_frame.py',
  # --- design docs ---
  'FCLK0_ROOT_CAUSE.md'
)
$BD_KEEP_DIR = @('focus')      # subfolders of board_deploy to keep wholesale
$BD_KEEP_EXT_MD = $true       # keep every *.md in board_deploy (all of them are design records)

# ---- project root: explicit whitelist --------------------------------------------------------
# The root accumulated ~200 one-off debugging scripts (peek_*.ps1, phase*.sh, vm_*.sh, probe*,
# sd_*.sh, fclk_*.sh...). They are all tiny so size is not the reason to drop them - a repository
# whose top level is full of them just reads badly. Only the meaningful top-level items are kept;
# directories are handled by the rules below.
$ROOT_KEEP = @(
  'README.md', 'design_1_regen.tcl', 'system-user.dtsi',
  'YOLOv3-on-Z-turn-V2-Tutorial.md', 'PROJECT_RETROSPECTIVE_AND_OV5640_PLAN.md',
  'mzq7x_manual.txt', 'ov5640_tutorial.txt',
  'lab1-mz7x.txt', 'lab2-mz7x.txt', 'lab3-mz7x.txt'
)
$ROOT_KEEP_DIR = @('rtl', 'vivado_projects', 'board_deploy', 'ui', 'docs')
# probe_src is deliberately absent: it contains Xilinx IP source carrying a
# "CONFIDENTIAL IN CONFIDENCE" header, which must not be redistributed.
# docs/ additionally allows images (README references them).
$DOCS_EXT = @('.jpg', '.jpeg', '.png', '.gif', '.svg')

# ---- only these extensions are source / config / documentation ----------------
$ALLOW_EXT = @(
  '.c', '.cpp', '.cc', '.h', '.hpp',
  '.v', '.sv', '.vhd', '.vh',
  '.tcl', '.xdc', '.xci', '.bd', '.xpr',
  '.dtsi', '.dts',
  '.ps1', '.py', '.sh', '.bat', '.cmd',
  '.md', '.txt', '.json', '.yml', '.yaml',
  '.html', '.css', '.js'
)

Write-Host "=== scanning $Root ==="
$all = Get-ChildItem $Root -Recurse -File -Force -ErrorAction SilentlyContinue
$keep = New-Object System.Collections.ArrayList
$skippedSecrets = New-Object System.Collections.ArrayList

foreach ($f in $all) {
  $rel = $f.FullName.Replace("$Root\", '')
  $relSlash = '/' + $rel.Replace('\', '/')

  # 1) never, ever
  if ($DENY_NAME -contains $f.Name) { [void]$skippedSecrets.Add($rel); continue }

  # 2) board_deploy uses an explicit whitelist (see $BD_KEEP).
  #    The name match must only apply to DIRECT children of board_deploy - matching by name alone
  #    would also pick up e.g. backup/.../deephi_rel.o, which is an 8.6 MB duplicate.
  $top = ($rel -split '\\')[0]
  if ($top -eq 'board_deploy') {
    $parts = $rel -split '\\'
    if ($parts.Count -eq 2) {                                  # board_deploy\<file>
      if ($BD_KEEP_EXT_MD -and $f.Extension.ToLower() -eq '.md') { [void]$keep.Add($f); continue }
      if ($BD_KEEP -contains $f.Name) { [void]$keep.Add($f); continue }
      continue
    }
    $sub = $parts[1]
    if ($BD_KEEP_DIR -contains $sub) { [void]$keep.Add($f); continue }
    continue
  }

  # 2b) project root uses a whitelist too (top-level debug scripts are dropped)
  if ($rel -notmatch '\\') {
    if ($ROOT_KEEP -contains $f.Name) { [void]$keep.Add($f); continue }
    continue
  }
  if ($ROOT_KEEP_DIR -notcontains $top) { continue }

  # 3) artefact / vendor directories
  $denied = $false
  foreach ($d in $DENY_SUB) { if ($relSlash -like "*$d*") { $denied = $true; break } }
  if ($denied) { continue }

  # 4) generated files
  $isGen = $false
  foreach ($g in $DENY_FILE) { if ($f.Name -like $g) { $isGen = $true; break } }
  if ($isGen) { continue }

  # 5) extension must be source/config/doc (docs/ may also hold images for the README)
  $ext = $f.Extension.ToLower()
  if ($top -eq 'docs') {
    if ($ALLOW_EXT -notcontains $ext -and $DOCS_EXT -notcontains $ext) { continue }
  } else {
    if ($ALLOW_EXT -notcontains $ext) { continue }
  }
  if ($rel -like '*.bak' -or $rel -like '*.orig') { continue }

  [void]$keep.Add($f)
}

$sum = ($keep | Measure-Object -Property Length -Sum).Sum
Write-Host ""
Write-Host "=== KEPT (would be uploaded) ==="
Write-Host ("  files : " + $keep.Count)
Write-Host ("  size  : " + [math]::Round($sum / 1MB, 2) + " MB")

Write-Host ""
Write-Host "=== distribution by top-level folder ==="
$keep | Group-Object { ($_.FullName.Replace("$Root\", '') -split '\\')[0] } |
  ForEach-Object {
    $s = ($_.Group | Measure-Object -Property Length -Sum).Sum
    [pscustomobject]@{
      Folder = $_.Name
      Files  = $_.Count
      MB     = [math]::Round($s / 1MB, 2)
    }
  } | Sort-Object MB -Descending | Format-Table -AutoSize | Out-String | Write-Host

Write-Host "=== files over 1 MB (check these are genuinely wanted) ==="
$big = $keep | Where-Object { $_.Length -gt 1MB } | Sort-Object Length -Descending
if ($big) {
  $big | ForEach-Object { "{0,8:N2} MB  {1}" -f ($_.Length / 1MB), $_.FullName.Replace("$Root\", '') }
} else { Write-Host "  (none)" }

Write-Host ""
Write-Host "=== SECRETS EXCLUDED (must stay excluded) ==="
if ($skippedSecrets.Count) { $skippedSecrets | ForEach-Object { "  [excluded] $_" } }
else { Write-Host "  (none found)" }

Write-Host ""
Write-Host "=== sanity: any secret-looking filename left in KEPT? ==="
$suspect = $keep | Where-Object { $_.Name -match 'key|secret|token|password|passwd|credential|\.pem$|\.p12$|\.ppk$' }
if ($suspect) { $suspect | ForEach-Object { "  !! " + $_.FullName.Replace("$Root\", '') } }
else { Write-Host "  clean" }

if ($EmitList) {
  # forward slashes and repo-relative paths, for git add --pathspec-from-file
  $keep | ForEach-Object { $_.FullName.Replace("$Root\", '').Replace('\', '/') } |
    Sort-Object | Set-Content -Path $EmitList -Encoding ascii
  Write-Host ""
  Write-Host ("=== wrote " + $keep.Count + " paths to " + $EmitList + " ===")
}
