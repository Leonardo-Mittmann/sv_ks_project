module data_path
import k_and_s_pkg::*;
(
    input  logic                    rst_n,
    input  logic                    clk,
    input  logic                    branch,
    input  logic                    pc_enable,
    input  logic                    ir_enable,
    input  logic                    addr_sel,
    input  logic                    c_sel,
    input  logic              [1:0] operation,
    input  logic                    write_reg_enable,
    input  logic                    flags_reg_enable,
    output decoded_instruction_type decoded_instruction,
    output logic                    zero_op,
    output logic                    neg_op,
    output logic                    unsigned_overflow,
    output logic                    signed_overflow,
    output logic              [4:0] ram_addr,
    output logic             [15:0] data_out,
    input  logic             [15:0] data_in

);
logic [15:0] bus_a;
logic [15:0] bus_b;
logic [15:0] bus_c;
logic [15:0] complement_a;
logic [15:0] instruction;
logic [15:0] alu_out;

logic [4:0]  mem_addr;
logic [4:0]  program_counter;

logic [1:0]  a_addr;
logic [1:0]  b_addr;
logic [1:0]  c_addr;

logic zero_f;
logic neg_f;
logic overflow_f;
logic signed_overflow_f;
logic alu_carry_in;
logic [15:0] registr[4];

//Registrador de instrucao
always_ff @(posedge clk) begin
    if (ir_enable) begin
        instruction <= data_in;
    end
end

//Program counter
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        program_counter <= 'd0;
    end
    else if (pc_enable) begin
        if (branch) begin
            program_counter <= mem_addr;
         end else begin
            program_counter <= program_counter + 1;
         end
    end
end

//ULA
assign complement_a = -bus_a;
always_comb begin
    case (operation)
        //ADD
        2'b00: begin
            {alu_carry_in, alu_out[14:0]} = bus_a[14:0] + bus_b[14:0];
            {overflow_f, alu_out[15]} = bus_a[15] + bus_b[15] + alu_carry_in;
            signed_overflow_f = overflow_f ^ alu_carry_in;
        end
        //SUB
        2'b01: begin
            {alu_carry_in, alu_out[14:0]} = complement_a[14:0] + bus_b[14:0];
            {overflow_f, alu_out[15]} = complement_a[15] + bus_b[15] + alu_carry_in;
            signed_overflow_f = overflow_f ^ alu_carry_in;
        end
        //AND
        2'b10: begin 
            alu_out = bus_a & bus_b;
            overflow_f = 1'b0;
            signed_overflow_f = 1'b0;
        end
        //OR
        2'b11: begin
            alu_out = bus_a | bus_b;
            overflow_f = 1'b0;
            signed_overflow_f = 1'b0;
        end
        default: begin
            $display("ERRO: Operacao da ULA invalida: op %d",operation);
            alu_out = 'd4321;
            overflow_f = 1'b0;
            signed_overflow_f = 1'b0;
        end
     endcase
end

//Calculo de flags
assign zero_f = ~|(alu_out);
assign neg_f = alu_out[15];

//MUX
assign bus_c = (c_sel?data_in:alu_out);
assign ram_addr = (addr_sel?mem_addr:program_counter);


//Decodificar instrucao
always_comb begin
    a_addr = 'd0;
    b_addr = 'd0;
    c_addr = 'd0;
    mem_addr = 'd0;
    case (instruction [15:8])
    //--Movimentacao de dados--
    //LOAD
    8'b1000_0001: begin
        c_addr = instruction[6:5];
        mem_addr = instruction[4:0];
        decoded_instruction = I_LOAD; 
    end
    //STORE
    8'b1000_0010: begin
        a_addr = instruction[6:5];
        mem_addr = instruction[4:0];
        decoded_instruction = I_STORE;
    end
    //MOVE
    8'b1001_0001: begin
        a_addr = instruction[1:0];
        b_addr = instruction[1:0];
        c_addr = instruction[3:2];
        mem_addr = instruction[4:0];
        decoded_instruction = I_MOVE; 
    end
    
    //--Aritimetica--
    //ADD
    8'b1010_0001: begin
        decoded_instruction = I_ADD;
        a_addr = instruction[1:0];
        b_addr = instruction[3:2];
        c_addr = instruction[5:4];
    end
    //SUB
    8'b1010_0010: begin
    decoded_instruction = I_SUB;
        a_addr = instruction[1:0];
        b_addr = instruction[3:2];
        c_addr = instruction[5:4];
    end
    
    //--Logica--
    //AND
    8'b1010_0011: begin
        decoded_instruction = I_AND;
        a_addr = instruction[1:0];
        b_addr = instruction[3:2];
        c_addr = instruction[5:4];
    end
    //OR
    8'b1010_0100: begin
        decoded_instruction = I_OR;
        a_addr = instruction[1:0];
        b_addr = instruction[3:2];
        c_addr = instruction[5:4];
    end
    //--Desvio
    //BRANCH
    8'b0000_0001: begin
        decoded_instruction = I_BRANCH;
        mem_addr = instruction[4:0];
    end
    //BZERO
    8'b0000_0010: begin 
        decoded_instruction = I_BZERO;
        mem_addr = instruction[4:0];
    end
    //BNEG
    8'b0000_0011: begin
        decoded_instruction = I_BNEG;
        mem_addr = instruction[4:0];
    end
    //BOV
    8'b0000_0101: begin
        decoded_instruction = I_BOV;
        mem_addr = instruction[4:0];
    end
    //BNOV
    8'b0000_0110: begin
        decoded_instruction = I_BNOV;
        mem_addr = instruction[4:0];
    end
    //BNNEG
    8'b0000_1010: begin
        decoded_instruction = I_BNNEG;
        mem_addr = instruction[4:0];
    end
    //BNZERO
    8'b0000_1011: begin
        decoded_instruction = I_BNZERO;
        mem_addr = instruction[4:0];
    end
    
    //Fim de programa
    //HALT
    8'b1111_1111: begin
        decoded_instruction = I_HALT;
    end
    //NOP
    default : begin
        decoded_instruction = I_NOP;
    end
  endcase
end


//Registrador de flags
always_ff @(posedge clk) begin
    if (flags_reg_enable) begin
        zero_op <= zero_f;
        neg_op <= neg_f;
        unsigned_overflow <= overflow_f;
        signed_overflow <= signed_overflow_f;
    end
end

//Registradores de uso geral
assign bus_a = registr[a_addr];
assign bus_b = registr[b_addr];
always_ff @(posedge clk) begin
    if (write_reg_enable) begin
        registr[c_addr] <= bus_c;
    end
end 
//Escrever na memoria
assign data_out = bus_a;
endmodule : data_path
