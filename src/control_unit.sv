//control unit
module control_unit
import k_and_s_pkg::*;
(
    input  logic                    rst_n,
    input  logic                    clk,
    output logic                    branch,
    output logic                    pc_enable,
    output logic                    ir_enable,
    output logic                    write_reg_enable,
    output logic                    addr_sel,
    output logic                    c_sel,
    output logic              [1:0] operation,
    output logic                    flags_reg_enable,
    input  decoded_instruction_type decoded_instruction,
    input  logic                    zero_op,
    input  logic                    neg_op,
    input  logic                    unsigned_overflow,
    input  logic                    signed_overflow,
    output logic                    ram_write_enable,
    output logic                    halt
);

typedef enum{
    FETCH_INSTRUCTION,
    REGISTER_INSTRUCTION,
    DECODE,
    S_LOAD_1,
    S_LOAD_2,
    S_HALT
}state_t;

state_t state;
state_t next_state;


always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= FETCH_INSTRUCTION;
    end
    else begin
         state <= next_state;
    end
end
    
    always_comb begin : calc_next_state
        branch = 1'b0;
        pc_enable = 1'b0;
        ir_enable = 1'b0;
        write_reg_enable = 1'b0;
        addr_sel = 1'b0;
        c_sel = 1'b0;
        operation = 2'b00;
        flags_reg_enable = 1'b0;
        ram_write_enable = 1'b0;
        halt = 1'b0;
        case (state)
            FETCH_INSTRUCTION : begin
                next_state = DECODE;
                ir_enable = 1'b1;
                pc_enable = 1'b1;
            end
            DECODE: begin
                next_state = FETCH_INSTRUCTION;
                case(decoded_instruction)
                    I_HALT: begin
                        next_state = S_HALT;
                    end
                    I_LOAD: begin
                        next_state = S_LOAD_1;
                        addr_sel = 1'b1;
                    end
            end
                endcase
                
             S_LOAD_1: begin
                next_state = S_LOAD_2;
                addr_sel = 1'b1;
                c_sel = 1'b1;
            end 
        endcase
    end : calc_next_state //always comb

endmodule : control_unit
