@echo off
cd /d E:\yoloProject\rtl
call "D:\vivado2019.1\VIVADO20191\Vivado\2019.1\bin\xvlog.bat" ov5640_cam_top.v async_fifo_18b.v I2C_OV5640_1280720_Config.v i2c_timing_ctrl_reg16_dat8_wronly.v cam_tb.v "D:\vivado2019.1\VIVADO20191\Vivado\2019.1\data\verilog\src\glbl.v" > sim_1_xvlog.log 2>&1
findstr /i "ERROR" sim_1_xvlog.log
echo XVLOG_EXIT=%ERRORLEVEL%
call "D:\vivado2019.1\VIVADO20191\Vivado\2019.1\bin\xelab.bat" work.cam_tb work.glbl -L unisims_ver -s cam_sim -debug typical > sim_2_xelab.log 2>&1
findstr /i "ERROR" sim_2_xelab.log
echo XELAB_EXIT=%ERRORLEVEL%
call "D:\vivado2019.1\VIVADO20191\Vivado\2019.1\bin\xsim.bat" cam_sim -R --maxdeltaid 10000 > sim_3_run.log 2>&1
findstr /i "TB- SIM_RESULT ERROR" sim_3_run.log
echo XSIM_EXIT=%ERRORLEVEL%
