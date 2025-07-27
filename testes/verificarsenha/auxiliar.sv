typedef struct packed {
logic status;
	logic [3:0] digit1;
	logic [3:0] digit2;
	logic [3:0] digit3;
	logic [3:0] digit4;
} pinPac_t;

typedef struct packed {
	logic bip_status;
	logic [6:0] bip_time;
	logic [6:0]  tranca_aut_time;
	pinPac_t master_pin;
	pinPac_t pin1;
	pinPac_t pin2;
	pinPac_t pin3;
	pinPac_t pin4;
	
} setupPac_t;

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

module verificar_senha (
    input  logic       clk,
    input  logic       rst,
    input  pinPac_t    pin_in,
    input  setupPac_t  data_setup,
    output logic       senha_fail,
    output logic       senha_padrao,
    output logic       senha_master,
    output logic       senha_master_update
);

    typedef enum logic [3:0] {
        RESETADO,
        ESPERA,
        VERIFICAR,
        CHECK_PIN,
        MASTER_UPDATE,
        MASTER_OK,
        MASTER_VALID,
        FAIL_FLAG,
        SETUP_FLAG,
        PIN_FLAG,
        UPDATE_FLAG,
        PIN_VALID,
        HOLD_FLAGS,
        TEMP
    } state_t;

    logic status_d;
    state_t estado;
  	pinPac_t pin_temp;

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            status_d <= 0;
        else
            status_d <= pin_in.status;
    end

    always_ff @(posedge clk or posedge rst) begin : controle_estados
        if (rst) begin
            estado <= RESETADO;
			senha_fail <= 0;
            senha_padrao <= 0;
            senha_master <= 0;
            senha_master_update <= 0;
        end else begin
        case (estado)
            RESETADO: begin
                if (!senha_master_update) begin
                    estado <= ESPERA;
                end
            end

            ESPERA: begin
                if (pin_in.status && !status_d) begin
                    pin_temp.status <= 1;
                    pin_temp.digit1 <= pin_in.digit1;
                    pin_temp.digit2 <= pin_in.digit2;
                    pin_temp.digit3 <= pin_in.digit3;
                    pin_temp.digit4 <= pin_in.digit4;
                    estado <= VERIFICAR;
              	end
            end

            VERIFICAR: begin
                if (!senha_master_update)
                    estado <= MASTER_UPDATE;
                else
                    estado <= CHECK_PIN;
            end

            CHECK_PIN: begin
                if ((pin_temp.digit1 == data_setup.master_pin.digit1) &&
                    (pin_temp.digit2 == data_setup.master_pin.digit2) &&
                    (pin_temp.digit3 == data_setup.master_pin.digit3) &&
                    (pin_temp.digit4 == data_setup.master_pin.digit4)) begin
                    estado <= MASTER_VALID;
                end else if ((pin_temp.digit1 == data_setup.pin1.digit1) &&
                            (pin_temp.digit2 == data_setup.pin1.digit2) &&
                            (pin_temp.digit3 == data_setup.pin1.digit3) &&
                            (pin_temp.digit4 == data_setup.pin1.digit4) &&
                            data_setup.pin1.status) begin
                    estado <= PIN_VALID;
                end else if ((pin_temp.digit1 == data_setup.pin2.digit1) &&
                            (pin_temp.digit2 == data_setup.pin2.digit2) &&
                            (pin_temp.digit3 == data_setup.pin2.digit3) &&
                            (pin_temp.digit4 == data_setup.pin2.digit4) &&
                            data_setup.pin2.status) begin
                    estado <= PIN_VALID;
                end else if ((pin_temp.digit1 == data_setup.pin3.digit1) &&
                            (pin_temp.digit2 == data_setup.pin3.digit2) &&
                            (pin_temp.digit3 == data_setup.pin3.digit3) &&
                            (pin_temp.digit4 == data_setup.pin3.digit4) &&
                            data_setup.pin3.status) begin
                    estado <= PIN_VALID;
                end else if ((pin_temp.digit1 == data_setup.pin4.digit1) &&
                            (pin_temp.digit2 == data_setup.pin4.digit2) &&
                            (pin_temp.digit3 == data_setup.pin4.digit3) &&
                            (pin_temp.digit4 == data_setup.pin4.digit4) &&
                            data_setup.pin4.status) begin
                    estado <= PIN_VALID;
                end else begin
                    estado <= FAIL_FLAG;
                end
            end

            MASTER_UPDATE: begin
                if ((pin_temp.digit4 == 4'b0001) &&
                    (pin_temp.digit3 == 4'b0010) &&
                    (pin_temp.digit2 == 4'b0011) &&
                    (pin_temp.digit1 == 4'b0100)) begin
                        estado <= MASTER_OK;
                end else begin
					senha_fail <= 1;
                    estado <= FAIL_FLAG;
                end
            end

            MASTER_OK: begin
                if(!senha_master_update)begin
                    senha_master <= 1;
                    estado <= UPDATE_FLAG;
				end
            end

            MASTER_VALID: begin
                if(senha_master)begin
                    senha_master <= 1;
                    estado <= SETUP_FLAG;
				end
            end

            UPDATE_FLAG: begin
                if(data_setup.master_pin.status)begin
                    senha_master_update <= 1;
                    senha_master <= 0;
                    estado <= TEMP;
                end
            end
          
          	PIN_VALID: begin
               senha_padrao = 1;
               estado <= PIN_FLAG;
            end
            
            FAIL_FLAG:     estado <= HOLD_FLAGS;
            SETUP_FLAG:    estado <= HOLD_FLAGS;
            PIN_FLAG:      estado <= HOLD_FLAGS;

            HOLD_FLAGS: begin
                senha_fail <= 0;
                senha_padrao <= 0;
                estado <= TEMP;
            end

            TEMP: begin
                case ({senha_fail, senha_master, senha_padrao})
                    
                    4'b0000: begin
                        estado <= ESPERA;
                  		pin_temp.status <= 0;
                        pin_temp.digit1 <= 4'b1111;
                        pin_temp.digit2 <= 4'b1111;
                        pin_temp.digit3 <= 4'b1111;
                        pin_temp.digit4 <= 4'b1111;
                    end
                    
                endcase
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
        4'b1010 : Seg = 7'b0001000;
        4'b1011 : Seg = 7'b0000011;
        4'b1100 : Seg = 7'b1000110;
        4'b1101 : Seg = 7'b0100001;
        4'b1110 : Seg = 7'b0000110;		
        4'b1111 : Seg = 7'b0001110;
	 endcase
 end
endmodule

