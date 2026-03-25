############################################################################
# Script   : setup.tcl (floorplan section)
# Design   : ORCA_TOP (Full SoC)
# Tool     : Synopsys IC Compiler 2 (ICC2) R-2020.09-SP2
# Node     : SAED 32nm
# Author   : Mohammad Yusuf
# Purpose  : Floorplan — die/core setup, macro placement,
#            keepout margins, endcap/tap cells
############################################################################

############################################################################
# PRE-FLOORPLAN SANITY CHECKS
############################################################################
file mkdir ../reports/floorplan

check_netlist                    > ../reports/floorplan/check_netlist_pre.rpt
report_design -all               > ../reports/floorplan/report_design_pre.rpt
report_design_mismatch           > ../reports/floorplan/report_design_mismatches_pre.rpt
get_ports                        > ../reports/floorplan/get_ports.rpt
get_ports -filter {direction==in}  > ../reports/floorplan/get_inputs_ports.rpt
get_ports -filter {direction==out} > ../reports/floorplan/get_outputs_ports.rpt
sizeof_collection [get_ports *]  > ../reports/floorplan/get_ports_count.rpt

############################################################################
# FLOORPLAN INITIALIZATION
# Die  : 600um x 600um
# Core offset: 15um all sides
# Core utilization: 0.5 (50%)
############################################################################
initialize_floorplan \
    -boundary        {{0.0 0.00} {600 600}} \
    -core_offset     {15} \
    -core_utilization 0.5

# Alternative (utilization-only mode):
# initialize_floorplan -core_utilization 0.4 -core_offset 15

report_utilization

############################################################################
# BLOCK SHAPING & PIN PLACEMENT
# shape_blocks: let tool place macros automatically
# IO pins on M3 M5 M4 sides 1/2 (inputs) and 3/4 (outputs)
############################################################################
shape_blocks    ;# place macros via tool

set_block_pin_constraints -self
place_pins -ports [get_ports *]

# Alternative pin placement (inputs on sides 1/2, outputs on 3/4):
set_block_pin_constraints -self -allowed_layers {M3 M5 M4} -sides {1 2}
place_pins -ports [get_ports [all_inputs]]
set_block_pin_constraints -self -allowed_layers {M3 M5 M4} -sides {3 4}
place_pins -ports [get_ports [all_outputs]]

############################################################################
# MACRO PLACEMENT (create_placement -floorplan for initial macro location)
############################################################################
create_placement -floorplan
report_macro_constraints

############################################################################
# KEEPOUT MARGINS (hard, 3um on all sides around each macro)
# Applied to: SDRAM FIFOs, RISC REG_FILE, CONTEXT_MEM, PCI FIFOs
############################################################################
create_keepout_margin \
    {I_SDRAM_TOP/I_SDRAM_READ_FIFO/SD_FIFO_RAM_1
     I_SDRAM_TOP/I_SDRAM_READ_FIFO/SD_FIFO_RAM_0} \
    -type hard -outer {3 3 3 3}

create_keepout_margin \
    {I_SDRAM_TOP/I_SDRAM_WRITE_FIFO/SD_FIFO_RAM_1
     I_SDRAM_TOP/I_SDRAM_WRITE_FIFO/SD_FIFO_RAM_0} \
    -type hard -outer {3 3 3 3}

create_keepout_margin \
    {I_RISC_CORE/I_REG_FILE/REG_FILE_A_RAM
     I_RISC_CORE/I_REG_FILE/REG_FILE_B_RAM
     I_RISC_CORE/I_REG_FILE/REG_FILE_C_RAM
     I_RISC_CORE/I_REG_FILE/REG_FILE_D_RAM} \
    -type hard -outer {3 3 3 3}

create_keepout_margin \
    {I_CONTEXT_MEM/I_CONTEXT_RAM_3_4
     I_CONTEXT_MEM/I_CONTEXT_RAM_3_3
     I_CONTEXT_MEM/I_CONTEXT_RAM_3_2
     I_CONTEXT_MEM/I_CONTEXT_RAM_3_1
     I_CONTEXT_MEM/I_CONTEXT_RAM_2_4
     I_CONTEXT_MEM/I_CONTEXT_RAM_2_3
     I_CONTEXT_MEM/I_CONTEXT_RAM_2_2
     I_CONTEXT_MEM/I_CONTEXT_RAM_2_1
     I_CONTEXT_MEM/I_CONTEXT_RAM_1_4
     I_CONTEXT_MEM/I_CONTEXT_RAM_1_3
     I_CONTEXT_MEM/I_CONTEXT_RAM_1_2
     I_CONTEXT_MEM/I_CONTEXT_RAM_1_1
     I_CONTEXT_MEM/I_CONTEXT_RAM_0_4
     I_CONTEXT_MEM/I_CONTEXT_RAM_0_3
     I_CONTEXT_MEM/I_CONTEXT_RAM_0_2
     I_CONTEXT_MEM/I_CONTEXT_RAM_0_1} \
    -type hard -outer {3 3 3 3}

