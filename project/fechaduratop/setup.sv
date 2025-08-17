// SETUP
module setup (
  input logic clk,
  input logic rst,    
  input logic key_valid,
  input logic [3:0] key_code,
  output bcdPac_t bcd_out,
  output logic bcd_enable,     
  output setupPac_t data_setup_new, 
  input setupPac_t data_setup_old,
  input logic setup_on,
  output logic setup_end
);

  typedef enum logic [5:0] {
    IDLE,
    RECEBER_DATA_SETUP_OLD,
    ATIVAR_BIP,
    ESPERA_SINAL_BIP1,
    MOSTRAR_TEMPO_BIP,
    EDITAR_TEMPO_BIP,
    MOSTRAR_TEMPO_TRAVA,
    EDITAR_TEMPO_TRAVA,
    ESTADO_PIN1,
    MOSTRAR_PIN1,
    EDITAR_PIN1,
    ESTADO_PIN2,
    ESTADO_ESPERA_PIN2,
    MOSTRAR_PIN2,
    EDITAR_PIN2,
    ESTADO_PIN3,
    ESTADO_ESPERA_PIN3,
    MOSTRAR_PIN3,
    EDITAR_PIN3,
    ESTADO_PIN4,
    ESTADO_ESPERA_PIN4,
    MOSTRAR_PIN4,
    EDITAR_PIN4,
    FIM
  } state_t;

  state_t ESTADO_ATUAL, PROXIMO_ESTADO;
  setupPac_t data_setup_reg, data_setup_temp;
  bcdPac_t bcd_reg, bcd_temp;
  logic bcd_enable_temp, bcd_enable_reg;
  logic [3:0] digito_entrada; 
  logic digit_valid;
  
  assign digito_entrada = key_code;
  assign digit_valid = key_valid && (key_code <= 4'd9);
  assign data_setup_new = data_setup_temp;
  assign bcd_out        = bcd_temp;
  assign bcd_enable     = bcd_enable_temp;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      bcd_enable_reg <= 1'b1;
      data_setup_reg <= '0; 
      bcd_reg <= 'hA; 
      ESTADO_ATUAL <=  IDLE;

    end else begin
      ESTADO_ATUAL <= PROXIMO_ESTADO; 
      data_setup_reg <= data_setup_temp; 
      bcd_reg <= bcd_temp; 
      bcd_enable_reg <= bcd_enable_temp;
    end
  end

  always_comb begin
    PROXIMO_ESTADO  = ESTADO_ATUAL;
    data_setup_temp = data_setup_reg;
    bcd_temp = bcd_reg;
    bcd_enable_temp = 1'b0;
    setup_end = 0;

    case (ESTADO_ATUAL)
      IDLE: begin
        if (setup_on) PROXIMO_ESTADO = RECEBER_DATA_SETUP_OLD;
      end

      RECEBER_DATA_SETUP_OLD: begin
        data_setup_temp = data_setup_old;

        bcd_temp.BCD5 = 4'd0; 
        bcd_temp.BCD4 = 4'd1;

        bcd_temp.BCD3 = 4'hA;
        bcd_temp.BCD2 = 4'hA;
        bcd_temp.BCD1 = 4'hA; 
        bcd_temp.BCD0 = (data_setup_reg.bip_status ? 4'd1 : 4'd0);
        bcd_enable_temp = 1'b1; PROXIMO_ESTADO = ATIVAR_BIP;
      end

      ATIVAR_BIP: PROXIMO_ESTADO = ESPERA_SINAL_BIP1;
      ESPERA_SINAL_BIP1: begin
        if (key_valid && (key_code == 4'd0 || key_code == 4'd1)) begin
          data_setup_temp.bip_status = (key_code == 4'd1);
          bcd_temp.BCD0 = key_code; 
          bcd_enable_temp = 1'b1;
        end else if (key_valid && key_code == 4'hF) begin

          bcd_temp.BCD5 = 4'd0; 
          bcd_temp.BCD4 = 4'd2;

          bcd_temp.BCD3 = 4'hA; 
          bcd_temp.BCD2 = 4'hA;
          bcd_temp.BCD1 = (data_setup_reg.bip_time / 10) % 10;
          bcd_temp.BCD0 = (data_setup_reg.bip_time % 10);
          bcd_enable_temp = 1'b1; PROXIMO_ESTADO = MOSTRAR_TEMPO_BIP;
        end
      end

      MOSTRAR_TEMPO_BIP: PROXIMO_ESTADO = EDITAR_TEMPO_BIP;
      EDITAR_TEMPO_BIP: begin
        if (digit_valid) begin
          bcd_temp.BCD1 = bcd_temp.BCD0;
          bcd_temp.BCD0 = digito_entrada;
          bcd_enable_temp = 1'b1;
        end else if (key_valid && key_code == 4'hF) begin
          integer valor;
          valor = 10 * bcd_temp.BCD1 + bcd_temp.BCD0;
          valor = (valor < 5) ? 5 :
                  (valor > 60) ? 60 :
                  valor;
          data_setup_temp.bip_time = valor[5:0];

          bcd_temp.BCD5 = 4'd0; 
          bcd_temp.BCD4 = 4'd3;

          bcd_temp.BCD3 = 4'hA; 
          bcd_temp.BCD2 = 4'hA;
          bcd_temp.BCD1 = (data_setup_reg.tranca_aut_time / 10) % 10;
          bcd_temp.BCD0 = (data_setup_reg.tranca_aut_time % 10);
          bcd_enable_temp = 1'b1; PROXIMO_ESTADO = MOSTRAR_TEMPO_TRAVA;
        end
      end

      MOSTRAR_TEMPO_TRAVA: PROXIMO_ESTADO = EDITAR_TEMPO_TRAVA;
      EDITAR_TEMPO_TRAVA: begin
        if (digit_valid) begin
          bcd_temp.BCD1 = bcd_temp.BCD0;
          bcd_temp.BCD0 = digito_entrada;
          bcd_enable_temp = 1'b1;
        end else if (key_valid && key_code == 4'hF) begin
          integer valor;
          valor = 10 * bcd_temp.BCD1 + bcd_temp.BCD0;
          valor = (valor < 5) ? 5 :
                  (valor > 60) ? 60 :
                  valor;
          data_setup_temp.tranca_aut_time = valor[5:0];

          bcd_temp.BCD5 = 4'd0; 
          bcd_temp.BCD4 = 4'd4;

          bcd_temp.BCD0 = data_setup_reg.pin1.digit4; 
          bcd_temp.BCD1 = data_setup_reg.pin1.digit3;
          bcd_temp.BCD2 = data_setup_reg.pin1.digit2; 
          bcd_temp.BCD3 = data_setup_reg.pin1.digit1;
          bcd_enable_temp = 1'b1; PROXIMO_ESTADO = MOSTRAR_PIN1;
        end
      end

      ESTADO_PIN1: begin

        bcd_temp.BCD5 = 4'd0; 
        bcd_temp.BCD4 = 4'd4;

        bcd_temp.BCD0 = data_setup_reg.pin1.digit4; 
        bcd_temp.BCD1 = data_setup_reg.pin1.digit3;
        bcd_temp.BCD2 = data_setup_reg.pin1.digit2; 
        bcd_temp.BCD3 = data_setup_reg.pin1.digit1;
        bcd_enable_temp = 1'b1;
        PROXIMO_ESTADO = MOSTRAR_PIN1;
      end

      MOSTRAR_PIN1: begin
        if (digit_valid) begin  
          bcd_temp.BCD3 = bcd_temp.BCD2;
          bcd_temp.BCD2 = bcd_temp.BCD1;
          bcd_temp.BCD1 = bcd_temp.BCD0;
          bcd_temp.BCD0 = digito_entrada; 
          bcd_enable_temp = 1'b1;

        end else if (key_valid && key_code == 4'hF) begin
          data_setup_temp.pin1.status = 1'b1;
          data_setup_temp.pin1.digit4 = bcd_temp.BCD3;
          data_setup_temp.pin1.digit3 = bcd_temp.BCD2;
          data_setup_temp.pin1.digit2 = bcd_temp.BCD1;
          data_setup_temp.pin1.digit1 = bcd_temp.BCD0;

          bcd_temp.BCD5 = 4'd0;
          bcd_temp.BCD4 = 4'd5;

          bcd_temp.BCD3 = 4'hA;
          bcd_temp.BCD2 = 4'hA;
          bcd_temp.BCD1 = 4'hA;
          bcd_temp.BCD0 = (data_setup_reg.pin2.status ? 4'd1 : 4'd0);
          bcd_enable_temp = 1'b1; PROXIMO_ESTADO = ESTADO_PIN2;
        end
      end

      ESTADO_PIN2: PROXIMO_ESTADO = ESTADO_ESPERA_PIN2;
      ESTADO_ESPERA_PIN2: begin
        if (key_valid && (key_code == 4'd0 || key_code == 4'd1)) begin
          data_setup_temp.pin2.status = (key_code == 4'd1);
          bcd_temp.BCD0 = key_code;
          bcd_enable_temp = 1'b1;

        end else if (key_valid && key_code == 4'hF) begin

          bcd_temp.BCD5 = 4'd0; 
          bcd_temp.BCD4 = 4'd6;

          bcd_temp.BCD0 = data_setup_reg.pin2.digit4; 
          bcd_temp.BCD1 = data_setup_reg.pin2.digit3;
          bcd_temp.BCD2 = data_setup_reg.pin2.digit2; 
          bcd_temp.BCD3 = data_setup_reg.pin2.digit1;
          bcd_enable_temp = 1'b1; PROXIMO_ESTADO = MOSTRAR_PIN2;
        end
      end

      MOSTRAR_PIN2: begin
        if (digit_valid) begin
          bcd_temp.BCD3 = bcd_temp.BCD2; 
          bcd_temp.BCD2 = bcd_temp.BCD1;
          bcd_temp.BCD1 = bcd_temp.BCD0; 
          bcd_temp.BCD0 = digito_entrada; 
          bcd_enable_temp = 1'b1;

        end else if (key_valid && key_code == 4'hF) begin
          data_setup_temp.pin2.digit4 = bcd_temp.BCD3; 
          data_setup_temp.pin2.digit3 = bcd_temp.BCD2;
          data_setup_temp.pin2.digit2 = bcd_temp.BCD1; 
          data_setup_temp.pin2.digit1 = bcd_temp.BCD0;

          bcd_temp.BCD5 = 4'd0; 
          bcd_temp.BCD4 = 4'd7;
          bcd_temp.BCD3 = 4'hA; 
          bcd_temp.BCD2 = 4'hA; 
          bcd_temp.BCD1 = 4'hA;

          bcd_temp.BCD0 = (data_setup_reg.pin3.status ? 4'd1 : 4'd0);
          bcd_enable_temp = 1'b1; PROXIMO_ESTADO = ESTADO_PIN3;
        end
      end

      ESTADO_PIN3: PROXIMO_ESTADO = ESTADO_ESPERA_PIN3;
      ESTADO_ESPERA_PIN3: begin
        if (key_valid && (key_code == 4'd0 || key_code == 4'd1)) begin
          data_setup_temp.pin3.status = (key_code == 4'd1);
          bcd_temp.BCD0 = key_code;
          bcd_enable_temp = 1'b1;

        end else if (key_valid && key_code == 4'hF) begin

          bcd_temp.BCD5 = 4'd0; 
          bcd_temp.BCD4 = 4'd8;

          bcd_temp.BCD0 = data_setup_reg.pin3.digit4; 
          bcd_temp.BCD1 = data_setup_reg.pin3.digit3;
          bcd_temp.BCD2 = data_setup_reg.pin3.digit2; 
          bcd_temp.BCD3 = data_setup_reg.pin3.digit1;
          bcd_enable_temp = 1'b1; PROXIMO_ESTADO = MOSTRAR_PIN3;
        end
      end

      MOSTRAR_PIN3: begin
        if (digit_valid) begin
          bcd_temp.BCD3 = bcd_temp.BCD2;
          bcd_temp.BCD2 = bcd_temp.BCD1;
          bcd_temp.BCD1 = bcd_temp.BCD0;
          bcd_temp.BCD0 = digito_entrada;
          bcd_enable_temp = 1'b1;

        end else if (key_valid && key_code == 4'hF) begin
          data_setup_temp.pin3.digit4 = bcd_temp.BCD3; 
          data_setup_temp.pin3.digit3 = bcd_temp.BCD2;
          data_setup_temp.pin3.digit2 = bcd_temp.BCD1; 
          data_setup_temp.pin3.digit1 = bcd_temp.BCD0;

          bcd_temp.BCD5 = 4'd0; 
          bcd_temp.BCD4 = 4'd9;

          bcd_temp.BCD3 = 4'hA; 
          bcd_temp.BCD2 = 4'hA; 
          bcd_temp.BCD1 = 4'hA;

          bcd_temp.BCD0 = (data_setup_reg.pin4.status ? 4'd1 : 4'd0);
          bcd_enable_temp = 1'b1; PROXIMO_ESTADO = ESTADO_PIN4;
        end
      end

      ESTADO_PIN4: PROXIMO_ESTADO = ESTADO_ESPERA_PIN4;
      ESTADO_ESPERA_PIN4: begin
        if (key_valid && (key_code == 4'd0 || key_code == 4'd1)) begin
          data_setup_temp.pin4.status = (key_code == 4'd1);
          bcd_temp.BCD0 = key_code; bcd_enable_temp = 1'b1;

        end else if (key_valid && key_code == 4'hF) begin

          bcd_temp.BCD5 = 4'd1; 
          bcd_temp.BCD4 = 4'd0;

          bcd_temp.BCD0 = data_setup_reg.pin4.digit4; 
          bcd_temp.BCD1 = data_setup_reg.pin4.digit3;
          bcd_temp.BCD2 = data_setup_reg.pin4.digit2; 
          bcd_temp.BCD3 = data_setup_reg.pin4.digit1;
          bcd_enable_temp = 1'b1; PROXIMO_ESTADO = MOSTRAR_PIN4;
        end
      end

      MOSTRAR_PIN4: begin
        if (digit_valid) begin
          bcd_temp.BCD3 = bcd_temp.BCD2;
          bcd_temp.BCD2 = bcd_temp.BCD1;
          bcd_temp.BCD1 = bcd_temp.BCD0;
          bcd_temp.BCD0 = digito_entrada; 
          bcd_enable_temp = 1'b1;

        end else if (key_valid && key_code == 4'hF) begin
          data_setup_temp.pin4.digit4 = bcd_temp.BCD3;
          data_setup_temp.pin4.digit3 = bcd_temp.BCD2;
          data_setup_temp.pin4.digit2 = bcd_temp.BCD1;
          data_setup_temp.pin4.digit1 = bcd_temp.BCD0;

			bcd_temp.BCD3 = 4'hA; 
          bcd_temp.BCD2 = 4'hA;
		    bcd_temp.BCD4 = 4'hA; 
          bcd_temp.BCD5 = 4'hA;
          bcd_temp.BCD1 = 4'hA; 
          bcd_temp.BCD0 = 4'hA; 
          PROXIMO_ESTADO = FIM;
          bcd_enable_temp = 1'b1;
        end
      end

      FIM: begin
        setup_end = 1'b1;
        if(!setup_on) begin
            PROXIMO_ESTADO = IDLE;
            setup_end = 1'b0;
        end
      end
      default: PROXIMO_ESTADO = IDLE;
    endcase
  end
endmodule