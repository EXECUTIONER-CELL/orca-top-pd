############################################################################
# Script   : setup.tcl
# Design   : ORCA_TOP (Full SoC)
# Tool     : Synopsys IC Compiler 2 (ICC2) R-2020.09-SP2
# Node     : SAED 32nm (9-metal 1p9m)
# Author   : Mohammad Yusuf
# Date     : Dec 14 2025
# Purpose  : ICC2 library setup, NDM creation, parasitic tech,
#            multi-corner scenarios, UPF load, import
############################################################################

############################################################################
# NDM REFERENCE LIBRARIES
############################################################################
set ref /home/user21/Desktop/projects/Synopsys/SAED_32nm/NDM/

set my_ref_libs [join "
    $ref/saed32_1p9m_tech.ndm
    $ref/saed32_hvt.ndm
    $ref/saed32_lvt.ndm
    $ref/saed32_rvt.ndm
    $ref/saed32_sram_lp.ndm
"]

############################################################################
# CREATE ICC2 DESIGN LIBRARY
############################################################################
create_lib -technology /home/user21/Desktop/projects/Synopsys/SAED_32nm/tech/saed32nm_1p9m.tf \
           -ref_libs $my_ref_libs \
           orca_demo_v1.dlib

############################################################################
# READ GATE-LEVEL NETLIST FROM DC
############################################################################
read_verilog ../../synthesis_tools/work/orca_top_gln.v

############################################################################
# PARASITIC TECHNOLOGY (TLU+ Cmin/Cmax)
############################################################################
read_parasitic_tech \
    -tlup     {/home/user21/Desktop/ref/tech/saed32nm_1p9m_Cmin.tluplus} \
    -layermap /home/user21/Desktop/ref/tech/saed32nm_tf_itf_tluplus.map \
    -name     tlu_min

read_parasitic_tech \
    -tlup     {/home/user21/Desktop/ref/tech/saed32nm_1p9m_Cmax.tluplus} \
    -layermap /home/user21/Desktop/ref/tech/saed32nm_tf_itf_tluplus.map \
    -name     tlu_max

############################################################################
# PARASITIC PARAMETERS
# late_spec tlu_max  → setup (max delay)
# early_spec tlu_min → hold  (min delay)
# Corners: ss0p95v25c, ss0p95v125c
############################################################################
set_parasitic_parameters \
    -late_spec       tlu_max \
    -early_spec      tlu_min \
    -late_temperature  125   \
    -early_temperature  25   \
    -corners           ss0p95v25c

set_parasitic_parameters \
    -late_spec       tlu_max \
    -early_spec      tlu_min \
    -late_temperature  125   \
    -early_temperature  25   \
    -corners           ss0p95v125c

report_parasitics

############################################################################
# SITE DEFINITION
############################################################################
set_attribute [get_site_defs unit] symmetry   Y
set_attribute [get_site_defs unit] is_default true

############################################################################
# ROUTING LAYER DIRECTIONS
# Horizontal : M1 M3 M5 M7 M9
# Vertical   : M2 M4 M6 M8
# Max layer  : M9
############################################################################
set_attribute [get_layers {M1 M3 M5 M7 M9}] routing_direction horizontal
set_attribute [get_layers {M2 M4 M6 M8}]    routing_direction vertical
set_ignored_layers -max_routing_layer M9

############################################################################
# MULTI-CORNER SCENARIOS
# Mode: func
# Corners: ss0p95v25c, ss0p95v125c
############################################################################
remove_corners   -all
remove_modes     -all
remove_scenarios -all

create_mode   func
create_corner ss0p95v25c
create_corner ss0p95v125c

create_scenario -name func:ss0p95v25c  -mode func -corner ss0p95v25c
create_scenario -name func:ss0p95v125c -mode func -corner ss0p95v125c

report_scenarios
report_corners
report_modes
report_design_mismatch
report_design -library -all

############################################################################
# READ SDC CONSTRAINTS
############################################################################
read_sdc ../../synthesis_tools/work/orca_top.sdc

report_clock
report_timing
report_timing -delay_type min

############################################################################
# LOAD UPF POWER INTENT
############################################################################
load_upf  ../inputs/orca_top.upf
commit_upf
report_incomplete_upf
set_app_options -list {mv.incomplete_upf.enable {true}}
commit_upf

############################################################################
# SAVE IMPORT BLOCK
############################################################################
save_block -as import_done