create_keepout_margin \
    {I_PCI_TOP/I_PCI_READ_FIFO/PCI_FIFO_RAM_8
     I_PCI_TOP/I_PCI_READ_FIFO/PCI_FIFO_RAM_7
     I_PCI_TOP/I_PCI_READ_FIFO/PCI_FIFO_RAM_6
     I_PCI_TOP/I_PCI_READ_FIFO/PCI_FIFO_RAM_5
     I_PCI_TOP/I_PCI_READ_FIFO/PCI_FIFO_RAM_4
     I_PCI_TOP/I_PCI_READ_FIFO/PCI_FIFO_RAM_3
     I_PCI_TOP/I_PCI_READ_FIFO/PCI_FIFO_RAM_2
     I_PCI_TOP/I_PCI_READ_FIFO/PCI_FIFO_RAM_1
     I_PCI_TOP/I_PCI_WRITE_FIFO/PCI_FIFO_RAM_8
     I_PCI_TOP/I_PCI_WRITE_FIFO/PCI_FIFO_RAM_7
     I_PCI_TOP/I_PCI_WRITE_FIFO/PCI_FIFO_RAM_6
     I_PCI_TOP/I_PCI_WRITE_FIFO/PCI_FIFO_RAM_5
     I_PCI_TOP/I_PCI_WRITE_FIFO/PCI_FIFO_RAM_4
     I_PCI_TOP/I_PCI_WRITE_FIFO/PCI_FIFO_RAM_3
     I_PCI_TOP/I_PCI_WRITE_FIFO/PCI_FIFO_RAM_2
     I_PCI_TOP/I_PCI_WRITE_FIFO/PCI_FIFO_RAM_1} \
    -type hard -outer {3 3 3 3}

# Fix all macros in place
set_attribute [get_cells -physical_context \
    -filter design_type==macro] physical_status fixed

############################################################################
# MACRO LIST (for reference and power planning)
############################################################################
set all_macros [get_cells -hierarchical \
    -filter "is_hard_macro && !is_physical_only"]

set hm(orca_top) [get_cells -filter "is_hard_macro==true" \
    -physical_context {
        I_PCI_TOP/I_PCI_READ_FIFO/PCI_FIFO_RAM_8
        I_PCI_TOP/I_PCI_READ_FIFO/PCI_FIFO_RAM_7
        I_CONTEXT_MEM/I_CONTEXT_RAM_3_4
        I_CONTEXT_MEM/I_CONTEXT_RAM_0_1
        I_RISC_CORE/I_REG_FILE/REG_FILE_A_RAM
        I_SDRAM_TOP/I_SDRAM_READ_FIFO/SD_FIFO_RAM_1
        I_SDRAM_TOP/I_SDRAM_READ_FIFO/SD_FIFO_RAM_0
        I_SDRAM_TOP/I_SDRAM_WRITE_FIFO/SD_FIFO_RAM_1
        I_SDRAM_TOP/I_SDRAM_WRITE_FIFO/SD_FIFO_RAM_0}]

set hm(top) [remove_from_collection $all_macros $hm(orca_top)]

############################################################################
# ENDCAP CELLS
# CAPT2 (top), CAPB2 (bottom), CAPBIN13 (right), CAPBTAP6 (left)
############################################################################
get_lib_cells

set_boundary_cell_rules \
    -top_boundary_cells    [get_lib_cells */*CAPT2]   \
    -bottom_boundary_cells [get_lib_cells */*CAPB2]   \
    -right_boundary_cell   [get_lib_cells */*CAPBIN13] \
    -left_boundary_cell    [get_lib_cellells */*CAPBTAP6] \
    -prefix ENDCAP

compile_targeted_boundary_cells -target_objects [get_voltage_area]

############################################################################
# TAP CELLS (Well-tap for latch-up prevention)
# saed32_hvt DCAP_HVT, distance=30um, every row
############################################################################
create_tap_cells \
    -lib_cell saed32_hvt|saed32_hvt_std/DCAP_HVT \
    -distance 30 \
    -pattern  every_row

remove_cells *tap*

check_legality -cells [get_cells bonud*]
check_legality -cells [get_cells tap*]

############################################################################
# FINAL SANITY CHECKS
############################################################################
check_legality -verbose
get_placement_blockages
report_keepout_margins

############################################################################
# SAVE BLOCK
############################################################################
save_block -as floorplan_done
