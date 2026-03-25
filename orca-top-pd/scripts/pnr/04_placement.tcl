############################################################################
# Script   : placement_orca.tcl
# Design   : ORCA_TOP (Full SoC)
# Tool     : Synopsys IC Compiler 2 (ICC2) R-2020.09-SP2
# Node     : SAED 32nm
# Author   : Mohammad Yusuf
# Purpose  : Pre-placement checks, magnet placement, timing-driven
#            placement, place_opt
############################################################################

############################################################################
# HOST OPTIONS (parallel execution)
############################################################################
set_host_options -max_cores 16

############################################################################
# PRE-PLACEMENT REPORTS
############################################################################
file mkdir ../reports/placement

check_design -checks pre_placement_stage \
    > ../reports/placement/check-design.rpt

############################################################################
# MAGNET PLACEMENT (IO port alignment)
# Pull long ports toward their connected logic for better wirelength
############################################################################
magnet_placement -multiple_long_port_mode auto [get_ports [all_inputs]]
magnet_placement -multiple_long_port_mode auto [get_ports [all_outputs]]

############################################################################
# CELL DENSITY
# Coarse max density = 0.6 (prevents routing congestion)
############################################################################
set_app_options -name place.coarse.max_density -value 0.6

############################################################################
# PARASITIC TECH (for timing-driven placement)
############################################################################
read_parasitic_tech \
    -tlup     /home/user_snps/Desktop/my_project/code/snps/ref/tech/saed32nm_1p9m_Cmin.tluplus \
    -layermap /home/user_snps/Desktop/my_project/code/snps/ref/tech/saed32nm_tf_itf_tluplus.map \
    -name     tlup_min

read_parasitic_tech \
    -tlup     /home/user_snps/Desktop/my_project/code/snps/ref/tech/saed32nm_1p9m_Cmax.tluplus \
    -layermap /home/user_snps/Desktop/my_project/code/snps/ref/tech/saed32nm_tf_itf_tluplus.map \
    -name     tlup_max

set_parasitic_parameters -early_spec tlup_min -late_spec tlup_max -corners ss0p95v25c
set_parasitic_parameters -early_spec tlup_min -late_spec tlup_max -corners ss0p95v125c

############################################################################
# VOLTAGE SETUP
############################################################################
set_voltage 0.95 -object_list VDD
set_voltage 0.0  -object_list VSS
