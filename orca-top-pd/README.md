# ORCA_TOP SoC — Full RTL to GDSII Physical Design
### 32nm SAED Process | Synopsys DC NXT R-2020.09-SP5-5 + ICC2 R-2020.09-SP2

---

## 📌 Project Overview

Complete **RTL-to-GDSII Physical Design** of the **ORCA_TOP** — a full-featured SoC containing a RISC processor core, SDRAM controller, PCI interface, and context memory subsystem. Implemented on the **SAED 32nm (9-metal, 1p9m)** process using the full Synopsys tool suite.

This is a significantly more complex design than a simple UART block — with **51,131 standard cells**, **40 hard macros**, multi-corner scenarios, and a **600µm × 600µm** die footprint. The implementation achieves **timing closure with +8.21ns of setup slack** on the critical path.

---

## 🏗️ Design Architecture

```
ORCA_TOP
├── I_RISC_CORE          — RISC processor core
│   └── I_REG_FILE       — Register file (REG_FILE_A/B/C/D_RAM — 4 macros)
├── I_SDRAM_TOP          — SDRAM memory controller
│   ├── I_SDRAM_READ_FIFO  — SD_FIFO_RAM_0/1 (2 macros)
│   └── I_SDRAM_WRITE_FIFO — SD_FIFO_RAM_0/1 (2 macros)
├── I_CONTEXT_MEM        — Context memory (16 SRAM macros: RAM_0_1 to RAM_3_4)
├── I_PCI_TOP            — PCI interface
│   ├── I_PCI_READ_FIFO  — PCI_FIFO_RAM_1 to RAM_8 (8 macros)
│   └── I_PCI_WRITE_FIFO — PCI_FIFO_RAM_1 to RAM_8 (8 macros)
└── CLOCKING             — Clock generation & distribution
    └── NBUFFX16_LVT, DFFX1_LVT, DFFARX1_HVT clock cells
```

---

## 🛠️ Tools & Technology Stack

| Category               | Tool / Technology                            |
|------------------------|----------------------------------------------|
| Logic Synthesis        | Synopsys DC NXT **R-2020.09-SP5-5**          |
| Place & Route          | Synopsys IC Compiler 2 **R-2020.09-SP2**     |
| Static Timing Analysis | Synopsys PrimeTime                           |
| Process Node           | **SAED 32nm (1p9m — 9 metal layers)**        |
| Std Cell Libraries     | saed32_lvt / saed32_hvt / saed32_rvt         |
| NDM Libraries          | saed32_hvt.ndm / lvt.ndm / rvt.ndm / sram_lp.ndm |
| Design Library         | `orca_demo_v1.dlib`                          |
| RTL Language           | **SystemVerilog** (`ORCA_WRAPPER/*.v`)       |
| Parasitic Extraction   | TLU+ (Cmin tlu_min / Cmax tlu_max)           |
| Power Intent           | UPF (Unified Power Format)                   |
| Timing Constraints     | SDC                                          |
| Timing Corners         | SS 0.95V 25C / SS 0.95V 125C                |
| Scenarios              | func:ss0p95v25c / func:ss0p95v125c           |

---

## 🔄 Complete PnR Flow

