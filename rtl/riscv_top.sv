/*
 *  5-Stage Pipelined RISC-V (RV32I) Processor
 *  Stages: IF, ID, EX, MEM, WB
 *  Features: Forwarding, Hazard Detection (Load-Use), Branch Flushing
 */

module riscv_top (
    input  logic clk,
    input  logic rst
);

    // INTER-STAGE WIRES
    // IF Stage
    logic [31:0] pc_next, pc_out, instr_if, pc_plus4_if;
    
    // ID Stage
    logic [31:0] pc_id, instr_id, rs1_data_id, rs2_data_id, imm_id;
    logic        reg_write_id, mem_read_id, mem_write_id, mem_to_reg_id, alu_src_id, branch_id;
    logic [1:0]  alu_op_id;
    logic [3:0]  alu_ctrl_id;

    // EX Stage
    logic [31:0] pc_ex, rs1_data_ex, rs2_data_ex, imm_ex;
    logic [4:0]  rs1_addr_ex, rs2_addr_ex, rd_addr_ex;
    logic [3:0]  alu_ctrl_ex;
    logic        reg_write_ex, mem_read_ex, mem_write_ex, mem_to_reg_ex, alu_src_ex, branch_ex;
    logic [31:0] alu_in_a, alu_in_b, alu_result_ex, forward_b_mux_out;
    logic [1:0]  forward_a, forward_b;
    logic        zero_ex, flush, stall;
    logic [31:0] branch_target_ex;

    // MEM Stage
    logic [31:0] alu_result_mem, rs2_data_mem, mem_read_data_mem;
    logic [4:0]  rd_addr_mem;
    logic        reg_write_mem, mem_read_mem, mem_write_mem, mem_to_reg_mem;

    // WB Stage
    logic [31:0] alu_result_wb, mem_read_data_wb, write_data_wb;
    logic [4:0]  rd_addr_wb;
    logic        reg_write_wb, mem_to_reg_wb;


    // 1. FETCH (IF) STAGE
    // PC Logic: If branch is taken, jump to target. Else, PC + 4.
    assign pc_plus4_if = pc_out + 32'd4;
    assign pc_next     = (flush) ? branch_target_ex : pc_plus4_if;

    pc pc_unit (
        .clk(clk), .rst(rst), .stall(stall), .pc_next(pc_next), .pc_out(pc_out)
    );

    instruction_memory imem (
        .addr(pc_out), .instr(instr_if)
    );

    if_id_reg if_id (
        .clk(clk), .rst(rst), .stall(stall), .flush(flush),
        .pc_if(pc_out), .instr_if(instr_if),
        .pc_id(pc_id), .instr_id(instr_id)
    );


    // 2. DECODE (ID) STAGE
    // Immediate Generator (logic for I, S, B types)
    always_comb begin
        case (instr_id[6:0])
            7'b0010011, 7'b0000011: imm_id = {{20{instr_id[31]}}, instr_id[31:20]};           // I-type, Load
            7'b0100011:             imm_id = {{20{instr_id[31]}}, instr_id[31:25], instr_id[11:7]}; // S-type
            7'b1100011:             imm_id = {{20{instr_id[31]}}, instr_id[31], instr_id[7], instr_id[30:25], instr_id[11:8], 1'b0}; // B-type
            default:                imm_id = 32'b0;
        endcase
    end

    register_file rf (
        .clk(clk), .reg_write(reg_write_wb), .rs1(instr_id[19:15]), .rs2(instr_id[24:20]), 
        .rd(rd_addr_wb), .write_data(write_data_wb), .read_data1(rs1_data_id), .read_data2(rs2_data_id)
    );

    control_unit cu (
        .opcode(instr_id[6:0]), .reg_write(reg_write_id), .mem_read(mem_read_id), 
        .mem_write(mem_write_id), .mem_to_reg(mem_to_reg_id), .alu_src(alu_src_id), 
        .branch(branch_id), .alu_op(alu_op_id)
    );

    alu_control ac (
        .alu_op(alu_op_id), .funct3(instr_id[14:12]), .funct7_bit(instr_id[30]), .alu_ctrl(alu_ctrl_id)
    );

    // Hazard Detection
    hazard_unit hu (
        .rs1_id(instr_id[19:15]), .rs2_id(instr_id[24:20]), .rd_ex(rd_addr_ex), 
        .mem_read_ex(mem_read_ex), .stall(stall)
    );

    id_ex_reg id_ex (
        .clk(clk), .rst(rst), .flush(flush || stall),
        .pc_id(pc_id), .rs1_data_id(rs1_data_id), .rs2_data_id(rs2_data_id), .imm_id(imm_id),
        .rs1_addr_id(instr_id[19:15]), .rs2_addr_id(instr_id[24:20]), .rd_addr_id(instr_id[11:7]),
        .alu_ctrl_id(alu_ctrl_id), .reg_write_id(reg_write_id), .mem_read_id(mem_read_id),
        .mem_write_id(mem_write_id), .mem_to_reg_id(mem_to_reg_id), .alu_src_id(alu_src_id), .branch_id(branch_id),
        
        .pc_ex(pc_ex), .rs1_data_ex(rs1_data_ex), .rs2_data_ex(rs2_data_ex), .imm_ex(imm_ex),
        .rs1_addr_ex(rs1_addr_ex), .rs2_addr_ex(rs2_addr_ex), .rd_addr_ex(rd_addr_ex),
        .alu_ctrl_ex(alu_ctrl_ex), .reg_write_ex(reg_write_ex), .mem_read_ex(mem_read_ex),
        .mem_write_ex(mem_write_ex), .mem_to_reg_ex(mem_to_reg_ex), .alu_src_ex(alu_src_ex), .branch_ex(branch_ex)
    );


    // 3. EXECUTE (EX) STAGE
    assign branch_target_ex = pc_ex + imm_ex;
    assign flush            = branch_ex && zero_ex; // Flush if Branch is TAKEN

    // Forwarding Muxes (A and B)
    always_comb begin
        case (forward_a)
            2'b10:   alu_in_a = alu_result_mem; // Forward from MEM stage
            2'b01:   alu_in_a = write_data_wb;  // Forward from WB stage
            default: alu_in_a = rs1_data_ex;    // Use RegFile data
        endcase

        case (forward_b)
            2'b10:   forward_b_mux_out = alu_result_mem;
            2'b01:   forward_b_mux_out = write_data_wb;
            default: forward_b_mux_out = rs2_data_ex;
        endcase
    end

    // ALU Src Mux: Choose between RegData (or forwarded) and Immediate
    assign alu_in_b = (alu_src_ex) ? imm_ex : forward_b_mux_out;

    alu alu_unit (
        .a(alu_in_a), .b(alu_in_b), .alu_ctrl(alu_ctrl_ex), .alu_result(alu_result_ex), .zero(zero_ex)
    );

    forwarding_unit fu (
        .rs1_ex(rs1_addr_ex), .rs2_ex(rs2_addr_ex), .rd_mem(rd_addr_mem), .rd_wb(rd_addr_wb),
        .reg_write_mem(reg_write_mem), .reg_write_wb(reg_write_wb), .forward_a(forward_a), .forward_b(forward_b)
    );

    ex_mem_reg ex_mem (
        .clk(clk), .rst(rst),
        .alu_result_ex(alu_result_ex), .rs2_data_ex(forward_b_mux_out), .rd_addr_ex(rd_addr_ex),
        .reg_write_ex(reg_write_ex), .mem_read_ex(mem_read_ex), .mem_write_ex(mem_write_ex), .mem_to_reg_ex(mem_to_reg_ex),
        
        .alu_result_mem(alu_result_mem), .rs2_data_mem(rs2_data_mem), .rd_addr_mem(rd_addr_mem),
        .reg_write_mem(reg_write_mem), .mem_read_mem(mem_read_mem), .mem_write_mem(mem_write_mem), .mem_to_reg_mem(mem_to_reg_mem)
    );


    // 4. MEMORY (MEM) STAGE
    data_memory dmem (
        .clk(clk), .mem_read(mem_read_mem), .mem_write(mem_write_mem),
        .addr(alu_result_mem), .write_data(rs2_data_mem), .read_data(mem_read_data_mem)
    );

    mem_wb_reg mem_wb (
        .clk(clk), .rst(rst),
        .alu_result_mem(alu_result_mem), .mem_read_data_mem(mem_read_data_mem), .rd_addr_mem(rd_addr_mem),
        .reg_write_mem(reg_write_mem), .mem_to_reg_mem(mem_to_reg_mem),
        
        .alu_result_wb(alu_result_wb), .mem_read_data_wb(mem_read_data_wb), .rd_addr_wb(rd_addr_wb),
        .reg_write_wb(reg_write_wb), .mem_to_reg_wb(mem_to_reg_wb)
    );


    // 5. WRITE BACK (WB) STAGE
    assign write_data_wb = (mem_to_reg_wb) ? mem_read_data_wb : alu_result_wb;

endmodule
