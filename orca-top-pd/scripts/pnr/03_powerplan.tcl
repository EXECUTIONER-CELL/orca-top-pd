############################################################################
# Script   : powerplan.tcl
# Design   : ORCA_TOP (Full SoC)
# Tool     : Synopsys IC Compiler 2 (ICC2) R-2020.09-SP2
# Node     : SAED 32nm
# Author   : Mohammad Yusuf
# Purpose  : VDD/VSS power ring (M7/M8), M7/M8 mesh, M1 rails,
#            PG verification
############################################################################

############################################################################
# IDENTIFY HARD MACROS
############################################################################
set all_macros [get_cells -hierarchical \
    -filter "is_hard_macro && !is_physical_only"]

set hm(orca_top) [get_cells -filter "is_hard_macro==true" \
    -physical_context { I_PCI_TOP/I_PCI_READ_FIFO/PCI_FIFO_RAM_8
                        I_PCI_TOP/I_PCI_READ_FIFO/PCI_FIFO_RAM_7
                        I_PCI_TOP/I_PCI_WRITE_FIFO/PCI_FIFO_RAM_8
                        I_CONTEXT_MEM/I_CONTEXT_RAM_3_4
                        I_CONTEXT_MEM/I_CONTEXT_RAM_0_1
                        I_RISC_CORE/I_REG_FILE/REG_FILE_A_RAM
                        I_SDRAM_TOP/I_SDRAM_READ_FIFO/SD_FIFO_RAM_1
                        I_SDRAM_TOP/I_SDRAM_READ_FIFO/SD_FIFO_RAM_0
                        I_SDRAM_TOP/I_SDRAM_WRITE_FIFO/SD_FIFO_RAM_1
                        I_SDRAM_TOP/I_SDRAM_WRITE_FIFO/SD_FIFO_RAM_0}]

set hm(top) [remove_from_collection $all_macros $hm(orca_top)]

############################################################################
# CLEAN EXISTING PG STRUCTURES
############################################################################
remove_pg_strategies        -all
remove_pg_patterns          -all
remove_pg_regions           -all
remove_pg_via_master_rules  -all
remove_pg_strategy_via_rules -all
remove_routes -net_types {power ground} \
    -ring -stripe -lib_cell_pin_connect
connect_pg_net

############################################################################
# CORE RING (M7 horizontal / M8 vertical)
# Width  : 1.5um (both H and V)
# Spacing: 1um   (both H and V)
# Nets   : VDD VSS, offset 1um from core
############################################################################
create_pg_ring_pattern ring_pattern \
    -horizontal_layer   M7 \
    -horizontal_width   {1.5} \
    -horizontal_spacing {1}   \
    -vertical_layer     M8    \
    -vertical_width     {1.5} \
    -vertical_spacing   {1}   \
    -corner_bridge      true

set_pg_strategy core_ring \
    -pattern {{name: ring_pattern} {nets: {VDD VSS}} {offset: {1 1}}} \
    -core \
    -extension {{{side: 1 2} {direction: R} {stop: design_boundary_and_generate_pin}} \
                {{side: 3}   {direction: R} {stop: design_boundary_and_generate_pin}}}

compile_pg -strategies core_ring

############################################################################
# UPPER MESH — M7/M8 (M5M6 strategy name)
# M8 vertical  : width=0.75um, pitch=11um
# M7 horizontal: width=0.75um, pitch=11um
############################################################################
create_pg_mesh_pattern mesh_pattern \
    -layers {{{vertical_layer:   M8} {width: 0.75} {pitch: 11} \
               {spacing: interleaving} {trim: true}}           \
             {{horizontal_layer: M7} {width: 0.75}             \
               {pitch: 11} {spacing: interleaving} {trim: true}}} \
    -via_rule {{intersection: adjacent} {via_master: default}}

set_pg_strategy M5M6_mesh \
    -pattern  {{name: mesh_pattern} {nets: VDD VSS}} \
    -core \
    -extension {{nets: VDD VSS} {stop: outermost_ring}}

compile_pg -strategies M5M6_mesh

############################################################################
# M1 STD CELL RAILS
# Pattern: rail_pat on M1
# Via rule: NIL (no via insertion for rails)
############################################################################
create_pg_std_cell_conn_pattern rail_pat -layers {M1}

set_pg_strategy rail_strategy \
    -core \
    -pattern {{name: rail_pat} {nets: {VDD VSS}}}

set_pg_strategy_via_rule rail_via_rule \
    -via_rule {{intersection: all} {via_master: NIL}}

compile_pg -strategies {rail_strategy} -via_rule rail_via_rule

############################################################################
# PG VERIFICATION
############################################################################
file mkdir ../reports/powerplan

check_pg_connectivity  > ../reports/powerplan/check_pg_connectivity.rpt
check_pg_missing_vias  > ../reports/powerplan/check_pg_missing_vias.rpt
check_pg_drc           > ../reports/powerplan/check_pg_drc.rpt

return 1
