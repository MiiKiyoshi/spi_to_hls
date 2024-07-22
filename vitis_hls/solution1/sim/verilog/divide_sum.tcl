
log_wave -r /
set designtopgroup [add_wave_group "Design Top Signals"]
set coutputgroup [add_wave_group "C Outputs" -into $designtopgroup]
set return_group [add_wave_group return(wire) -into $coutputgroup]
add_wave /apatb_divide_sum_top/AESL_inst_divide_sum/out_result2_ap_vld -into $return_group -color #ffff00 -radix hex
add_wave /apatb_divide_sum_top/AESL_inst_divide_sum/out_result2 -into $return_group -radix hex
add_wave /apatb_divide_sum_top/AESL_inst_divide_sum/out_result1_ap_vld -into $return_group -color #ffff00 -radix hex
add_wave /apatb_divide_sum_top/AESL_inst_divide_sum/out_result1 -into $return_group -radix hex
set cinputgroup [add_wave_group "C Inputs" -into $designtopgroup]
set return_group [add_wave_group return(memory) -into $cinputgroup]
add_wave /apatb_divide_sum_top/AESL_inst_divide_sum/in_val2_q0 -into $return_group -radix hex
add_wave /apatb_divide_sum_top/AESL_inst_divide_sum/in_val2_ce0 -into $return_group -color #ffff00 -radix hex
add_wave /apatb_divide_sum_top/AESL_inst_divide_sum/in_val2_address0 -into $return_group -radix hex
add_wave /apatb_divide_sum_top/AESL_inst_divide_sum/in_val1_q0 -into $return_group -radix hex
add_wave /apatb_divide_sum_top/AESL_inst_divide_sum/in_val1_ce0 -into $return_group -color #ffff00 -radix hex
add_wave /apatb_divide_sum_top/AESL_inst_divide_sum/in_val1_address0 -into $return_group -radix hex
set blocksiggroup [add_wave_group "Block-level IO Handshake" -into $designtopgroup]
add_wave /apatb_divide_sum_top/AESL_inst_divide_sum/ap_start -into $blocksiggroup
add_wave /apatb_divide_sum_top/AESL_inst_divide_sum/ap_done -into $blocksiggroup
add_wave /apatb_divide_sum_top/AESL_inst_divide_sum/ap_idle -into $blocksiggroup
add_wave /apatb_divide_sum_top/AESL_inst_divide_sum/ap_ready -into $blocksiggroup
set resetgroup [add_wave_group "Reset" -into $designtopgroup]
add_wave /apatb_divide_sum_top/AESL_inst_divide_sum/ap_rst -into $resetgroup
set clockgroup [add_wave_group "Clock" -into $designtopgroup]
add_wave /apatb_divide_sum_top/AESL_inst_divide_sum/ap_clk -into $clockgroup
set testbenchgroup [add_wave_group "Test Bench Signals"]
set tbinternalsiggroup [add_wave_group "Internal Signals" -into $testbenchgroup]
set tb_simstatus_group [add_wave_group "Simulation Status" -into $tbinternalsiggroup]
set tb_portdepth_group [add_wave_group "Port Depth" -into $tbinternalsiggroup]
add_wave /apatb_divide_sum_top/AUTOTB_TRANSACTION_NUM -into $tb_simstatus_group -radix hex
add_wave /apatb_divide_sum_top/ready_cnt -into $tb_simstatus_group -radix hex
add_wave /apatb_divide_sum_top/done_cnt -into $tb_simstatus_group -radix hex
add_wave /apatb_divide_sum_top/LENGTH_in_val1 -into $tb_portdepth_group -radix hex
add_wave /apatb_divide_sum_top/LENGTH_in_val2 -into $tb_portdepth_group -radix hex
add_wave /apatb_divide_sum_top/LENGTH_out_result1 -into $tb_portdepth_group -radix hex
add_wave /apatb_divide_sum_top/LENGTH_out_result2 -into $tb_portdepth_group -radix hex
set tbcoutputgroup [add_wave_group "C Outputs" -into $testbenchgroup]
set tb_return_group [add_wave_group return(wire) -into $tbcoutputgroup]
add_wave /apatb_divide_sum_top/out_result2_ap_vld -into $tb_return_group -color #ffff00 -radix hex
add_wave /apatb_divide_sum_top/out_result2 -into $tb_return_group -radix hex
add_wave /apatb_divide_sum_top/out_result1_ap_vld -into $tb_return_group -color #ffff00 -radix hex
add_wave /apatb_divide_sum_top/out_result1 -into $tb_return_group -radix hex
set tbcinputgroup [add_wave_group "C Inputs" -into $testbenchgroup]
set tb_return_group [add_wave_group return(memory) -into $tbcinputgroup]
add_wave /apatb_divide_sum_top/in_val2_q0 -into $tb_return_group -radix hex
add_wave /apatb_divide_sum_top/in_val2_ce0 -into $tb_return_group -color #ffff00 -radix hex
add_wave /apatb_divide_sum_top/in_val2_address0 -into $tb_return_group -radix hex
add_wave /apatb_divide_sum_top/in_val1_q0 -into $tb_return_group -radix hex
add_wave /apatb_divide_sum_top/in_val1_ce0 -into $tb_return_group -color #ffff00 -radix hex
add_wave /apatb_divide_sum_top/in_val1_address0 -into $tb_return_group -radix hex
save_wave_config divide_sum.wcfg
run all

