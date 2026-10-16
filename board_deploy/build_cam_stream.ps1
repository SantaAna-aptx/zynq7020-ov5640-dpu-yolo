# build_cam_stream.ps1 -- cross-compile cam_stream for the board.
#
# Toolchain note: the ARM Linux cross compiler was assumed missing for a long time because only
# Vivado\2019.1\gnu was searched. It actually ships with the SDK:
#     D:\vivado2019.1\VIVADO20191\SDK\2019.1\gnu\aarch32\nt\gcc-arm-linux-gnueabi\bin
# Its bundled glibc is 2.28, exactly the board's, so binaries run without a custom libc sysroot.
#
# The model: the board has no .elf anywhere. dpuLoadKernel("tiny_yolo") reads ELF sections named
# .deephi.* from the running executable. deephi_rel.o holds those sections, extracted from the
# working app. objcopy preserves the ET_DYN type of its input, which makes the linker treat the
# file as a shared library and silently drop the sections - hence elfedit --output-type=rel.
#
# Link flag note: -Wl,--allow-shlib-undefined is needed because OpenCV's own dependencies
# (libtbb, libpng, libtiff, libwebp) are not in the sysroot. They exist on the board and are
# resolved at run time, so the link does not need them.
param(
  [string]$Root = 'E:\yoloProject\board_deploy',
  [string]$Toolchain = 'D:\vivado2019.1\VIVADO20191\SDK\2019.1\gnu\aarch32\nt\gcc-arm-linux-gnueabi\bin'
)
$gpp = Join-Path $Toolchain 'arm-linux-gnueabihf-g++.exe'
$sysroot = Join-Path $Root 'sysroot_arm'
$out = Join-Path $Root 'cam_stream'
Remove-Item $out -ErrorAction SilentlyContinue

$compileArgs = @(
  '-O2', '-mcpu=cortex-a9', '-mfloat-abi=hard', '-mfpu=neon', '-std=c++11',
  "-I$sysroot",
  (Join-Path $Root 'cam_stream.cpp'),
  (Join-Path $Root 'deephi_rel.o'),
  "-L$sysroot\usr\lib",
  '-ln2cube', '-ldputils', '-lhineon',
  '-lopencv_core', '-lopencv_imgproc', '-lopencv_imgcodecs',
  '-Wl,--allow-shlib-undefined', "-Wl,-rpath-link,$sysroot\usr\lib",
  '-lpthread', '-lm',
  '-o', $out
)
Write-Host "=== compiling cam_stream.cpp ==="
$err = & $gpp @compileArgs 2>&1
Write-Host ("g++ exit=" + $LASTEXITCODE)
if ($err) { $err | Select-Object -First 40 }

if (Test-Path $out) {
  $size = (Get-Item $out).Length
  Write-Host ("`nOK: {0}  ({1} bytes)" -f $out, $size)
  $readelf = Join-Path $Toolchain 'arm-linux-gnueabihf-readelf.exe'
  Write-Host "=== model sections in the output (must be 7) ==="
  $sec = & $readelf -SW $out 2>&1 | Select-String -Pattern 'deephi'
  $sec | ForEach-Object { Write-Host ("   " + $_.Line.Trim()) }
  Write-Host ("   count: " + $sec.Count)
  if ($sec.Count -ne 7) { Write-Host "!! expected 7 .deephi sections - dpuLoadKernel would fail" }
} else {
  Write-Host "`n!! no output produced"
}
