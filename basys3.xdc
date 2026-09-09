##====================================================
## Basys 3 FPGA Constraints
## 100 OTS x 100 Trials
##====================================================


##====================================================
## CLOCK - 100 MHz
##====================================================

set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

create_clock -period 10.000 -name sys_clk [get_ports clk]


##====================================================
## RESET - SW0
##====================================================

set_property PACKAGE_PIN V17 [get_ports rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports rst_n]


##====================================================
## START - CENTER PUSH BUTTON
##====================================================

set_property PACKAGE_PIN U18 [get_ports start]
set_property IOSTANDARD LVCMOS33 [get_ports start]


##====================================================
## STATUS LEDs
##====================================================

##----------------------------------------------------
## LED0
## Experiment / trial start
##----------------------------------------------------

set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]


##----------------------------------------------------
## LED1
## All 100 trials completed
##----------------------------------------------------

set_property PACKAGE_PIN E19 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]


##----------------------------------------------------
## LED2
## UART busy
##----------------------------------------------------

set_property PACKAGE_PIN U19 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]


##----------------------------------------------------
## LED3
## UART transmission complete
##----------------------------------------------------

set_property PACKAGE_PIN V19 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]


##====================================================
## UART TX
## Basys 3 USB-UART
##====================================================

set_property PACKAGE_PIN A18 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]


##====================================================
## SEVEN-SEGMENT DISPLAY
##====================================================

##----------------------------------------------------
## Segment A
##----------------------------------------------------

set_property PACKAGE_PIN W7 [get_ports {seg[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[0]}]


##----------------------------------------------------
## Segment B
##----------------------------------------------------

set_property PACKAGE_PIN W6 [get_ports {seg[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[1]}]


##----------------------------------------------------
## Segment C
##----------------------------------------------------

set_property PACKAGE_PIN U8 [get_ports {seg[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[2]}]


##----------------------------------------------------
## Segment D
##----------------------------------------------------

set_property PACKAGE_PIN V8 [get_ports {seg[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[3]}]


##----------------------------------------------------
## Segment E
##----------------------------------------------------

set_property PACKAGE_PIN U5 [get_ports {seg[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[4]}]


##----------------------------------------------------
## Segment F
##----------------------------------------------------

set_property PACKAGE_PIN V5 [get_ports {seg[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[5]}]


##----------------------------------------------------
## Segment G
##----------------------------------------------------

set_property PACKAGE_PIN U7 [get_ports {seg[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[6]}]


##----------------------------------------------------
## Decimal Point
##----------------------------------------------------

set_property PACKAGE_PIN V7 [get_ports dp]
set_property IOSTANDARD LVCMOS33 [get_ports dp]


##====================================================
## SEVEN-SEGMENT DIGIT ENABLES
##====================================================

##----------------------------------------------------
## AN0
##----------------------------------------------------

set_property PACKAGE_PIN U2 [get_ports {an[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[0]}]


##----------------------------------------------------
## AN1
##----------------------------------------------------

set_property PACKAGE_PIN U4 [get_ports {an[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[1]}]


##----------------------------------------------------
## AN2
##----------------------------------------------------

set_property PACKAGE_PIN V4 [get_ports {an[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[2]}]


##----------------------------------------------------
## AN3
##----------------------------------------------------

set_property PACKAGE_PIN W4 [get_ports {an[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[3]}]