```
SystemVerilog RTL  —  ORCA_WRAPPER/*.v
          │
          ▼
┌──────────────────────────────────────────────┐
│  SYNTHESIS  (DC NXT R-2020.09-SP5-5)         │
│                                              │
│  • set_host_option -max_core 16              │
│  • analyze -format sverilog [glob *.v]       │
│  • elaborate ORCA_TOP                        │
│  • read_sdc orca_top.sdc                     │
│  • TLU+: Cmax + Cmin parasitic tech          │
│  • Libraries: LVT ss/ff 25C/125C            │
│  • compile_ultra -no_autoungroup             │
│               -no_boundary_optimization      │
│  • Outputs: orca_top_gln.v (5.7 MiB)        │
│             orca_top.sdc, orca_top.svf       │
└─────────────────┬────────────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────────────┐
│  ICC2 SETUP  (R-2020.09-SP2)                 │
│                                              │
│  • create_lib orca_demo_v1.dlib              │
│  • NDM: hvt+lvt+rvt+sram_lp                 │
│  • TLU+: tlu_min(Cmin) + tlu_max(Cmax)      │
│  • Corners: ss0p95v25c, ss0p95v125c          │
│  • Scenarios: func:ss0p95v25c               │
│               func:ss0p95v125c              │
│  • Layer directions: H=M1/M3/M5/M7/M9       │
│                      V=M2/M4/M6/M8          │
│  • Max routing layer: M9                     │
│  • load_upf + commit_upf                     │
│  • save_block -as import_done                │
└─────────────────┬────────────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────────────┐
│  FLOORPLAN  (ICC2)                           │
│                                              │
│  • Die: 600µm × 600µm                        │
│  • Core offset: 15µm | Utilization: 50%      │
│  • 40 hard macros placed & fixed             │
│  • Keepout: 3µm hard margin all macros       │
│  • IO pins: M3/M5/M4 sides 1-4              │
│  • Endcap: CAPT2/CAPB2/CAPBIN13/CAPBTAP6    │
│  • Tap cells: DCAP_HVT, dist=30, every row  │
│  • save_block -as floorplan_done             │
└─────────────────┬────────────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────────────┐
│  POWER PLANNING  (ICC2)                      │
│                                              │
│  • Ring  : M7(H)/M8(V), width=1.5µm         │
│            spacing=1µm, corner_bridge=true   │
│  • Mesh  : M7/M8, width=0.75µm, pitch=11µm  │
│  • Rails : M1 (VDD/VSS std cell rails)       │
│  • check_pg_missing_vias → 0 ✅             │
│  • check_pg_drc          → Clean ✅          │
│  • check_pg_connectivity → All connected ✅  │
│  • VDD: 81,126 wires / 95,547 vias           │
│  • VSS: 77,791 wires / 96,279 vias           │
│  • save_block -as powerplan_done             │
└─────────────────┬────────────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────────────┐
│  PLACEMENT  (ICC2)                           │
│                                              │
│  • set_host_options -max_cores 16            │
│  • magnet_placement for all inputs/outputs   │
│  • max_density: 0.6                          │
│  • Parasitics: tlup_min/max both corners     │
│  • VDD=0.95V, VSS=0.0V                       │
│  • create_placement -timing_driven           │
│  • place_opt (pre-CTS optimization)          │
│  • Cells: SDFFNARX1_HVT, MUX2X1_HVT,        │
│           AO cells, NBUFF, INVX32_HVT        │
│  • save_block -as place_opt_done             │
└─────────────────┬────────────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────────────┐
│  CLOCK TREE SYNTHESIS  (ICC2)                │
│                                              │
│  • Clock: orca_clk                           │
│  • CTS cells: NBUFF*LVT/RVT, INVX*LVT/RVT  │
│               CGL*, LSUP*, DFF*              │
│  • Uncertainty: setup=0.1ns, hold=0.05ns    │
│  • Target skew   : 30ps                      │
│  • Target latency: 30ps                      │
│  • CCD disabled                              │
│  • Max transition: 5.0ns                     │
│  • cts_opt                                   │
│  • save_block -as cts_block                  │
└─────────────────┬────────────────────────────┘
                  │
                  ▼
┌──────────────────────────────────────────────┐
│  ROUTING  (ICC2)                             │
│                                              │
│  • set_host_options -max_core 16             │
│  • All stages timing-driven                  │
│    (global / detail / track)                 │
│  • route_auto -max_detail_route_iterations 10│
│  • route_opt                                 │
│  • route_eco -reroute any_nets               │
│  • Fillers: SHFILL*_LVT (saed32_lvt)        │
│  • save_block -as routing_done               │
└─────────────────┬────────────────────────────┘
                  │
                  ▼
               GDSII
```

---

## ⚙️ Key Design Parameters

