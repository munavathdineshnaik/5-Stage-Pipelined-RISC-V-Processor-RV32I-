// 1. FORWARDING UNIT
module forwarding_unit (
    input  logic [4:0] rs1_ex,
    input  logic [4:0] rs2_ex,
    input  logic [4:0] rd_mem,
    input  logic [4:0] rd_wb,
    input  logic       reg_write_mem,
    input  logic       reg_write_wb,
    output logic [1:0] forward_a,
    output logic [1:0] forward_b
);
    always_comb begin
        forward_a = 2'b00;
        forward_b = 2'b00;

        if (reg_write_mem && (rd_mem != 5'b0) && (rd_mem == rs1_ex))
            forward_a = 2'b10; 
        else if (reg_write_wb && (rd_wb != 5'b0) && (rd_wb == rs1_ex))
            forward_a = 2'b01; 

        if (reg_write_mem && (rd_mem != 5'b0) && (rd_mem == rs2_ex))
            forward_b = 2'b10; 
        else if (reg_write_wb && (rd_wb != 5'b0) && (rd_wb == rs2_ex))
            forward_b = 2'b01; 
    end
endmodule

// 2. HAZARD DETECTION UNIT
module hazard_unit (
    input  logic [4:0] rs1_id,
    input  logic [4:0] rs2_id,
    input  logic [4:0] rd_ex,
    input  logic       mem_read_ex, 
    output logic       stall
);
    always_comb begin
        // Optimized: Don't stall if destination is x0
        if (mem_read_ex && (rd_ex != 5'b0) && ((rd_ex == rs1_id) || (rd_ex == rs2_id)))
            stall = 1'b1;
        else
            stall = 1'b0;
    end
endmodule
