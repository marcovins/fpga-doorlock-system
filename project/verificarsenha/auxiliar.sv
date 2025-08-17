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
} bcdPac_t

// MONTAR PIN
module montar_pin (
    input  logic      clk,
    input  logic      rst,
    input  logic      key_valid,
    input  logic [3:0] key_code,
    output pinPac_t   pin_out
);
    typedef enum logic [2:0] {
        INICIAL,
        DIGITO_LIDO,
        STATUS_TRUE,
        HOLD_STATUS,
        TEMP
    } estado_t;
    estado_t ESTADO_ATUAL;
	 logic key_valid_prev;
	 logic has_blank_digit;
	 
	 assign has_blank_digit = (pin_out.digit1 == 4'hE) || (pin_out.digit2 == 4'hE) ||
                                          (pin_out.digit3 == 4'hE) || (pin_out.digit4 == 4'hE);


    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            ESTADO_ATUAL <= INICIAL;
            key_valid_prev <= 0;
            pin_out <= '{status: 0, digit1: 4'hE, digit2: 4'hE, digit3: 4'hE, digit4: 4'hE};
        end else begin
				key_valid_prev <= key_valid;
            case (ESTADO_ATUAL)
                INICIAL: begin
                    pin_out.status <= 0;
                    if (key_valid && !key_valid_prev && key_code <= 4'h9) begin
                        ESTADO_ATUAL <= DIGITO_LIDO;
                        pin_out.digit1 <= pin_out.digit2;
                        pin_out.digit2 <= pin_out.digit3;
                        pin_out.digit3 <= pin_out.digit4;
                        pin_out.digit4 <= key_code;
                    end
                end
							
                DIGITO_LIDO: begin
                    if (key_valid && !key_valid_prev && key_code == 4'hF && !has_blank_digit) begin
                        ESTADO_ATUAL <= STATUS_TRUE;
                    
                    end else if (key_valid && !key_valid_prev && key_code <= 4'h9) begin
                        pin_out.digit1 <= pin_out.digit2;
                        pin_out.digit2 <= pin_out.digit3;
                        pin_out.digit3 <= pin_out.digit4;
                        pin_out.digit4 <= key_code;
                    end
                end

                STATUS_TRUE: begin
                    pin_out.status <= 1;
                    ESTADO_ATUAL <= HOLD_STATUS;
                end

                HOLD_STATUS: begin
                    pin_out.status <= 1;
                    ESTADO_ATUAL <= TEMP;
                end

                TEMP: begin
                    if (pin_out.status) begin
                        pin_out.status <= 0;
                    end else begin
                      pin_out <= '{status: 0, digit1: 4'hE, digit2: 4'hE, digit3: 4'hE, digit4: 4'hE};
                      ESTADO_ATUAL <= INICIAL;
                    end
                end
            endcase
        end
    end
endmodule

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