| Parameter               | Value                                        |
|-------------------------|----------------------------------------------|
| Process Node            | SAED 32nm (1p9m)                             |
| Top Module              | `ORCA_TOP`                                   |
| Tool (Synthesis)        | DC NXT **R-2020.09-SP5-5** (Dec 13, 2025)   |
| Tool (PnR/STA)          | ICC2 **R-2020.09-SP2** (Dec 14-18, 2025)    |
| Design Library          | `orca_demo_v1.dlib`                          |
| Operating Voltage       | **0.95V** (VDD)                              |
| Timing Corners          | SS 0.95V 25°C / SS 0.95V 125°C              |
| Active Scenarios        | 2 (`func:ss0p95v25c`, `func:ss0p95v125c`)   |
| Die Size                | **600µm × 600µm**                            |
| Core Offset             | 15µm                                         |
| Core Utilization        | **50%**                                      |
| Max Routing Layer       | M9                                           |
| Total Standard Cells    | **51,131**                                   |
| Hard Macro Cells        | **40**                                       |
| Flip-Flops              | **306**                                      |
| Latches                 | 36                                           |
| ICGs (Clock Gates)      | **36**                                       |
| Buffers                 | 69                                           |
| Inverters               | 45                                           |
| Clock Name              | `orca_clk`                                   |
| CTS Target Skew         | **30ps**                                     |
| CTS Target Latency      | **30ps**                                     |
| Setup Uncertainty       | 0.1ns                                        |
| Hold Uncertainty        | 0.05ns                                       |
| Parallel Cores Used     | **16**                                       |

---

## ✅ Timing Results (Post-CTS, from actual ICC2 report)

| Metric                  | Value                    |
|-------------------------|--------------------------|
| Clock                   | `orca_clk`               |
| Corner                  | ss0p95v25c               |
| Scenario                | func:ss0p95v25c          |
| Path Type               | Max (Setup)              |
| Data Arrival Time       | 9.67 ns                  |
| Data Required Time      | 17.88 ns                 |
| **Setup Slack (WNS)**   | **+8.21 ns ✅ MET**      |
| Clock Network Delay     | 0.44 ns (propagated)     |
| Operating Voltage       | 0.95V (rail VDD)         |

**Critical Path:** `snps_clk_chain_0/U_shftreg_0/ff_1/q_reg` (DFFNX1_HVT) → AND2X1_HVT → OR2X1_HVT → `snps_OCC_controller/.../pipeline_or_tree_l_reg` (DFFARX1_HVT)

---

## 🔋 Power Network Results (from actual ICC2 reports)

| Check                      | Result              |
|----------------------------|---------------------|
| `check_pg_missing_vias`    | ✅ **0 missing**    |
| `check_pg_drc`             | ✅ **Clean**        |
| `check_pg_connectivity`    | ✅ **Connected**    |
| VDD Wires                  | **81,126**          |
| VDD Vias                   | **95,547**          |
| VSS Wires                  | **77,791**          |
| VSS Vias                   | **96,279**          |
| Total Std Cells             | 51,131              |
| Hard Macros                 | 40                  |
| Floating VDD Wires          | 29 (pre-route)      |
| Floating Hard Macros        | 0                   |

---

## 📁 Repository Structure

