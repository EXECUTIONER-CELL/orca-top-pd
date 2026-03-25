############################################################################
# Script   : routing_orca.tcl
# Design   : ORCA_TOP (Full SoC)
# Tool     : Synopsys IC Compiler 2 (ICC2) R-2020.09-SP2
# Node     : SAED 32nm
# Author   : Mohammad Yusuf
# Purpose  : Pre-route checks, timing-driven routing,
#            route_auto/opt/eco, filler insertion
############################################################################

############################################################################
# HOST OPTIONS (parallel routing)
############################################################################
set_host_options -max_core 16

############################################################################
# PRE-ROUTING REPORTS
############################################################################
file mkdir ../reports/routing
file mkdir ../reports/routing/pre_check

report_routing_rules  -verbose
report_routing_rules  -verbose         > ../reports/routing/pre_check/report_routing_rules.rpt
report_clock_routing_rules             > ../reports/routing/pre_check/report_clock_rules.rpt

report_timing -transition_time -capacitance -voltage \
                                       > ../reports/routing/pre_check/report_timing.rpt
report_congestion                      > ../reports/routing/pre_check/report_congestion.rpt
report_timing -transition_time -capacitance -voltage -delay_type min \
                                       > ../reports/routing/pre_check/report_timing_hold.rpt
report_clocks -skew                    > ../reports/routing/pre_check/report_clocks.rpt
report_design -all                     > ../reports/routing/pre_check/report_design.rpt
check_design -checks pre_route_stage   > ../reports/routing/pre_check/check_route_pre.rpt
report_design -all
report_constraints                     > ../reports/routing/pre_check/report_constraints.rpt

############################################################################
# ROUTING APP OPTIONS (all stages timing-driven)
############################################################################
set_app_options -list {route.global.timing_driven {true}}
set_app_options -list {route.detail.timing_driven {true}}
set_app_options -list {route.track.timing_driven  {true}}

############################################################################
# ROUTE AUTO
# -max_detail_route_iterations 10 : more iterations for complex SoC
############################################################################
route_auto -max_detail_route_iterations 10

############################################################################
# ROUTE OPTIMIZATION (timing + DRC fixing)
############################################################################
route_opt

############################################################################
# ROUTE ECO (final DRC cleanup — reroute any problematic nets)
############################################################################
route_eco -reroute any_nets

############################################################################
# FILLER CELL INSERTION
# SHFILL*_LVT: fill empty sites for DRC compliance
############################################################################
create_stdcell_fillers -lib_cells [get_lib_cells *SHFILL*_LVT]
connect_pg_net
remove_stdcell_fillers_with_violation

############################################################################
# POST-ROUTING SANITY CHECKS
# (add report_timing, report_drc etc. as needed)
############################################################################
