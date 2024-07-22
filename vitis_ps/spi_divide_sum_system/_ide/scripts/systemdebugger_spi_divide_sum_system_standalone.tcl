# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: C:\works\verilog\starlite_prj\spi_divide_sum\vitis_ps\spi_divide_sum_system\_ide\scripts\systemdebugger_spi_divide_sum_system_standalone.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source C:\works\verilog\starlite_prj\spi_divide_sum\vitis_ps\spi_divide_sum_system\_ide\scripts\systemdebugger_spi_divide_sum_system_standalone.tcl
# 
connect -url tcp:127.0.0.1:3121
targets -set -nocase -filter {name =~"APU*"}
rst -system
after 3000
targets -set -filter {jtag_cable_name =~ "Digilent JTAG-SMT2 210251A08870" && level==0 && jtag_device_ctx=="jsn-JTAG-SMT2-210251A08870-23727093-0"}
fpga -file C:/works/verilog/starlite_prj/spi_divide_sum/vitis_ps/spi_divide_sum/_ide/bitstream/design_1_wrapper.bit
targets -set -nocase -filter {name =~"APU*"}
loadhw -hw C:/works/verilog/starlite_prj/spi_divide_sum/vitis_ps/design_1_wrapper/export/design_1_wrapper/hw/design_1_wrapper.xsa -mem-ranges [list {0x40000000 0xbfffffff}] -regs
configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*"}
source C:/works/verilog/starlite_prj/spi_divide_sum/vitis_ps/spi_divide_sum/_ide/psinit/ps7_init.tcl
ps7_init
ps7_post_config
targets -set -nocase -filter {name =~ "*A9*#0"}
dow C:/works/verilog/starlite_prj/spi_divide_sum/vitis_ps/spi_divide_sum/Debug/spi_divide_sum.elf
configparams force-mem-access 0
targets -set -nocase -filter {name =~ "*A9*#0"}
con