```
orca-top-pd/
│
├── README.md
│
├── scripts/
│   ├── synthesis/
│   │   └── orca_top.tcl         # DC setup, multi-corner libs, compile_ultra
│   └── pnr/
│       ├── 01_setup.tcl         # ICC2 NDM, TLU+, corners, scenarios, UPF
│       ├── 02_floorplan.tcl     # 600x600 die, 40 macros, keepout, endcap/tap
│       ├── 03_powerplan.tcl     # Ring M7/M8 1.5um, mesh 0.75um, M1 rails
│       ├── 04_placement.tcl     # 16-core, magnet_placement, timing-driven
│       ├── 05_cts.tcl           # 30ps skew, cts_opt, post-CTS reports
│       └── 06_route.tcl         # route_auto x10, route_opt, route_eco
│
├── constraints/
│   ├── orca_top.sdc             # Clock (orca_clk), IO delays, corners
│   └── orca_top.upf             # UPF power intent
│
└── screenshots/
    ├── synthesis/
    │   ├── gl_1.png             # Gate-level netlist (orca_top_gln.v) in Mousepad
    │   ├── ou1.png              # Synthesis outputs folder (sdc, svf, gln.v)
    │   ├── s_1.png              # DC script — lib setup, MW lib, target/link lib
    │   ├── s2.png               # DC script — link_library, ref_library, RTL read
    │   └── s3.png               # DC script — TLU+, compile_ultra, reports, outputs
    ├── floorplan/
    │   ├── fp_1.png             # ICC2 setup script — NDM, corners, scenarios
    │   ├── fp2.png              # Floorplan script — 600x600, macros, keepout margins
    │   ├── fp_3.png             # Setup script — modes/corners/scenarios creation
    │   ├── fp_4.png             # Setup script — endcap & tap cells
    │   ├── fp5.png              # Floorplan — save_block floorplan_done
    │   └── fp_1.png (ICC2)      # ICC2 floorplan view — macros + cell cluster
    ├── powerplan/
    │   ├── pw_1.png             # Powerplan script — ring, M7/M8 mesh
    │   ├── pw2.png              # Powerplan script — M1 rails, PG checks
    │   ├── pg_connectivity.png  # check_pg_connectivity: 51131 cells, 40 macros
    │   └── pg_mismatch.png      # check_pg_missing_vias: 0 missing ✅
    ├── placement/
    │   ├── pl.png               # Placement script — magnet, density, parasitics
    │   ├── pl1.png              # ICC2 place_opt_done view — dense cell placement
    │   └── cell_place.png       # ICC2 CTS block — I_SDRAM_IF cell properties
    ├── cts/
    │   ├── cts1.png             # CTS script — cell selection, skew targets
    │   ├── cts2.png             # CTS script — cts_opt, post-CTS reports
    │   ├── cts_1.png            # ICC2 cts_block — cell-level view + schematic
    │   └── report_clock.png     # Clock report: orca_clk, setup=0.10, hold=0.05
    ├── routing/
    │   ├── rr.png               # Routing script — route_auto x10, opt, eco, fillers
    │   ├── rr1.png              # ICC2 routing_done — full chip routed view
    │   └── rr2.png              # ICC2 routing_done — detail view with fillers
    └── reports/
        ├── report_design.png    # report_design: 1025 cells, 306 FFs, 36 ICGs
        ├── report_timing1.png   # Timing report header (ORCA_TOP, R-2020.09-SP2)
        ├── report_timing_2.png  # Timing path: slack MET = +8.21ns ✅
        └── dlib.png             # orca_demo_d1.dlib folder structure (all stages)
```

---

## 🧠 Implementation Highlights

### Synthesis (DC NXT)
- RTL written in **SystemVerilog** — analyzed with `-format sverilog`
- Full multi-corner library setup: LVT SS/FF at 25°C and 125°C
- `compile_ultra -no_autoungroup` preserves hierarchy across 40 macro boundaries
- Output netlist `orca_top_gln.v` is **5.7 MiB** — reflects SoC complexity
- CLOCKING module uses NBUFFX16_LVT as clock source buffers

### Floorplan (ICC2)
- **600µm × 600µm** die with 50% utilization and 15µm core offset
- **40 hard macros** placed and fixed: SDRAM FIFOs, RISC REG_FILEs, CONTEXT_MEM SRAMs, PCI FIFOs
- Hard keepout margin of **3µm on all 4 sides** of every macro (critical for routing)
- Endcap cells (CAPT2/CAPB2/CAPBIN13/CAPBTAP6) inserted at row boundaries
- Well-tap cells (DCAP_HVT) placed every **30µm** in every row for latch-up prevention

