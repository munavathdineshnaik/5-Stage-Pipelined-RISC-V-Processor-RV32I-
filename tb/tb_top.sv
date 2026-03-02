module tb_top;

    logic clk;
    logic rst;

    // Instantiate the Top Module
    riscv_top dut (
        .clk(clk),
        .rst(rst)
    );

    // 100MHz Clock Generation
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // 1. Load the machine code into Instruction Memory
        $readmemh("instr.hex", dut.imem.imem);

        // 2. System Reset
        $display("Time: %0t | System Resetting...", $time);
        rst = 1;
        #25;
        rst = 0;
        $display("Time: %0t | Reset Released. Execution Starting...", $time);

        // 3. Run simulation for enough cycles to finish the program
        #500;

        // 4. Print Register File contents to verify the program results
        $display("\n==============================================");
        $display("FINAL REGISTER VALUES (DECIMAL)");
        $display("==============================================");
        $display("x1 (addi 10): %d", dut.rf.rf[1]);
        $display("x2 (addi 20): %d", dut.rf.rf[2]);
        $display("x3 (add 1+2): %d", dut.rf.rf[3]); // Should be 30 (Forwarding check)
        $display("x4 (lw 0[x0]): %d", dut.rf.rf[4]); // Should be 30 (Memory check)
        $display("x5 (add 4+1): %d", dut.rf.rf[5]); // Should be 40 (Stall + Forwarding check)
        $display("x6 (addi 100): %d", dut.rf.rf[6]); // Branch test result
        $display("==============================================\n");
        
        $finish;
    end

    // Create waveform file for EPWave
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);
    end

endmodule
