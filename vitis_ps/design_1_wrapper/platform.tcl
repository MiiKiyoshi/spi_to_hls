# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct C:\works\verilog\starlite_prj\spi_divide_sum_baremetal\vitis_ps\design_1_wrapper\platform.tcl
# 
# OR launch xsct and run below command.
# source C:\works\verilog\starlite_prj\spi_divide_sum_baremetal\vitis_ps\design_1_wrapper\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {design_1_wrapper}\
-hw {C:\works\verilog\starlite_prj\spi_divide_sum_baremetal\vivado_bd\design_1_wrapper.xsa}\
-out {C:/works/verilog/starlite_prj/spi_divide_sum_baremetal/vitis_ps}

platform write
domain create -name {standalone_ps7_cortexa9_0} -display-name {standalone_ps7_cortexa9_0} -os {standalone} -proc {ps7_cortexa9_0} -runtime {cpp} -arch {32-bit} -support-app {empty_application}
platform generate -domains 
platform active {design_1_wrapper}
domain active {zynq_fsbl}
domain active {standalone_ps7_cortexa9_0}
platform generate -quick
platform generate
platform generate
platform clean
platform generate
