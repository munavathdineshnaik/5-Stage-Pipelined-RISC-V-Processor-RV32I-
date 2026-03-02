# Purpose: Verify Pipeline Hazard Logic

addi x1, x0, 10      # Write 10 to x1
addi x2, x0, 20      # Write 20 to x2
add  x3, x1, x2      # RAW Hazard: x1, x2 forwarded from EX/MEM to ALU
sw   x3, 0(x0)       # Store result (30) to memory
lw   x4, 0(x0)       # Load result (30) back to x4
add  x5, x4, x1      # Load-Use Hazard: Must stall 1 cycle, then forward x4
beq  x5, x0, end     # Branch logic check (40 != 0, so no branch)
addi x6, x0, 100     # Should execute
end:
addi x7, x0, 200     # Final marker
