.\clean.ps1
echo "xvlog: Compiling Verilog HDL files"
xvlog divide_sum_flow_control_loop_pipe.v divide_sum_sdiv_32ns_32ns_32_36_1.v divide_sum.v dual_port_bram.v spi_master.v spi_slave.v  tb_spi_system.v spi_to_hls.v | Out-File debug.log
echo ""
echo "xelab: Linking compiled files"
xelab tb_spi_system -s tb_spi_system -debug wave | Out-File debug.log -Append
echo ""
echo "xsim: Running the simulation"
xsim tb_spi_system -wdb simulate_xsim_tb_spi_system.wdb -gui | Out-File debug.log -Append
(Get-Content debug.log) -replace “ECHO가 설정되어 있지 않습니다.”, “” | Set-Content debug.log
Get-Content debug.log
