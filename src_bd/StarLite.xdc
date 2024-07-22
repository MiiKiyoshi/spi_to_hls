set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS33} [get_ports {led[1]}]

set_property -dict {PACKAGE_PIN F17 IOSTANDARD LVCMOS33} [get_ports {i_mosi}]
set_property -dict {PACKAGE_PIN F16 IOSTANDARD LVCMOS33} [get_ports {o_miso}]
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports {i_sclk}]
set_property -dict {PACKAGE_PIN E17 IOSTANDARD LVCMOS33} [get_ports {i_ss_n}]

set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS33} [get_ports {SPI0_MOSI_O}]
set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS33} [get_ports {SPI0_MISO_I}]
set_property -dict {PACKAGE_PIN J19 IOSTANDARD LVCMOS33} [get_ports {SPI0_SCLK_O}]
set_property -dict {PACKAGE_PIN K19 IOSTANDARD LVCMOS33} [get_ports {SPI0_SS_O  }]
