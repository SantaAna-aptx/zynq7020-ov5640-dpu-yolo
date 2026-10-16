@echo off
cd /d E:\yoloProject\vivado_projects\scripts
del build_vdma7.log build_vdma7.jou 2>nul
D:\vivado2019.1\VIVADO20191\Vivado\2019.1\bin\vivado.bat -mode batch -source build_vdma6.tcl -log build_vdma7.log -journal build_vdma7.jou -notrace