### Power Planning (ICC2)
- **Wider ring** than UART: M7/M8 at **1.5µm width** (vs 1.0µm) to handle larger current
- M7/M8 mesh at **0.75µm width, 11µm pitch** for uniform power distribution
- M1 rails use `via_master: NIL` — no via insertion (rails connect directly to cells)
- Verified: **0 missing vias**, **0 DRC errors**, all 51,131 cells and 40 macros connected

### Placement (ICC2)
- Leveraged **16 parallel CPU cores** (`set_host_options -max_cores 16`) for speed
- `magnet_placement` applied to **all inputs AND outputs** (vs UART only)
- Timing-driven placement with `tlup_min/max` parasitics for both corners
- Cells visible in placement: SDFFNARX1_HVT, MUX2X1_HVT, INVX32_HVT, AO cells

### CTS (ICC2)
- Used `cts_opt` (not `clock_opt`) — specific to this flow version
- `save_lib` called after `save_block` to persist library state
- Post-CTS skew report confirms: `orca_clk`, setup=0.10ns, hold=0.05ns

### Routing (ICC2)
- `route_auto -max_detail_route_iterations 10` — 10 iterations for complex SoC routing
- `route_eco -reroute any_nets` — aggressive ECO to clean up all remaining violations
- Filler `SHFILL1_LVT` (saed32_lvt) visible in routing_done screenshots
- `SRAMLP2RWG64x8` macro confirmed in powerplan_done view

---

## 📸 Key Screenshots

| Stage | What it Shows |
|---|---|
| `gl_1.png` | Gate-level netlist: CLOCKING module, NBUFFX16_LVT, DFFX1_LVT cells |
| `ou1.png` | Synthesis outputs: orca_top.sdc (5.7 MiB), svf, gln.v |
| `dlib.png` | Full dlib showing all 9 stage blocks from import_done to routing_done |
| `fp_1.png` (ICC2) | Floorplan view: macros at periphery, dense cell cluster |
| `pg_connectivity.png` | PG report: 51131 std cells, 40 macros, 81126 VDD wires |
| `pg_mismatch.png` | Missing vias = **0** on both VDD and VSS |
| `pl1.png` | place_opt_done: dense SDFFNARX1_HVT, MUX2X1_HVT placement |
| `cell_place.png` | CTS block: I_SDRAM_IF cell at (502, 926), R180 orientation |
| `report_clock.png` | orca_clk: setup=0.10ns, hold=0.05ns, scenario func:ss0p95v25c |
| `report_timing_2.png` | Critical path: **slack MET = +8.21ns** ✅ |
| `report_design.png` | 1025 lib cells, 306 FFs, 36 latches, 36 ICGs, 69 buffers |
| `rr2.png` | routing_done: full chip with SRAM macros at bottom |

---

## 📚 Skills Demonstrated

- Full RTL-to-GDSII flow for a **complex SoC with 40 hard macros**
- SystemVerilog RTL synthesis using DC NXT
- Multi-corner multi-scenario setup (SS 25°C / SS 125°C)
- Hard macro placement with keepout margin strategy
- Endcap and tap cell insertion for DRC and latch-up compliance
- 3-tier PG mesh design scaled for SoC-level current demand
- 16-core parallel execution for placement and routing
- `cts_opt` flow with 30ps skew target on `orca_clk`
- Aggressive routing with 10-iteration `route_auto` + `route_eco`
- Timing closure: **+8.21ns setup slack MET** at SS 0.95V 25°C

---

## ⚠️ Note on Paths

All scripts reference `/projects/yusuf/orca_top/` and `/projects/SAED_32nm/` — server-side PDK paths from the training environment. Update paths to match your local SAED32 PDK installation. No proprietary library or technology files are included.

---

## 👤 Author

**Mohammad Yusuf**
M.S. Computer Engineering (VLSI) — University of New Mexico
Training: OneVlsi Training Institute | VLSIGuru

🔗 LinkedIn: [linkedin.com/in/mohammad-yusuf-vlsi](https://linkedin.com/in/mohammad-yusuf-vlsi)
🐙 GitHub: [github.com/EXECUTIONER-CELL](https://github.com/EXECUTIONER-CELL)
