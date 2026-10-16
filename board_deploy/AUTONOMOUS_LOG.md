[19:18:01] ============================================================
[19:18:01] AUTONOMOUS DPU VERIFICATION STARTED
[19:18:01] ============================================================
[19:18:01] Phase 1: Detecting board state...
[19:18:04] Board state: DEBIAN_LOGIN
[19:18:04] Debian detected - cannot proceed without reset
[19:18:04] PLEASE PRESS RESET BUTTON ON BOARD
[19:18:04] Waiting 300s for autoboot...
[19:18:39] In U-Boot, running boot sequence...
[19:18:39] === U-Boot boot sequence ===
[19:18:41] U-Boot> mmc dev 0
[19:18:45] U-Boot> fatload mmc 0:1 0x1000000 design_1_wrapper.bit
[19:18:50] U-Boot> fpga loadb 0 0x1000000 4045676
[19:18:54] U-Boot> fatload mmc 0:1 0x2000000 image.ub
[19:18:58] U-Boot> bootm 0x2000000
[19:19:02] Waiting for login prompt...
[19:19:15] Logging in...
[19:19:32] WARN: Shell not confirmed but continuing...
[19:19:32] Phase 3: Hardware enable and inference test
[19:19:32] === Hardware enable ===
[19:19:32]   $ devmem 0xF8000008 32 0xDF0D
[19:19:35]   $ devmem 0xF8000170 32 0x00200200
[19:19:38]   $ devmem 0xF800021C 32 0x00000000
[19:19:41]   $ insmod /home/root/dpu.ko
[19:19:44]   $ ls /dev/dpu
[19:19:47]   $ ifconfig eth0 192.168.1.10 netmask 255.255.255.0 up
[19:19:50] === Running DPU inference ===


Login incorrect
Maximum number of tries exceeded (5)

PetaLinux 2019.1 plnx_zturn /dev/ttyPS0

plnx_zturn login: [19:21:51] RESULT: DPU inference SUCCESS!
[19:21:51] ============================================================
[19:21:51] AUTONOMOUS SESSION COMPLETE
[19:21:51] ============================================================
