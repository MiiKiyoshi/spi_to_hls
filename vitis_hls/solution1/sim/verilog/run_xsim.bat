
set PATH=
call G:/TOOLS/Xilinx/Vivado/2023.2/bin/xelab xil_defaultlib.apatb_divide_sum_top glbl -Oenable_linking_all_libraries  -prj divide_sum.prj -L smartconnect_v1_0 -L axi_protocol_checker_v1_1_12 -L axi_protocol_checker_v1_1_13 -L axis_protocol_checker_v1_1_11 -L axis_protocol_checker_v1_1_12 -L xil_defaultlib -L unisims_ver -L xpm  -L floating_point_v7_1_16 -L floating_point_v7_0_21 --lib "ieee_proposed=./ieee_proposed" -s divide_sum -debug all
call G:/TOOLS/Xilinx/Vivado/2023.2/bin/xsim --noieeewarnings divide_sum -tclbatch divide_sum.tcl -gui -view divide_sum_dataflow_ana.wcfg -protoinst divide_sum.protoinst

