@echo off
rem ============================================================================
rem run_sim.bat -- run the RTL testbenches with xvlog / xelab / xsim.
rem
rem WHY THIS FILE WAS REWRITTEN
rem   The original lived in rtl\ and hardcoded two absolute paths:
rem       cd /d E:\yoloProject\rtl
rem       call "D:\vivado2019.1\...\bin\xvlog.bat" ...
rem   so nobody else could run it. The paths are now parameters, and the
rem   repository root is derived from this script's own location, so the script
rem   works from any checkout directory.
rem
rem USAGE
rem   run_sim.bat [testbench] [outdir]
rem
rem     testbench   cam_tb2 (default) | cam_tb | fw_tb
rem     outdir      where logs land; default <repo>\sim\logs
rem
rem   Override the toolchain with an environment variable if it is elsewhere:
rem       set VIVADO_BIN=C:\Xilinx\Vivado\2019.1\bin
rem
rem TESTBENCHES
rem   cam_tb    ov5640_cam_top: 4 rows x 16 pixels, checks AXIS packing / sof / eol
rem   cam_tb2   ov5640_cam_top: count-based framing, INJECTS tready stalls
rem             (regression test for the AXIS handshake fix)
rem   fw_tb     frame_writer: 4-pixel packing, write-pointer wrap, frame boundary
rem
rem EXIT CODES
rem   0 = simulation ran and printed SIM_RESULT=PASS
rem   1 = compile/elaborate error, or the run did not print SIM_RESULT=PASS
rem   2 = toolchain not found
rem
rem Keep this file pure ASCII: PowerShell/cmd can fail to parse non-ASCII in a
rem script, and such a failure happens before anything runs.
rem ============================================================================

setlocal enabledelayedexpansion

set "HERE=%~dp0"
set "REPO=%~dp0.."
set "SRC=%REPO%\rtl"

set "TB=%~1"
if "%TB%"=="" set "TB=cam_tb2"

set "LOGDIR=%~2"
if "%LOGDIR%"=="" set "LOGDIR=%HERE%logs"

if "%VIVADO_BIN%"=="" set "VIVADO_BIN=D:\vivado2019.1\VIVADO20191\Vivado\2019.1\bin"

set "XVLOG=%VIVADO_BIN%\xvlog.bat"
set "XELAB=%VIVADO_BIN%\xelab.bat"
set "XSIM=%VIVADO_BIN%\xsim.bat"
set "GLBL=%VIVADO_BIN%\..\data\verilog\src\glbl.v"

if not exist "%XVLOG%" (
    echo FAIL: xvlog.bat not found at "%XVLOG%"
    echo       Set VIVADO_BIN to the bin directory of your Vivado install.
    exit /b 2
)

if not exist "%LOGDIR%" mkdir "%LOGDIR%"

rem ---- source set: cam_top needs the SCCB master and the async FIFO ----------
set "SOURCES="
if /i "%TB%"=="fw_tb" (
    set "SOURCES=frame_writer.v"
) else (
    set "SOURCES=ov5640_cam_top.v async_fifo_18b.v I2C_OV5640_1280720_Config.v i2c_timing_ctrl_reg16_dat8_wronly.v"
)

echo === testbench : %TB%
echo === sources   : %SOURCES%
echo === logs      : %LOGDIR%
echo.

pushd "%SRC%"

rem ---- 1. compile -----------------------------------------------------------
call "%XVLOG%" %SOURCES% %TB%.v "%GLBL%" > "%LOGDIR%\sim_1_xvlog.log" 2>&1
findstr /i "ERROR" "%LOGDIR%\sim_1_xvlog.log" >nul 2>&1
if not errorlevel 1 (
    echo FAIL: xvlog reported errors -- see "%LOGDIR%\sim_1_xvlog.log"
    popd & exit /b 1
)
echo   [1/3] xvlog OK

rem ---- 2. elaborate ---------------------------------------------------------
call "%XELAB%" work.%TB% work.glbl -L unisims_ver -s %TB%_sim -debug typical > "%LOGDIR%\sim_2_xelab.log" 2>&1
findstr /i "ERROR" "%LOGDIR%\sim_2_xelab.log" >nul 2>&1
if not errorlevel 1 (
    echo FAIL: xelab reported errors -- see "%LOGDIR%\sim_2_xelab.log"
    popd & exit /b 1
)
echo   [2/3] xelab OK

rem ---- 3. run ---------------------------------------------------------------
call "%XSIM%" %TB%_sim -R --maxdeltaid 10000 > "%LOGDIR%\sim_3_run.log" 2>&1
findstr /i "TB-PASS TB-FAIL SIM_RESULT ERROR" "%LOGDIR%\sim_3_run.log"

findstr /c:"SIM_RESULT=PASS" "%LOGDIR%\sim_3_run.log" >nul 2>&1
if errorlevel 1 (
    echo.
    echo FAIL: no SIM_RESULT=PASS in the run log -- see "%LOGDIR%\sim_3_run.log"
    popd & exit /b 1
)

popd
echo.
echo PASS: %TB% -- logs in "%LOGDIR%"
exit /b 0
