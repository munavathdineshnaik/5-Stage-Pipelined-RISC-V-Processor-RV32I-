// PIPELINE CONTROL UNIT
// Includes:
//   - Forwarding Unit
//   - Load-Use Hazard Detection
module pipeline_control (

    // ID Stage Inputs (Hazard Check)
    input  logic [4:0] rs1_id,
    input  logic [4:0] rs2_id,

    // EX Stage Inputs
    input  logic [4:0] rs1_ex,
    input  logic [4:0] rs2_ex,
    input  logic [4:0] rd_ex,
    input  logic       mem_read_ex,

    // MEM Stage Inputs
    input  logic [4:0] rd_mem,
    input  logic       reg_write_mem,

    // WB Stage Inputs
    input  logic [4:0] rd_wb,
    input  logic       reg_write_wb,

    // Forwarding Outputs (to EX MUXes)
    output logic [1:0] forward_a,
    output logic [1:0] forward_b,

    // Hazard Control Outputs
    output logic       pc_write,
    output logic       if_id_write,
    output logic       id_ex_flush
);

    // DEFAULT VALUES
    always_comb begin

        // Default: normal pipeline flow
        forward_a    = 2'b00;
        forward_b    = 2'b00;

        pc_write     = 1'b1;
        if_id_write  = 1'b1;
        id_ex_flush  = 1'b0;

        // 1) FORWARDING LOGIC
        // Forward A (EX stage operand 1)

        // Priority 1: EX/MEM stage
        if (reg_write_mem && (rd_mem != 5'd0) && (rd_mem == rs1_ex))
            forward_a = 2'b10;

        // Priority 2: MEM/WB stage
        else if (reg_write_wb && (rd_wb != 5'd0) && (rd_wb == rs1_ex))
            forward_a = 2'b01;


        // Forward B (EX stage operand 2)

        if (reg_write_mem && (rd_mem != 5'd0) && (rd_mem == rs2_ex))
            forward_b = 2'b10;

        else if (reg_write_wb && (rd_wb != 5'd0) && (rd_wb == rs2_ex))
            forward_b = 2'b01;


        // 2️) LOAD-USE HAZARD DETECTION
        // If instruction in EX is a load
        // and its destination matches ID stage source,
        // then stall pipeline

        if (mem_read_ex &&
            (rd_ex != 5'd0) &&
            ((rd_ex == rs1_id) || (rd_ex == rs2_id))) begin

            pc_write     = 1'b0;  // Freeze PC
            if_id_write  = 1'b0;  // Freeze IF/ID register
            id_ex_flush  = 1'b1;  // Insert bubble into EX stage

        end

    end

endmodule
