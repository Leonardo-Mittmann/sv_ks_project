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
    S_STORE_1,
    S_STORE_2,
    S_MOVE_1,
    S_MOVE_2,
    S_ADD_1,
    S_ADD_2,
    S_SUB_1,
    S_SUB_2,
    S_AND_1,
    S_AND_2,
    S_OR_1,
    S_OR_2,
    S_BRANCH,
    S_BZERO,
    S_BNEG,
    S_BOV,
    S_BNOV,
    S_BNNEG,
    S_BNZERO,
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
    
    always_comb begin
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
                next_state = REGISTER_INSTRUCTION;
            end
            REGISTER_INSTRUCTION: begin
                next_state = DECODE;
                ir_enable = 1'b1;
                pc_enable = 1'b1;
            end
            DECODE: begin
            //DECODE
                next_state = FETCH_INSTRUCTION;
                case(decoded_instruction)
                    I_HALT: begin
                        next_state = S_HALT;
                    end
                    I_LOAD: begin
                        next_state = S_LOAD_1;
                    end
                    I_STORE: begin
                        next_state = S_STORE_1;
                    end
                    I_MOVE: begin
                        next_state = S_MOVE_1;
                    end
                    I_ADD: begin
                        next_state = S_ADD_1;
                    end
                    I_SUB: begin
                        next_state = S_SUB_1;
                    end
                    I_AND: begin
                        next_state = S_AND_1;
                    end
                    I_OR: begin
                        next_state = S_OR_1;
                    end
                    I_BRANCH: begin
                        next_state = S_BRANCH;
                    end
                    I_BZERO: begin
                        next_state = S_BZERO;
                    end
                    I_BNEG: begin
                        next_state = S_BNEG;
                    end
                    I_BOV: begin
                        next_state = S_BOV;
                    end
                    I_BNOV: begin
                        next_state = S_BNOV;
                    end
                    I_BNNEG: begin
                        next_state = S_BNNEG;
                    end
                    I_BNZERO: begin
                        next_state = S_BNZERO;
                    end               
                endcase
             end
            //--EXECUTAR--
            //LOAD                    
            S_LOAD_1: begin
                next_state = S_LOAD_2;
                addr_sel = 1'b1;
            end
            S_LOAD_2: begin
                next_state = FETCH_INSTRUCTION;
                addr_sel = 1'b1;
                write_reg_enable = 1'b1;
                c_sel = 1'b1;
            end
            //STORE
            S_STORE_1: begin
                next_state = S_STORE_2;
                addr_sel = 1'b1;
            end
            S_STORE_2: begin
                next_state = FETCH_INSTRUCTION;
                addr_sel = 1'b1;
                ram_write_enable = 1'b1;
            end
            //MOVE
            S_MOVE_1: begin
                next_state = S_MOVE_2;
                operation = 2'b10;   //ULA faz AND para nao mudar o valor
            end
            S_MOVE_2: begin
                next_state = FETCH_INSTRUCTION;
                operation = 2'b10;
                write_reg_enable = 1'b1;
            end
            //ADD
            S_ADD_1: begin
                next_state = S_ADD_2;
                operation = 2'b00;
                flags_reg_enable = 1'b1;
            end
            S_ADD_2: begin
                next_state = FETCH_INSTRUCTION;
                operation = 2'b00;
                flags_reg_enable = 1'b1;
                write_reg_enable = 1'b1;
            end
            //SUB
            S_SUB_1: begin
                next_state = S_SUB_2;
                operation = 2'b01;
                flags_reg_enable = 1'b1;
            end
            S_SUB_2: begin
                next_state = FETCH_INSTRUCTION;
                operation = 2'b01;
                flags_reg_enable = 1'b1;
                write_reg_enable = 1'b1;
            end
            //AND
            S_AND_1: begin
                next_state = S_AND_2;
                operation = 2'b10;
                flags_reg_enable = 1'b1;
            end
            S_AND_2: begin
                next_state = FETCH_INSTRUCTION;
                operation = 2'b10;
                flags_reg_enable = 1'b1;
                write_reg_enable = 1'b1;
            end
            //OR
            S_OR_1: begin
                next_state = S_OR_2;
                operation = 2'b11;
                flags_reg_enable = 1'b1;
            end
            S_OR_2: begin
                next_state = FETCH_INSTRUCTION;
                operation = 2'b11;
                flags_reg_enable = 1'b1;
                write_reg_enable = 1'b1;
            end
            //BRANCH
            S_BRANCH: begin
                next_state = FETCH_INSTRUCTION;
                pc_enable = 1'b1;
                branch = 1'b1;
            end
            //BZERO
            S_BZERO: begin
                next_state = FETCH_INSTRUCTION;
                pc_enable = 1'b1;
                branch = zero_op;
            end
            //BNEG
            S_BNEG: begin
                next_state = FETCH_INSTRUCTION;
                pc_enable = 1'b1;
                branch = neg_op;
            end
            //BOV
            S_BOV: begin
                next_state = FETCH_INSTRUCTION;
                pc_enable = 1'b1;
                branch = unsigned_overflow;
            end
            //BNOV
            S_BNOV: begin
                next_state = FETCH_INSTRUCTION;
                pc_enable = 1'b1;
                branch = ~unsigned_overflow;
            end
            //BNNEG
            S_BNNEG: begin
                next_state = FETCH_INSTRUCTION;
                pc_enable = 1'b1;
                branch = ~neg_op;
            end
            //BNZERO
            S_BNZERO: begin
                next_state = FETCH_INSTRUCTION;
                pc_enable = 1'b1;
                branch = ~zero_op;
            end
            //HALT
            S_HALT: begin
                next_state = S_HALT;
                halt = 1'b1;
            end
        endcase
    end

endmodule : control_unit
