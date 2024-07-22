############################################################
## This file is generated automatically by Vitis HLS.
## Please DO NOT edit it.
## Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
## Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
############################################################
open_project vitis_hls
set_top divide_sum
add_files src_hls/divide_sum.cpp
add_files -tb src_hls/tb_divide_sum.cpp -cflags "-Wno-unknown-pragmas"
open_solution "solution1" -flow_target vivado
set_part {xck26-sfvc784-2LV-c}
create_clock -period 10 -name default
config_cosim -tool xsim -trace_level all -wave_debug
config_export -format ip_catalog -output C:/works/verilog/kria_prj/spi_add_100/vitis_hls -rtl verilog
source "./vitis_hls/solution1/directives.tcl"
csim_design
csynth_design
cosim_design -wave_debug -trace_level all
export_design -rtl verilog -format ip_catalog -output C:/works/verilog/kria_prj/spi_add_100/vitis_hls
