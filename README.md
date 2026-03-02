# 5-Stage Pipelined RISC-V Processor (RV32I)

## Overview

This project implements a 32-bit RV32I RISC-V processor using a classic 5-stage pipeline:

IF → ID → EX → MEM → WB

The goal was to design and verify a pipelined processor with proper hazard handling and clean RTL structure in SystemVerilog.

---

## Features

- 5-stage pipelined architecture
- Forwarding for RAW data hazards
- Load-use hazard detection with 1-cycle stall
- Branch resolution in EX stage with pipeline flush
- Modular RTL design (datapath + control separation)
- Self-checking testbench

---

## Architecture

![Architecture](docs/architecture.png)

The processor follows a classic 5-stage pipeline:

IF → ID → EX → MEM → WB

Pipeline registers:
- IF/ID  
- ID/EX  
- EX/MEM  
- MEM/WB  

---

## Hazard & Forwarding Logic

![Hazard and Forwarding](docs/hazard_forwarding.png)

The processor handles hazards using:

### Data Forwarding
- EX/MEM → EX
- MEM/WB → EX
- Most recent result has priority

### Load-Use Hazard
- If a load instruction is followed by a dependent instruction:
  - PC and IF/ID are stalled
  - Bubble inserted into ID/EX
  - Execution resumes after 1 cycle

### Branch Handling
- Branch resolved in EX stage
- If branch is taken:
  - Pipeline is flushed
  - PC updated to branch target
- 1-cycle branch penalty

---

## Pipeline Timing

![Pipeline Timing](docs/pipeline_timing.png)

Shows:
- 1-cycle stall for load-use
- Correct forwarding behavior
- Proper pipeline flow
---

## Test Program

Used to verify:

- Forwarding logic
- Load-use stall
- Memory read/write
- Branch (taken and not taken)

Example:

```assembly
addi x1, x0, 10
addi x2, x0, 20
add  x3, x1, x2
sw   x3, 0(x0)
lw   x4, 0(x0)
add  x5, x4, x1
beq  x5, x0, end
addi x6, x0, 100
end:
addi x7, x0, 200
```

---

## Project Structure

```
rtl/
    core_modules.sv
    pipeline_control.sv
    pipeline_regs.sv
    riscv_top.sv

tb/
    tb_top.sv

sim/
    instr.hex
    test_program.s

docs/
    architecture.png
    hazard_forwarding.png
    pipeline_timing.png
```


## What I Learned

- Designing a pipelined datapath from scratch
- Implementing forwarding and hazard detection logic
- Understanding cycle-level behavior of a processor
- Clean RTL structuring for modular hardware design
