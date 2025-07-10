module verificar_senha (
    input  logic       clk,
    input  logic       rst,
    input  pinPac_t    pin_in,
    input  setupPac_t  data_setup,
    output logic       senha_fail,
    output logic       senha_padrao,
    output logic       senha_pin,
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
        end else begin
        case (estado)
            RESETADO: begin
                if (!senha_master_update) begin
                    estado <= ESPERA;
                end
            end

            ESPERA: begin
                if (pin_in.status && !status_d)
                    estado <= VERIFICAR;
              		pin_temp.status <= 1;
              		pin_temp.digit1 <= pin_in.digit1;
                    pin_temp.digit2 <= pin_in.digit2;
                    pin_temp.digit3 <= pin_in.digit3;
                    pin_temp.digit4 <= pin_in.digit4;
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
                if ((pin_temp.digit1 == 4'b0001) &&
                    (pin_temp.digit2 == 4'b0010) &&
                    (pin_temp.digit3 == 4'b0011) &&
                    (pin_temp.digit4 == 4'b0100)) begin
                    estado <= MASTER_OK;
                end else begin
                    estado <= FAIL_FLAG;
                end
            end

            MASTER_OK: begin
                if(!senha_master_update)
                    estado <= UPDATE_FLAG;
            end

            MASTER_VALID: begin
                if(senha_master)
                    estado <= SETUP_FLAG;
            end

            UPDATE_FLAG: begin
                if(data_setup.master_pin.status)
                    estado <= TEMP;
            end
          
          	PIN_VALID: begin
              estado <= PIN_FLAG;
            end
            
            FAIL_FLAG:     estado <= HOLD_FLAGS;
            SETUP_FLAG:    estado <= HOLD_FLAGS;
            PIN_FLAG:      estado <= HOLD_FLAGS;

            HOLD_FLAGS: begin
                    estado <= TEMP;
                end

            TEMP: begin
                case ({senha_fail, senha_master, senha_padrao, senha_pin})
                    
                    4'b0000: begin
                        estado <= ESPERA;
                  		pin_temp.status <= 0;
                        pin_temp.digit1 <= 4'b1111;
                        pin_temp.digit2 <= 4'b1111;
                        pin_temp.digit3 <= 4'b1111;
                        pin_temp.digit4 <= 4'b1111;
                    end
                    
                    default: 
                        estado <= TEMP;
                endcase
            end

        endcase
    end
end

    always_comb begin : controle_variaveis
        if (rst) begin
            senha_fail = 0;
            senha_padrao = 0;
            senha_pin = 0;
            senha_master = 0;
            senha_master_update = 0;

        end else begin
        case (estado)

            MASTER_VALID: begin
                senha_master = 1;
            end

            FAIL_FLAG: begin
                senha_fail = 1;
            end

            PIN_FLAG: begin
               senha_padrao = 1;
            end

            UPDATE_FLAG: begin
                senha_master = 1;
            end

            TEMP: begin
                senha_master_update = 1;
                senha_fail = 0;
                senha_padrao = 0;
                senha_pin = 0;
                senha_master = 0;
                
            end
        endcase
    end

end

endmodule