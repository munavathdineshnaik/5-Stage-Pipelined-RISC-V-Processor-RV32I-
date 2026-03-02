// RV32I Core Modules
// 5-Stage Pipelined RISC-V Processor
// Includes:
//   - Program Counter
//   - Register File
//   - ALU
//   - Main Control Unit
//   - ALU Control

// 1. PROGRAM COUNTER
module pc (
    input  logic        clk,
    input  logic        rst,
    input  logic        stall,
    input  logic [31:0] pc_next,
    output logic [31:0] pc_out
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            pc_out <= 32'h0000_0000;
        else if (!stall)
            pc_out <= pc_next;
    end

endmodule

// 2. REGISTER FILE (32 x 32)
module register_file (
    input  logic        clk,
    input  logic        reg_write,
    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    input  logic [4:0]  rd,
    input  logic [31:0] write_data,
    output logic [31:0] read_data1,
    output logic [31:0] read_data2
);

    logic [31:0] rf [31:0];

    initial begin
        integer i;
        for (i = 0; i < 32; i++)
            rf[i] = 32'b0;
    end

    // Read with x0 protection + internal forwarding
    assign read_data1 =
        (rs1 == 5'd0) ? 32'b0 :
        (reg_write && (rd == rs1) && (rd != 0)) ? write_data :
        rf[rs1];

    assign read_data2 =
        (rs2 == 5'd0) ? 32'b0 :
        (reg_write && (rd == rs2) && (rd != 0)) ? write_data :
        rf[rs2];

    // Write operation
    always_ff @(posedge clk) begin
        if (reg_write && (rd != 5'd0))
            rf[rd] <= write_data;
    end

endmodule

// 3. ALU
module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [3:0]  alu_ctrl,
    output logic [31:0] alu_result,
    output logic        zero
);

    always_comb begin
        case (alu_ctrl)

            4'b0000: alu_result = a + b;  // ADD
            4'b0001: alu_result = a - b;  // SUB
            4'b0010: alu_result = a & b;  // AND
            4'b0011: alu_result = a | b;  // OR
            4'b0100: alu_result = a ^ b;  // XOR
            4'b0101: alu_result = a << b[4:0];                       // SLL
            4'b0110: alu_result = a >> b[4:0];                       // SRL
            4'b0111: alu_result = $signed(a) >>> b[4:0];             // SRA
            4'b1000: alu_result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0; // SLT
            4'b1001: alu_result = (a < b) ? 32'd1 : 32'd0;           // SLTU

            default: alu_result = 32'd0;

        endcase
    end

    assign zero = (alu_result == 32'd0);

endmodule

// 4. MAIN CONTROL UNIT
module control_unit (
    input  logic [6:0] opcode,

    output logic       reg_write,
    output logic       mem_read,
    output logic       mem_write,
    output logic       mem_to_reg,
    output logic       alu_src,
    output logic       branch,
    output logic [1:0] alu_op
);

    always_comb begin

        // Default values
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        alu_src    = 1'b0;
        branch     = 1'b0;
        alu_op     = 2'b00;

        case (opcode)

            7'b0110011: begin // R-type
                reg_write = 1'b1;
                alu_op    = 2'b10;
            end

            7'b0010011: begin // I-type arithmetic
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = 2'b11;
            end

            7'b0000011: begin // Load (LW)
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                alu_op     = 2'b00;
            end

            7'b0100011: begin // Store (SW)
                alu_src   = 1'b1;
                mem_write = 1'b1;
                alu_op    = 2'b00;
            end

            7'b1100011: begin // Branch (BEQ)
                branch = 1'b1;
                alu_op = 2'b01;
            end

            default: ;

        endcase
    end

endmodule

// 5. ALU CONTROL
module alu_control (
    input  logic [1:0] alu_op,
    input  logic [2:0] funct3,
    input  logic       funct7_bit,
    output logic [3:0] alu_ctrl
);

    always_comb begin

        case (alu_op)

            2'b00: alu_ctrl = 4'b0000; // ADD (Load/Store)

            2'b01: alu_ctrl = 4'b0001; // SUB (Branch compare)

            2'b10: begin // R-type
                case (funct3)
                    3'b000: alu_ctrl = (funct7_bit) ? 4'b0001 : 4'b0000; // SUB/ADD
                    3'b111: alu_ctrl = 4'b0010; // AND
                    3'b110: alu_ctrl = 4'b0011; // OR
                    3'b100: alu_ctrl = 4'b0100; // XOR
                    3'b001: alu_ctrl = 4'b0101; // SLL
                    3'b101: alu_ctrl = (funct7_bit) ? 4'b0111 : 4'b0110; // SRA/SRL
                    3'b010: alu_ctrl = 4'b1000; // SLT
                    3'b011: alu_ctrl = 4'b1001; // SLTU
                    default: alu_ctrl = 4'b0000;
                endcase
            end

            2'b11: begin // I-type arithmetic
                case (funct3)
                    3'b000: alu_ctrl = 4'b0000; // ADDI
                    3'b111: alu_ctrl = 4'b0010; // ANDI
                    3'b110: alu_ctrl = 4'b0011; // ORI
                    3'b100: alu_ctrl = 4'b0100; // XORI
                    3'b010: alu_ctrl = 4'b1000; // SLTI
                    3'b011: alu_ctrl = 4'b1001; // SLTIU
                    3'b001: alu_ctrl = 4'b0101; // SLLI
                    3'b101: alu_ctrl = (funct7_bit) ? 4'b0111 : 4'b0110; // SRAI/SRLI
                    default: alu_ctrl = 4'b0000;
                endcase
            end

            default: alu_ctrl = 4'b0000;

        endcase
    end

endmodule
