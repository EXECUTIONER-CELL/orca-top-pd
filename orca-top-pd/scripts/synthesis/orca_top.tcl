############################################################################
# Script   : orca_top.tcl
# Design   : ORCA_TOP (Full SoC)
# Tool     : Synopsys Design Compiler NXT R-2020.09-SP5-5
# Node     : SAED 32nm (LVT / HVT / RVT)
# Author   : Mohammad Yusuf
# Date     : Dec 13 2025
# Purpose  : RTL synthesis — library setup, MW lib creation,
#            multi-corner libraries, compile_ultra, outputs
############################################################################

############################################################################
# HOST OPTIONS
############################################################################
set_host_option -max_core 16

############################################################################
# REFERENCE LIBRARY PATH
############################################################################
set ref_path "/projects/proj/ref/CLIBs/"

set my_ref_libs {$ref_path/saed32_1p9m_tech.ndm/ \
                 $ref_path/saed32_hvt.ndm/        \
                 $ref_path/saed32_lvt.ndm/         \
                 $ref_path/saed32_rvt.ndm          \
                 $ref_path/saed32_sram_lp.ndm}

set tech_libs {/projects/proj/ref/tech/saed32nm_1p9m.tf}

############################################################################
# SYNTHETIC LIBRARY (DesignWare)
############################################################################
set synthetic_library dw_foundation.sldb

############################################################################
# TARGET LIBRARY PATH
############################################################################
set target_lib "/projects/proj/ref/tech/"

############################################################################
# CREATE MILKYWAY LIBRARY
############################################################################
create_mw_lib orca.mw -technology $tech_libs -open

############################################################################
# TIMING LIBRARY PATHS (.db Liberty files)
############################################################################
set lvt "/projects/SAED32_EDK/stdcell_lvt/db_ccs/"
set hvt "/projects/SAED32_EDK/stdcell_hvt/db_ccs/"
set rvt "/projects/SAED32_EDK/stdcell_rvt/db_ccs/"

############################################################################
# TARGET LIBRARY
# Corners: SS 0.95V 25C, FF 0.95V 25C, SS 0.95V 125C, FF 0.95V 125C
############################################################################
set target_library " $lvt/saed32lvt_ss0p95v25c.db  \
                     $lvt/saed32lvt_ff0p95v25c.db   \
                     $lvt/saed32lvt_ss0p95v125c.db  \
                     $lvt/saed32lvt_ff0p95v125c.db "

############################################################################
# LINK LIBRARY (all corners: LVT + RVT + HVT)
############################################################################
set link_library " $lvt/saed32lvt_ss0p95v25c.db  \
                   $lvt/saed32lvt_ff0p95v25c.db   \
                   $lvt/saed32lvt_ss0p95v125c.db  \
                   $lvt/saed32lvt_ff0p95v125c.db  "

############################################################################
# REFERENCE LIBRARY (full multi-corner: LVT + RVT + HVT all corners)
############################################################################
#set reference_library " $lvt/saed32lvt_ss0p95v25c.db  \
#                         $rvt/saed32rvt_ss0p95v25c.db  \
#                         $hvt/saed32hvt_ff0p95v25c.db  \
#                         $lvt/saed32lvt_ff0p95v25c.db  \
#                         $rvt/saed32rvt_ff0p95v25c.db  \
#                         $hvt/saed32hvt_ss0p95v125c.db \
#                         $lvt/saed32lvt_ss0p95v125c.db \
#                         $rvt/saed32rvt_ss0p95v125c.db \
#                         $lvt/saed32lvt_ff0p95v125c.db \
#                         $hvt/saed32hvt_ff0p95v125c.db \
#                         $rvt/saed32rvt_ff0p95v125c.db "

############################################################################
# READ RTL (SystemVerilog)
############################################################################
set rtl_path {/projects/trainer_scripts/orca_top/ORCA_WRAPPER}
analyze -format sverilog [glob $rtl_path/*.v]
elaborate  ORCA_TOP
current_design ORCA_TOP

############################################################################
# TIMING CONSTRAINTS
############################################################################
read_sdc ../constraints/orca_top.sdc

############################################################################
# STANDARD VECTOR FILE
############################################################################
set_svf > ../outputs/orca_top.svf

############################################################################
# PARASITIC TECHNOLOGY (TLU+ for RC estimation during synthesis)
############################################################################
set_tlu_plus_files \
    -max_tluplus  /projects/SAED_32nm/tech/saed32nm_1p9m_Cmax.tluplus \
    -tech2itf_map /projects/SAED_32nm/tech/saed32nm_tf_itf_tluplus.map

set_tlu_plus_files \
    -max_tluplus  /projects/SAED_32nm/tech/saed32nm_1p9m_Cmin.tluplus \
    -tech2itf_map /projects/SAED_32nm/tech/saed32nm_tf_itf_tluplus.map

############################################################################
# COMPILE
# compile_ultra: translation + optimization + mapping
# -no_autoungroup    : preserve hierarchy for ICC2 handoff
# -no_boundary_opt   : no cross-boundary optimization
############################################################################
compile_ultra -no_autoungroup -no_boundary_optimization

############################################################################
# POST-SYNTHESIS QoR REPORTS
############################################################################
report_area
report_power

############################################################################
# OUTPUT FILES
############################################################################
sh mkdir ../reports

write_sdc  orca_top.sdc > ../outputs/orca_top.sdc
report_timing           > ../reports/report_timing.rpt
write_file -format verilog -hierarchy -output > ../outputs/orca_top_gln.v

return 1
