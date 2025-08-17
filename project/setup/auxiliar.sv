/*
pinPacked_t

Tipo de dado usado para empacotar as informações do pin, 
ou seja seu valor e se o mesmo se encontra ativo, inativo e seu valor.
*/


typedef struct packed {
	logic 		status;
	logic [3:0] digit1;
	logic [3:0] digit2;
	logic [3:0] digit3;
	logic [3:0] digit4;
} pinPac_t;


/*
setupPac_t

Tipo de dado usado para empacotar as informações 
transmitidas entre o módulo de setup e o modulo operacional.

*/
typedef struct packed {
	logic 		bip_status;
	logic [6:0] bip_time;
	logic [6:0] tranca_aut_time;
	pinPac_t 	master_pin;
	pinPac_t 	pin1;
	pinPac_t 	pin2;
	pinPac_t 	pin3;
	pinPac_t 	pin4;
	
} setupPac_t;



/*
bcdPacked_t

Tipo de dado usado para empacotar os valores dos displays no formato BCD.
*/
typedef struct packed {
	logic [3:0] BCD0;
	logic [3:0] BCD1;
	logic [3:0] BCD2;
	logic [3:0] BCD3;
	logic [3:0] BCD4;
	logic [3:0] BCD5;
} bcdPac_t;

// DIVISOR FREQUÊNCIA
module divfreq(input reset, clock, output logic clk_i);

  int cont;

  always @(posedge clock or posedge reset) begin
    if(reset) begin
      cont  = 0;
      clk_i = 0;
    end
    else
      if( cont <= 25000 )
        cont++;
      else begin
        clk_i = ~clk_i;
        cont = 0;
      end
  end
endmodule

// BCD TO 7
module BCDto7SEGMENT( input logic[3:0] bcd, output logic [6:0] Seg );

always begin
	 case(bcd) 
		   4'b0000 : Seg = 7'b1000000;
			4'b0001 : Seg = 7'b1111001;
			4'b0010 : Seg = 7'b0100100;
			4'b0011 : Seg = 7'b0110000;
			4'b0100 : Seg = 7'b0011001;
			4'b0101 : Seg = 7'b0010010;
			4'b0110 : Seg = 7'b0000010;
			4'b0111 : Seg = 7'b1111000;
			4'b1000 : Seg = 7'b0000000;
			4'b1001 : Seg = 7'b0011000; 
			4'b1011 : Seg = 7'b0111111;
		default: begin
         Seg = 7'b1111111; // Display apagado
		end
	 endcase
 end
endmodule

