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

module operacional (
    input 	logic clk, 
    input 	logic rst, 
    input 	logic sensor_de_contato, 
    input 	logic botao_interno,
    input 	logic key_valid,
    input	logic [3:0] key_code,
    output 	bcdPac_t bcd_out,
    output 	logic bcd_enable,
    output 	logic tranca, 
    output 	logic bip,
    output 	logic setup_on,
    input	logic setup_end,
    output 	setupPac_t data_setup_old,
    input 	setupPac_t data_setup_new
 );

    typedef enum logic [3:0] {
        RESET,
        MONTAR_PIN,
        VERIFICAR_SENHA,
        ESPERA,
        UPDATE_MASTER,
        TRAVA_OFF,
        SETUP,
        PORTA_FECHADA,
        PORTA_ABERTA,
        TRAVA_ON
    } estado_t;

    estado_t ESTADO_ATUAL;
  
  	// Tempos para 1KHz
    localparam logic [14:0] UM_SEG = 1000, CINCO_SEG = 5000, DEZ_SEG = 10000,
    VINTE_SEG = 20000, TRINTA_SEG = 30000;

    // Sinais e saídas de submódulos
    logic senha_fail;
    logic senha_master_update, senha_master, senha_padrao;
    pinPac_t pin_montado;

    // Contadores
    logic [2:0] tentativas;
    logic [14:0] counter_espera, tempo_espera;
    logic [15:0] counter_travamento, counter_bip;

    setupPac_t data_setup_old_reg;
    assign data_setup_old = data_setup_old_reg;
    
    pinPac_t novo_master_pin;

    logic key_valid_d;
    logic key_valid_rise;

    logic trigger_pulse;
    bcdPac_t bcd_out_reg;
	 
	 task setup_default(); begin
        data_setup_old_reg.bip_status <= 1;
        data_setup_old_reg.bip_time <= CINCO_SEG;
        data_setup_old_reg.tranca_aut_time <= CINCO_SEG;
        data_setup_old_reg.master_pin <= '{status: 1'b0, digit1: 4'd1, digit2: 4'd2, digit3: 4'd3, digit4: 4'd4};
        data_setup_old_reg.pin1 <= '{default: 4'd0, status: 1'b1};
        data_setup_old_reg.pin2 <= '{default: 4'd0, status: 1'b0};
        data_setup_old_reg.pin3 <= '{default: 4'd0, status: 1'b0};
        data_setup_old_reg.pin4 <= '{default: 4'd0, status: 1'b0};
    end
    endtask

    assign bcd_out = bcd_out_reg;

    assign key_valid_rise = key_valid && !key_valid_d;
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            tentativas <= 0;
            counter_espera <= 0;
            counter_travamento <= 0;
            counter_bip <= 0;
            setup_default();
            key_valid_d <= 1'b0;
            bcd_enable <= 1;
            tempo_espera <= 0;
            bip <= 0;
            setup_on <= 0;
            bcd_out_reg <= {4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF}; // Apaga o display
            ESTADO_ATUAL <= RESET;
        end
        else begin
            key_valid_d <= key_valid;
            bcd_enable = trigger_pulse;

            case (ESTADO_ATUAL)
                RESET: begin
                    if (sensor_de_contato) begin
                        tranca <= 1;
                        bcd_enable <= 1;
                        bcd_out_reg <= {4'b1010, 4'b1010, 4'hF, 4'hF, 4'hF, 4'hF}; // Apaga o display
                        ESTADO_ATUAL <= MONTAR_PIN;
                    end else begin
                        bcd_enable <= 0;
                        tranca <= 0;
                    end
                end

                MONTAR_PIN: begin
                    if (key_valid_rise)begin
                        bcd_enable <= 1;
                        if(key_code == 4'hF) begin
                            bcd_out_reg <= {4'b1010, 4'b1010, 4'hF, 4'hF, 4'hF, 4'hF};
                            ESTADO_ATUAL <= VERIFICAR_SENHA;
                        end else if (key_code < 4'b1010) begin
                            bcd_out_reg.BCD5 <= (pin_montado.digit1 < 4'b1010) ? pin_montado.digit1 : 4'b1111;
                            bcd_out_reg.BCD4 <= (pin_montado.digit2 < 4'b1010) ? pin_montado.digit2 : 4'b1111;
                            bcd_out_reg.BCD3 <= (pin_montado.digit3 < 4'b1010) ? pin_montado.digit3 : 4'b1111;
                            bcd_out_reg.BCD2 <= (pin_montado.digit4 < 4'b1010) ? pin_montado.digit4 : 4'b1111;
                        end
                end else if (botao_interno)begin
                        bcd_enable <= 1;
                        bcd_out_reg <= {4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF};
                        ESTADO_ATUAL <= TRAVA_OFF;
                end else begin
                        bcd_enable <= 0;
                    end
                end

                VERIFICAR_SENHA: begin
                    if (senha_fail) begin
                        if (tentativas < 5)
                            tentativas <= tentativas + 1;
                        bcd_out_reg <= {4'b1010, 4'b1010, 4'b1010, 4'b1010, 4'b1010, 4'b1010};
                        ESTADO_ATUAL <= ESPERA;
                    end 
                        
                    else if (senha_master && !senha_master_update)begin
                        tentativas <= 0;
                        bcd_out_reg <= {4'b1010, 4'b1010, 4'hF, 4'hF, 4'hF, 4'hF};
                        ESTADO_ATUAL <= UPDATE_MASTER;
                    end

                    else if (senha_master && senha_master_update)begin
                        tentativas <= 0;
                        setup_on <= 1;
                        ESTADO_ATUAL <= SETUP;
                    end

                    else if (senha_padrao)begin
                        tentativas <= 0;
                        bcd_out_reg <= {4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF};
                        tranca <= 0;
                        ESTADO_ATUAL <= TRAVA_OFF;
                    end

                    else begin
                        if (tentativas < 3)
                            tempo_espera <= UM_SEG;
                        else if (tentativas == 3)
                            tempo_espera <= DEZ_SEG;
                        else if (tentativas == 4)
                            tempo_espera <= VINTE_SEG;
                        else
                            tempo_espera <= TRINTA_SEG;
                    end

                end

                ESPERA: begin
                    counter_espera <= counter_espera + 1;
                    if (counter_espera == tempo_espera) begin
                        counter_espera <= 0;
                        bcd_out_reg <= {4'b1010, 4'b1010, 4'hF, 4'hF, 4'hF, 4'hF};           
                        ESTADO_ATUAL <= MONTAR_PIN;
                    end
                end

                SETUP: begin
                    if (setup_end)begin
                        setup_on <= 0;
                        ESTADO_ATUAL <= MONTAR_PIN;
                    end
                end

                UPDATE_MASTER: begin
                    if (novo_master_pin.status) begin
                        bcd_out_reg <= {4'b1010, 4'b1010, 4'hF, 4'hF, 4'hF, 4'hF};
                        data_setup_old_reg.master_pin <= novo_master_pin;
                        ESTADO_ATUAL <= MONTAR_PIN;
                    end else if (key_valid_rise && key_code < 4'b1010) begin
                            bcd_out_reg.BCD5 <= (pin_montado.digit1 < 4'b1010) ? pin_montado.digit1 : 4'b1111;
                            bcd_out_reg.BCD4 <= (pin_montado.digit2 < 4'b1010) ? pin_montado.digit2 : 4'b1111;
                            bcd_out_reg.BCD3 <= (pin_montado.digit3 < 4'b1010) ? pin_montado.digit3 : 4'b1111;
                            bcd_out_reg.BCD2 <= (pin_montado.digit4 < 4'b1010) ? pin_montado.digit4 : 4'b1111;
                        end
                end

                TRAVA_OFF: begin
                    tentativas <= 0;
                    ESTADO_ATUAL <= PORTA_FECHADA;
                end

                PORTA_FECHADA: begin
                    if(bcd_enable)
                        bcd_enable <= 0;
                    if (!sensor_de_contato)
                        ESTADO_ATUAL <= PORTA_ABERTA;
                    else if ((counter_travamento >= data_setup_old_reg.tranca_aut_time) || botao_interno) begin
                        counter_travamento <= 0;
                        bcd_out_reg <= {4'b1010, 4'b1010, 4'hF, 4'hF, 4'hF, 4'hF};
                        bcd_enable <= 1;
                        tranca <= 1;
                        ESTADO_ATUAL <= TRAVA_ON;
                    end
                    else if (counter_travamento < data_setup_old_reg.tranca_aut_time)
                        counter_travamento <= counter_travamento + 1;     
                end

                PORTA_ABERTA: begin
                    if (sensor_de_contato) begin
                        counter_travamento <= 0;
                        counter_bip <= 0;
                        bip <= 0;
                        ESTADO_ATUAL <= PORTA_FECHADA;
                    end

                    else if (counter_bip < data_setup_old_reg.bip_time)
                        counter_bip <= counter_bip + 1;

                    else if ((counter_bip >= data_setup_old_reg.bip_time) && data_setup_old_reg.bip_status)
                        bip <= 1;

                end

                TRAVA_ON: begin
                    ESTADO_ATUAL <= MONTAR_PIN;
                end

            endcase
        end

    end

    montar_pin inst_montar_pin (
        .clk(clk),
        .rst(rst),
        .key_valid(key_valid),
        .key_code(key_code),
        .pin_out(pin_montado)
    );

    verificar_senha inst_verificar_senha (
        .clk(clk),
        .rst(rst),
        .pin_in(pin_montado),
        .data_setup(data_setup_old),
        .senha_fail(senha_fail),
        .senha_padrao(senha_padrao),
        .senha_master(senha_master),
        .senha_master_update(senha_master_update)
    );

    update_master inst_update_master (
        .clk(clk),
        .rst(rst),
        .enable(senha_master),
        .pin_in(pin_montado),
        .new_master_pin(novo_master_pin)
    );

endmodule

module matrixKeyDecoder (
  input  logic clk, reset,
  input  logic [3:0] col_matrix,
  output logic [3:0] lin_matrix,
  output logic [3:0] tecla_value,
  output logic tecla_valid
);

  typedef enum logic [1:0] {
    STATE_IDLE,
    STATE_DEBOUNCE,
    STATE_ACTIVE,
    STATE_WAIT_RELEASE
  } state_t;

  state_t state;
  logic [6:0] debounce_cnt;
  localparam int DEBOUNCE_MAX = 50;

  logic [1:0] current_row;
  logic [3:0] active_cols;
  logic one_pressed;

  assign one_pressed = (($countones(~col_matrix)) == 1);

  logic [3:0] lin_temp;

  // Codifica (linha, coluna) para número
  function logic [3:0] matrix_to_number(input logic [5:0] code);
    case (code)
      6'b111110: matrix_to_number = 4'd1;
      6'b111101: matrix_to_number = 4'd2;
      6'b111011: matrix_to_number = 4'd3;
      6'b110111: matrix_to_number = 4'd10;
      6'b101110: matrix_to_number = 4'd4;
      6'b101101: matrix_to_number = 4'd5;
      6'b101011: matrix_to_number = 4'd6;
      6'b100111: matrix_to_number = 4'd11;
      6'b011110: matrix_to_number = 4'd7;
      6'b011101: matrix_to_number = 4'd8;
      6'b011011: matrix_to_number = 4'd9;
      6'b010111: matrix_to_number = 4'd12;
      6'b001110: matrix_to_number = 4'd14;
      6'b001101: matrix_to_number = 4'd0;
      6'b001011: matrix_to_number = 4'd15;
      6'b000111: matrix_to_number = 4'd13;
      default:   matrix_to_number = 4'd0;
    endcase
  endfunction

  // FSM + varredura de linha
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= STATE_IDLE;
      debounce_cnt <= 0;
      tecla_valid <= 0;
      tecla_value <= 0;
      current_row <= 0;
      lin_matrix <= 4'b1111;
    end else begin
      
      case (state)
        STATE_IDLE: begin
          lin_temp = 4'b1111;
          lin_temp[current_row] = 1'b0;
          lin_matrix <= lin_temp;
          
          if (one_pressed) begin
            debounce_cnt <= 0;
            state <= STATE_DEBOUNCE;
          end else begin
              current_row <= current_row + 1;
            end
        end

        STATE_DEBOUNCE: begin
          if (!debounce_cnt)
          lin_temp = 4'b1111;
          lin_temp[current_row] = 1'b0;
          lin_matrix <= lin_temp;
          
          if (one_pressed) begin
            debounce_cnt <= debounce_cnt + 1;
            if (debounce_cnt >= DEBOUNCE_MAX)
              state <= STATE_ACTIVE;
          end else begin
            debounce_cnt <= 0;
            state <= STATE_IDLE;
          end
        end

        STATE_ACTIVE: begin
          tecla_valid <= 1;
          tecla_value <= matrix_to_number({~current_row + 2, col_matrix});
          state <= STATE_WAIT_RELEASE;
        end

        STATE_WAIT_RELEASE: begin
          if (!one_pressed) begin
            tecla_valid <= 0;
            state <= STATE_IDLE;
          end
        end

        default: state <= STATE_IDLE;
      endcase
    end
  end

endmodule

module SixDigit7SegCtrl (
    input  logic clk, 
    input  logic rst,
    input  logic enable,
    input  bcdPac_t bcd_packet,
    output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);

  // Registradores internos para armazenar os valores dos BCDs
  bcdPac_t bcd_packet_reg;

  // Bloco sequencial: atualiza os registradores com base em enable
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      bcd_packet_reg.BCD0 <= 4'd0;
      bcd_packet_reg.BCD1 <= 4'd0;
      bcd_packet_reg.BCD2 <= 4'd0;
      bcd_packet_reg.BCD3 <= 4'd0;
      bcd_packet_reg.BCD4 <= 4'd0;
      bcd_packet_reg.BCD5 <= 4'd0;
    end else if (enable) begin
      bcd_packet_reg <= bcd_packet;
    end
  end

  // Conversor BCD para 7 segmentos (combinacional pura)
  function logic [6:0] bcd_to_7seg(input logic [3:0] hex);
    case (hex)
      4'h0: bcd_to_7seg = 7'b1000000;
      4'h1: bcd_to_7seg = 7'b1111001;
      4'h2: bcd_to_7seg = 7'b1011011;
      4'h3: bcd_to_7seg = 7'b0110000;
      4'h4: bcd_to_7seg = 7'b0011001;
      4'h5: bcd_to_7seg = 7'b0010010;
      4'h6: bcd_to_7seg = 7'b0000010;
      4'h7: bcd_to_7seg = 7'b1111000;
      4'h8: bcd_to_7seg = 7'b0000000;
      4'h9: bcd_to_7seg = 7'b0011000;
      4'hA: bcd_to_7seg = 7'b1111110;
      4'hB: bcd_to_7seg = 7'b0000011;
      4'hC: bcd_to_7seg = 7'b1000110;
      4'hD: bcd_to_7seg = 7'b0100001;
      4'hE: bcd_to_7seg = 7'b0000110;
      4'hF: bcd_to_7seg = 7'b1111111;
    endcase
  endfunction

  // Bloco combinacional: gera os sinais HEX* a partir dos registradores
  always_comb begin
    HEX0 = bcd_to_7seg(bcd_packet_reg.BCD0);
    HEX1 = bcd_to_7seg(bcd_packet_reg.BCD1);
    HEX2 = bcd_to_7seg(bcd_packet_reg.BCD2);
    HEX3 = bcd_to_7seg(bcd_packet_reg.BCD3);
    HEX4 = bcd_to_7seg(bcd_packet_reg.BCD4);
    HEX5 = bcd_to_7seg(bcd_packet_reg.BCD5);
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