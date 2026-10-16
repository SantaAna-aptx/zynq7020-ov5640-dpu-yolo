<#
.SYNOPSIS
    Verify that an ARM executable still carries the DNNDK model sections it needs.

.DESCRIPTION
    DNNDK's dpuLoadKernel("<kernel>") reads ELF sections named .deephi.* from the
    RUNNING EXECUTABLE. There is no separate model file at run time, so if those
    sections are missing from the binary the failure appears only on the board.

    They are easy to lose silently. The classic cause: objcopy preserves the
    ET_DYN type of its input, so the linker treats the model object as a shared
    library and discards every one of its sections WITHOUT an error. The fix is
    to mark the section-carrier object as relocatable:

        arm-linux-gnueabihf-objcopy -O elf32-littlearm --only-section='.deephi.*' <app> model.o
        arm-linux-gnueabihf-elfedit  --output-type=rel model.o

    Run this after every link. It takes a second and catches a failure that
    otherwise costs a board round trip.

.PARAMETER Binary
    The linked executable (or the intermediate .o) to inspect.

.PARAMETER ToolchainBin
    Directory holding arm-linux-gnueabihf-readelf.exe. Defaults to the copy that
    ships with Vivado's SDK, which is where a usable ARM Linux toolchain
    usually hides.

.PARAMETER Expected
    Expected number of .deephi sections. DNNDK models have one section per part:
    strtab, metadata, configurable, tensor, node, parameter, code = 7 for a
    single-kernel model. Count them once with `ddump` or readelf, then pin it here.

.EXAMPLE
    .\check_dpu_model_sections.ps1 -Binary .\cam_stream

.EXAMPLE
    .\check_dpu_model_sections.ps1 -Binary .\deephi_rel.o -Expected 7 -Verbose

.NOTES
    Exit code 0 = OK, 1 = missing sections or binary not found.
    Keep this file pure ASCII: PowerShell can fail to parse non-ASCII characters
    in a script, and the failure is at parse time, so nothing runs at all.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Binary,

    [string]$ToolchainBin = 'D:\Xilinx\SDK\2019.1\gnu\aarch32\nt\gcc-arm-linux-gnueabi\bin',

    [int]$Expected = 7
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Binary)) {
    Write-Host "FAIL: binary not found: $Binary"
    exit 1
}

$readelf = Join-Path $ToolchainBin 'arm-linux-gnueabihf-readelf.exe'
if (-not (Test-Path -LiteralPath $readelf)) {
    # Fall back to a readelf on PATH, if any.
    $onPath = Get-Command 'arm-linux-gnueabihf-readelf' -ErrorAction SilentlyContinue
    if ($onPath) {
        $readelf = $onPath.Source
    } else {
        Write-Host "FAIL: arm-linux-gnueabihf-readelf.exe not found."
        Write-Host "      Looked in : $ToolchainBin"
        Write-Host "      Pass -ToolchainBin, or run this from a shell where it is on PATH."
        exit 1
    }
}

$file = Get-Item -LiteralPath $Binary
Write-Host ("inspecting : {0}  ({1:N0} bytes)" -f $file.Name, $file.Length)
Write-Host ("readelf    : {0}" -f $readelf)

# -SW prints the section headers in wide form; one line per section.
$sections = & $readelf -SW $Binary 2>&1 | Select-String -Pattern '\.deephi'

Write-Host ''
Write-Host 'model sections found:'
if ($sections) {
    foreach ($s in $sections) {
        Write-Host ('   ' + $s.Line.Trim())
    }
} else {
    Write-Host '   (none)'
}

$count = @($sections).Count
Write-Host ''
Write-Host ("count = {0}   expected = {1}" -f $count, $Expected)

if ($count -ne $Expected) {
    Write-Host ''
    Write-Host 'FAIL: section count mismatch.'
    Write-Host '      If the count is 0, the linker dropped the model object.'
    Write-Host '      Check that elfedit --output-type=rel was applied to it:'
    Write-Host ('         ' + (Join-Path $ToolchainBin 'arm-linux-gnueabihf-readelf.exe') + ' -h <model.o>')
    Write-Host '      The ELF type must be REL, not DYN.'
    exit 1
}

# A sanity check on the payload: the biggest section should be the weights.
# An accidentally empty model would still show 7 headers.
#
# readelf -SW columns are:  [Nr] Name Type Address Off Size ES Flg Lk Inf Al
# so the size is the THIRD hex field after the type. Matching the first hex
# field instead picks up the address, which is 0 for these sections.
$bytes = ($sections | ForEach-Object {
        if ($_.Line -match 'PROGBITS\s+[0-9a-f]+\s+[0-9a-f]+\s+([0-9a-f]+)') {
            [Convert]::ToInt64($matches[1], 16)
        }
    } | Measure-Object -Sum).Sum

if ($null -eq $bytes -or $bytes -le 0) {
    Write-Host 'NOTE: could not parse section sizes (readelf format differs);'
    Write-Host '      skipped the payload sanity check. The count above is still valid.'
} else {
    Write-Host ("total .deephi payload = {0:N0} bytes" -f $bytes)
    if ($bytes -lt 1MB) {
        Write-Host 'WARN: payload looks small for a YOLO model. Verify it is the real thing.'
    }
}

Write-Host ''
Write-Host 'OK: all model sections present.'
exit 0