// MATRIX DECODER
module matrixKeyDecoder (
    input clk, reset,
    input logic [3:0] col_matrix, // Leitura das colunas
    output logic [3:0] lin_matrix, // Ativação das linhas
    output logic [3:0] tecla_value,
    output logic tecla_valid
);
    localparam DEBOUNCE_TIME = 25; 

    typedef enum {IDLE, SET_ROW, WAIT_STABILIZE, READ_COLS, DEBOUNCE, HOLD_KEY} state_t;
    state_t state;
    
    logic [3:0] lin_reg;
    logic [3:0] key_code_reg;
    logic [1:0] row_scan_counter;
    logic [31:0] debounce_counter;

    assign lin_matrix = lin_reg;
    assign tecla_value = key_code_reg;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            row_scan_counter <= 0;
            debounce_counter <= 0;
            tecla_valid <= 0;
            lin_reg <= 4'b1111;
            key_code_reg <= 4'hA;
        end else begin
            tecla_valid <= 0;

            case(state)
                IDLE: begin
                    row_scan_counter <= 0;
                    state <= SET_ROW;
                end

                SET_ROW: begin
                    case(row_scan_counter)
                        2'b00: lin_reg <= 4'b1110; 2'b01: lin_reg <= 4'b1101;
                        2'b10: lin_reg <= 4'b1011; 2'b11: lin_reg <= 4'b0111;
                    endcase
                    state <= WAIT_STABILIZE;
                end

                WAIT_STABILIZE: state <= READ_COLS;

                READ_COLS: begin
                    if (col_matrix != 4'b1111) begin
                        debounce_counter <= 0;
                        state <= DEBOUNCE;
                    end else begin
                        row_scan_counter <= (row_scan_counter == 3) ? 0 : row_scan_counter + 1;
                        state <= SET_ROW;
                    end
                end

                DEBOUNCE: begin
                    if (col_matrix != 4'b1111) begin
                        if (debounce_counter < DEBOUNCE_TIME) begin
                            debounce_counter <= debounce_counter + 1;
                        end else begin
                            case(row_scan_counter)
                                2'b00: case(col_matrix)
                                    4'b1110: key_code_reg <= 4'hD;// 
                                    4'b1101: key_code_reg <= 4'hE;// 
                                    4'b1011: key_code_reg <= 4'h0;//
                                    4'b0111: key_code_reg <= 4'hF;// 
                                    default: key_code_reg <= 4'hA;
                                endcase
                                
                                // Linha 1 (teclas 7, 8, 9, C)
                                2'b01: case(col_matrix)
                                    4'b1110: key_code_reg <= 4'hC;//
                                    4'b1101: key_code_reg <= 4'h9;// 
                                    4'b1011: key_code_reg <= 4'h8;// 
                                    4'b0111: key_code_reg <= 4'h7;//
                                    default: key_code_reg <= 4'hA;
                                endcase
                                
                                // Linha 2 (teclas 4, 5, 6, B)
                                2'b10: case(col_matrix)
                                    4'b1110: key_code_reg <= 4'hB;// 
                                    4'b1101: key_code_reg <= 4'h6;// 
                                    4'b1011: key_code_reg <= 4'h5;// 
                                    4'b0111: key_code_reg <= 4'h4;// 
                                    default: key_code_reg <= 4'hA;
                                endcase
                                
                                // Linha 3 (teclas 1, 2, 3, A)
                                2'b11: case(col_matrix)
                                    4'b1110: key_code_reg <= 4'hA; // 
                                    4'b1101: key_code_reg <= 4'h3; //
                                    4'b1011: key_code_reg <= 4'h2; //
                                    4'b0111: key_code_reg <= 4'h1; //
                                    default: key_code_reg <= 4'hA;
                                endcase
                            endcase
                            
                            tecla_valid <= 1;
                            state <= HOLD_KEY;
                        end
                    end else begin
                        state <= READ_COLS;
                    end
                end
                
                HOLD_KEY: begin
                    if (col_matrix == 4'b1111) begin
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule

// SIX DIGIT
module SixDigit7SegCtrl (
    input logic clk, 
    input logic rst,
    input logic enable,
    input bcdPac_t bcd_packet,
    output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);
    bcdPac_t bcd_reg;

    // Registra o valor do pacote BCD quando habilitado
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            bcd_reg <= '{default: 4'hB}; // Apaga todos os displays
        end else if (enable) begin
            bcd_reg <= bcd_packet;
        end
    end
    
    // Instancia um conversor para cada um dos 6 displays
    BCDto7SEGMENT conv0 (.bcd(bcd_reg.BCD0), .Seg(HEX0));
    BCDto7SEGMENT conv1 (.bcd(bcd_reg.BCD1), .Seg(HEX1));
    BCDto7SEGMENT conv2 (.bcd(bcd_reg.BCD2), .Seg(HEX2));
    BCDto7SEGMENT conv3 (.bcd(bcd_reg.BCD3), .Seg(HEX3));
    BCDto7SEGMENT conv4 (.bcd(bcd_reg.BCD4), .Seg(HEX4));
    BCDto7SEGMENT conv5 (.bcd(bcd_reg.BCD5), .Seg(HEX5));
endmodule