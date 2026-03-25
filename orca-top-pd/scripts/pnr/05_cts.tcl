############################################################################
# Script   : cts_orca.tcl
# Design   : ORCA_TOP (Full SoC)
# Tool     : Synopsys IC Compiler 2 (ICC2) R-2020.09-SP2
# Node     : SAED 32nm
# Author   : Mohammad Yusuf
# Purpose  : Clock tree synthesis — cell selection, skew/latency
#            targets, cts_opt, post-CTS reports
############################################################################

############################################################################
# PRE-CTS REPORTS
############################################################################
file mkdir ../reports/cts

check_design -checks pre_clock_tree_stage
check_design -checks pre_clock_tree_stage > ../reports/cts/check_design_pre_cts.rpt
check_legality -verbose
check_legality                            > ../reports/cts/check_legality.rpt
report_timing

report_timing -transition_time -capacitance -voltage -nets -max_paths 10 \
    > ../reports/cts/report_timing.rpt
report_timing -transition_time -capacitance -voltage -nets -max_paths 10 \
    > ../reports/cts/report_timing.rpt

report_congestion                         > ../reports/cts/report_congestion.rpt
report_clock_timing -type skew            > ../reports/cts/report_clock.rpt
report_clock_tree_options                 > ../reports/cts/report_clock_tree_option.rpt
report_clock_qor -type structure
report_clock_qor -type structure          > ../reports/cts/report_clock_qor.rpt

############################################################################
# CTS CELL SELECTION
# Include: NBUFF (LVT/RVT), INVX (LVT/RVT), CGL, LSUP, DFF
# Exclude all other cells from CTS usage
############################################################################
set_lib_cell_purpose -exclude cts [get_lib_cells]

set cts_cells [get_lib_cells \
    "*/NBUFF*LVT */NBUFF*RVT */INVX*_LVT */INVX*RVT */CGL* */LSUP* */DFF*"]

set_dont_touch        $cts_cells
set_lib_cell_purpose  -include cts $cts_cells

############################################################################
# CLOCK UNCERTAINTY
# Setup: 0.1ns | Hold: 0.05ns
############################################################################
set_clock_uncertainty 0.1  -setup [all_clocks]
set_clock_uncertainty 0.05 -hold  [all_clocks]

############################################################################
# CLOCK TREE OPTIONS
# Clock   : clk (orca_clk)
# Skew    : 30ps target
# Latency : 30ps target
############################################################################
set_clock_tree_options \
    -target_skew    0.03 \
    -target_latency 0.03 \
    -clocks         clk

############################################################################
# CTS APP OPTIONS
############################################################################
set_app_options -name clock_opt.flow.enable_ccd -value false
set_max_transition 5.0 [current_design]

############################################################################
# CLOCK TREE SYNTHESIS (ts_optimizations)
############################################################################
cts_opt

############################################################################
# POST-CTS REPORTS
############################################################################
sh mkdir ../reports/cts/post_check

report_routing_rules  -verbose \
    > ../reports/cts/post_check/report_routing_rules.rpt
report_clock_routing_rules -verbose \
    > ../reports/cts/post_check/report_routing_clock_rules.rpt
report_clock_routing_rules \
    > ../reports/cts/post_check/report_routing_clock_rules.rpt

report_timing -transition_time -capacitance -voltage \
    > ../reports/cts/post_check/report_timing.rpt
report_congestion -transition_time -capacitance -voltage \
    > ../reports/cts/post_check/report_congestion.rpt
report_congestion \
    > ../reports/cts/post_check/report_congestion.rpt
report_timing -transition_time -capacitance -voltage -delay_type min \
    > ../reports/cts/post_check/report_timing_hold.rpt

report_clocks -skew                     > ../reports/cts/post_check/report_clocks.rpt
report_design -all                      > ../reports/cts/post_check/report_design.rpt
check_design -checks pre_route_stage    > ../reports/cts/post_check/check_route_pre.rpt
report_design -all
report_constraints                      > ../reports/cts/post_check/report_constraints.rpt

############################################################################
# SAVE BLOCK
############################################################################
save_block -as cts_block
save_lib
