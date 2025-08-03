typedef struct packed {
logic status;
	logic [3:0] digit1;
	logic [3:0] digit2;
	logic [3:0] digit3;
	logic [3:0] digit4;
} pinPac_t;

module update_master (
    input logic	        clk,
    input logic 	    rst,
    input logic		    enable,
	input pinPac_t		pin_in,
	output pinPac_t 	new_master_pin
);

  typedef enum {
    INICIAL,
    ATUALIZAR,
    TEMP,
    FINAL
  } estado;
  
  estado ESTADO_ATUAL;
  
  always_ff @(posedge clk or posedge rst) begin
    if (rst)begin
      ESTADO_ATUAL <= INICIAL;
      new_master_pin.status <= 0;
    end
    else begin
      case (ESTADO_ATUAL)
        
        INICIAL: begin
          if (enable)
            ESTADO_ATUAL <= ATUALIZAR;
        end
        
        ATUALIZAR: begin
          if (pin_in.status)begin
            
            // Primeiro copia os valores
            new_master_pin.digit1 = pin_in.digit1;
            new_master_pin.digit2 = pin_in.digit2;
            new_master_pin.digit3 = pin_in.digit3;
            new_master_pin.digit4 = pin_in.digit4;

            // Verificando se os valores já foram copiados para subir o status para true
            if (new_master_pin.digit1 == pin_in.digit1 &&
                new_master_pin.digit2 == pin_in.digit2 &&
                new_master_pin.digit3 == pin_in.digit3 &&
                new_master_pin.digit4 == pin_in.digit4) begin
                new_master_pin.status <= 1;
                ESTADO_ATUAL <= TEMP;
            end
          end
        end
        
        TEMP: begin
          if(!enable)
            ESTADO_ATUAL <= FINAL;
        end
      endcase
    end
  end
endmodule

typedef struct packed {
    logic bip_status;
    logic [6:0] bip_time;
    logic [6:0] tranca_aut_time;
    pinPac_t master_pin;
    pinPac_t pin1;
    pinPac_t pin2;
    pinPac_t pin3;
    pinPac_t pin4;
} setupPac_t;

typedef struct packed {
    logic [3:0] BCD0;
    logic [3:0] BCD1;
    logic [3:0] BCD2;
    logic [3:0] BCD3;
    logic [3:0] BCD4;
    logic [3:0] BCD5;
} bcdPac_t;

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

    logic key_valid_d, key_valid_rise;
    logic pin_complete;

    assign pin_complete = (pin_out.digit1 != 4'b1110) &&
                          (pin_out.digit2 != 4'b1110) &&
                          (pin_out.digit3 != 4'b1110) &&
                          (pin_out.digit4 != 4'b1110);

    assign key_valid_rise = key_valid && !key_valid_d;


    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin
            ESTADO_ATUAL <= INICIAL;
            pin_out.digit1 <= 4'b1110;
            pin_out.digit2 <= 4'b1110;
            pin_out.digit3 <= 4'b1110;
            pin_out.digit4 <= 4'b1110;
            pin_out.status <= 1'b0;
            key_valid_d <= 1'b0;

        end else begin
 
            key_valid_d <= key_valid;

            case (ESTADO_ATUAL)
                INICIAL: begin
                    pin_out.status <= 1'b0;
                    if (key_valid_rise && key_code < 4'b1010) begin
                        pin_out.digit4 <= pin_out.digit3;
                        pin_out.digit3 <= pin_out.digit2;
                        pin_out.digit2 <= pin_out.digit1;
                        pin_out.digit1 <= key_code;
                        ESTADO_ATUAL <= DIGITO_LIDO;
                    end
                end

                DIGITO_LIDO: begin
                    if (key_valid_rise && key_code == 4'hF && pin_complete) begin
                        ESTADO_ATUAL <= STATUS_TRUE;
                    end else if (key_valid_rise && key_code < 4'b1010) begin
                        pin_out.digit4 <= pin_out.digit3;
                        pin_out.digit3 <= pin_out.digit2;
                        pin_out.digit2 <= pin_out.digit1;
                        pin_out.digit1 <= key_code;
                    end
                end

                STATUS_TRUE: begin
                    pin_out.status <= 1'b1;
                    ESTADO_ATUAL <= HOLD_STATUS;
                end

                HOLD_STATUS: begin
                    pin_out.status <= 1'b1;
                    ESTADO_ATUAL <= TEMP;
                end

                TEMP: begin
                    if (pin_out.status) begin
                        pin_out.status <= 1'b0;
                    end else begin
                        pin_out.digit1 <= 4'b1110;
                        pin_out.digit2 <= 4'b1110;
                        pin_out.digit3 <= 4'b1110;
                        pin_out.digit4 <= 4'b1110;
                        ESTADO_ATUAL <= INICIAL;
                    end
                end

            endcase
        end
    end
endmodule

module divfreq(input reset, clock, output logic clk_i);

  int cont;

  always @(posedge clock or posedge reset) begin
    if(reset) begin
      cont  = 0;
      clk_i = 0;
    end
    else
      if( cont <= 2500000 )
        cont++;
      else begin
        clk_i = ~clk_i;
        cont = 0;
      end
  end
endmodule


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
      4'b1010 : Seg = 7'b1111110; // Mostra apenas um hífen (-)
			4'b1011 : Seg = 7'b0000011;
			4'b1100 : Seg = 7'b1000110;
			4'b1101 : Seg = 7'b0100001;
			4'b1110 : Seg = 7'b0000110;		
			4'b1111 : Seg = 7'b0001110;
	 endcase
 end
endmodule

