module tb_top;

    logic clk;
    logic rst;

    // Instantiate DUT
    riscv_top dut (
        .clk(clk),
        .rst(rst)
    );

    // Clock: 100 MHz
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin

        // Load program
        $readmemh("instr.hex", dut.imem.imem);

        // Reset
        rst = 1;
        repeat (5) @(posedge clk);
        rst = 0;

        $display("Execution Started...");

        // Run for fixed cycles
        repeat (150) @(posedge clk);

        // ===============================
        // Self-check section
        // ===============================

        assert(dut.rf.rf[1] == 10)
            else $fatal("x1 incorrect");

        assert(dut.rf.rf[2] == 20)
            else $fatal("x2 incorrect");

        assert(dut.rf.rf[3] == 30)
            else $fatal("Forwarding failed (x3)");

        assert(dut.rf.rf[4] == 30)
            else $fatal("Memory failed (x4)");

        assert(dut.rf.rf[5] == 40)
            else $fatal("Stall/Forwarding failed (x5)");

        $display("=================================");
        $display("All tests PASSED successfully!");
        $display("=================================");

        $finish;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);
    end

endmodule
