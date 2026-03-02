// PIPELINE REGISTERS
// 5-Stage Pipelined RISC-V Processor
// IF → ID → EX → MEM → WB

// 1) IF/ID PIPELINE REGISTER
module if_id_reg (
    input  logic        clk,
    input  logic        rst,
    input  logic        stall,
    input  logic        flush,

    input  logic [31:0] pc_if,
    input  logic [31:0] instr_if,

    output logic [31:0] pc_id,
    output logic [31:0] instr_id
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            pc_id    <= 32'd0;
            instr_id <= 32'd0;
        end
        else if (!stall) begin
            pc_id    <= pc_if;
            instr_id <= instr_if;
        end
    end

endmodule

// 2) ID/EX PIPELINE REGISTER
module id_ex_reg (
    input  logic        clk,
    input  logic        rst,
    input  logic        flush,

    // Data Signals
    input  logic [31:0] pc_id,
    input  logic [31:0] rs1_data_id,
    input  logic [31:0] rs2_data_id,
    input  logic [31:0] imm_id,
    input  logic [4:0]  rs1_addr_id,
    input  logic [4:0]  rs2_addr_id,
    input  logic [4:0]  rd_addr_id,

    // Control Signals
    input  logic [3:0]  alu_ctrl_id,
    input  logic        reg_write_id,
    input  logic        mem_read_id,
    input  logic        mem_write_id,
    input  logic        mem_to_reg_id,
    input  logic        alu_src_id,
    input  logic        branch_id,

    // Outputs
    output logic [31:0] pc_ex,
    output logic [31:0] rs1_data_ex,
    output logic [31:0] rs2_data_ex,
    output logic [31:0] imm_ex,
    output logic [4:0]  rs1_addr_ex,
    output logic [4:0]  rs2_addr_ex,
    output logic [4:0]  rd_addr_ex,

    output logic [3:0]  alu_ctrl_ex,
    output logic        reg_write_ex,
    output logic        mem_read_ex,
    output logic        mem_write_ex,
    output logic        mem_to_reg_ex,
    output logic        alu_src_ex,
    output logic        branch_ex
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst || flush) begin
            pc_ex         <= 32'd0;
            rs1_data_ex   <= 32'd0;
            rs2_data_ex   <= 32'd0;
            imm_ex        <= 32'd0;
            rs1_addr_ex   <= 5'd0;
            rs2_addr_ex   <= 5'd0;
            rd_addr_ex    <= 5'd0;

            alu_ctrl_ex   <= 4'd0;
            reg_write_ex  <= 1'b0;
            mem_read_ex   <= 1'b0;
            mem_write_ex  <= 1'b0;
            mem_to_reg_ex <= 1'b0;
            alu_src_ex    <= 1'b0;
            branch_ex     <= 1'b0;
        end
        else begin
            pc_ex         <= pc_id;
            rs1_data_ex   <= rs1_data_id;
            rs2_data_ex   <= rs2_data_id;
            imm_ex        <= imm_id;
            rs1_addr_ex   <= rs1_addr_id;
            rs2_addr_ex   <= rs2_addr_id;
            rd_addr_ex    <= rd_addr_id;

            alu_ctrl_ex   <= alu_ctrl_id;
            reg_write_ex  <= reg_write_id;
            mem_read_ex   <= mem_read_id;
            mem_write_ex  <= mem_write_id;
            mem_to_reg_ex <= mem_to_reg_id;
            alu_src_ex    <= alu_src_id;
            branch_ex     <= branch_id;
        end
    end

endmodule

// 3) EX/MEM PIPELINE REGISTER
module ex_mem_reg (
    input  logic        clk,
    input  logic        rst,

    // Data
    input  logic [31:0] alu_result_ex,
    input  logic [31:0] rs2_data_ex,
    input  logic [31:0] branch_target_ex,
    input  logic        zero_ex,
    input  logic [4:0]  rd_addr_ex,

    // Control
    input  logic        reg_write_ex,
    input  logic        mem_read_ex,
    input  logic        mem_write_ex,
    input  logic        mem_to_reg_ex,
    input  logic        branch_ex,

    // Outputs
    output logic [31:0] alu_result_mem,
    output logic [31:0] rs2_data_mem,
    output logic [31:0] branch_target_mem,
    output logic        zero_mem,
    output logic [4:0]  rd_addr_mem,

    output logic        reg_write_mem,
    output logic        mem_read_mem,
    output logic        mem_write_mem,
    output logic        mem_to_reg_mem,
    output logic        branch_mem
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            alu_result_mem    <= 32'd0;
            rs2_data_mem      <= 32'd0;
            branch_target_mem <= 32'd0;
            zero_mem          <= 1'b0;
            rd_addr_mem       <= 5'd0;

            reg_write_mem     <= 1'b0;
            mem_read_mem      <= 1'b0;
            mem_write_mem     <= 1'b0;
            mem_to_reg_mem    <= 1'b0;
            branch_mem        <= 1'b0;
        end
        else begin
            alu_result_mem    <= alu_result_ex;
            rs2_data_mem      <= rs2_data_ex;
            branch_target_mem <= branch_target_ex;
            zero_mem          <= zero_ex;
            rd_addr_mem       <= rd_addr_ex;

            reg_write_mem     <= reg_write_ex;
            mem_read_mem      <= mem_read_ex;
            mem_write_mem     <= mem_write_ex;
            mem_to_reg_mem    <= mem_to_reg_ex;
            branch_mem        <= branch_ex;
        end
    end

endmodule

// 4) MEM/WB PIPELINE REGISTER
module mem_wb_reg (
    input  logic        clk,
    input  logic        rst,

    // Data
    input  logic [31:0] alu_result_mem,
    input  logic [31:0] mem_read_data_mem,
    input  logic [4:0]  rd_addr_mem,

    // Control
    input  logic        reg_write_mem,
    input  logic        mem_to_reg_mem,

    // Outputs
    output logic [31:0] alu_result_wb,
    output logic [31:0] mem_read_data_wb,
    output logic [4:0]  rd_addr_wb,

    output logic        reg_write_wb,
    output logic        mem_to_reg_wb
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            alu_result_wb    <= 32'd0;
            mem_read_data_wb <= 32'd0;
            rd_addr_wb       <= 5'd0;
            reg_write_wb     <= 1'b0;
            mem_to_reg_wb    <= 1'b0;
        end
        else begin
            alu_result_wb    <= alu_result_mem;
            mem_read_data_wb <= mem_read_data_mem;
            rd_addr_wb       <= rd_addr_mem;

            reg_write_wb     <= reg_write_mem;
            mem_to_reg_wb    <= mem_to_reg_mem;
        end
    end

endmodule
