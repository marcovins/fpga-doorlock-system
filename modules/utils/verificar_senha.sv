// VERIFICAR SENHA
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

    state_t     estado;
    state_t     estado_ant;
    logic       status_d;
    pinPac_t    pin_temp;

    // Armazena status do ciclo anterior
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            status_d <= 0;
				
        end else begin
            status_d <= pin_in.status;
        end
    end

    // Estado principal
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            estado <= RESETADO;
        end else begin
            case (estado)
                RESETADO: begin
                    estado <= ESPERA;
                end

                ESPERA: begin
                    if (pin_in.status && !status_d) begin
                        estado <= VERIFICAR;
                        pin_temp <= pin_in;
                        pin_temp.status <= 1;
                    end
                end

                VERIFICAR: begin
                    if (senha_master_update) begin
                        estado <= MASTER_UPDATE;
                    end else begin
                        estado <= CHECK_PIN;
                    end
                end

                CHECK_PIN: begin
                    if (pin_temp.digit1 == data_setup.master_pin.digit1 &&
                        pin_temp.digit2 == data_setup.master_pin.digit2 &&
                        pin_temp.digit3 == data_setup.master_pin.digit3 &&
                        pin_temp.digit4 == data_setup.master_pin.digit4) begin
                        estado <= MASTER_VALID;

                    end else if (pin_temp.digit1 == data_setup.pin1.digit1 &&
                                 pin_temp.digit2 == data_setup.pin1.digit2 &&
                                 pin_temp.digit3 == data_setup.pin1.digit3 &&
                                 pin_temp.digit4 == data_setup.pin1.digit4) begin
                        estado <= PIN_VALID;

                    end else if (pin_temp.digit1 == data_setup.pin2.digit1 &&
                                 pin_temp.digit2 == data_setup.pin2.digit2 &&
                                 pin_temp.digit3 == data_setup.pin2.digit3 &&
                                 pin_temp.digit4 == data_setup.pin2.digit4 &&
                                 data_setup.pin2.status) begin
                        estado <= PIN_VALID;

                    end else if (pin_temp.digit1 == data_setup.pin3.digit1 &&
                                 pin_temp.digit2 == data_setup.pin3.digit2 &&
                                 pin_temp.digit3 == data_setup.pin3.digit3 &&
                                 pin_temp.digit4 == data_setup.pin3.digit4 &&
                                 data_setup.pin3.status) begin
                        estado <= PIN_VALID;

                    end else if (pin_temp.digit1 == data_setup.pin4.digit1 &&
                                 pin_temp.digit2 == data_setup.pin4.digit2 &&
                                 pin_temp.digit3 == data_setup.pin4.digit3 &&
                                 pin_temp.digit4 == data_setup.pin4.digit4 &&
                                 data_setup.pin4.status) begin
                        estado <= PIN_VALID;

                    end else begin
                        estado <= FAIL_FLAG;
                    end
                end

                MASTER_UPDATE: begin
                    if (pin_temp.digit1 == 4'b0001 &&
                        pin_temp.digit2 == 4'b0010 &&
                        pin_temp.digit3 == 4'b0011 &&
                        pin_temp.digit4 == 4'b0100) begin
                        estado <= MASTER_OK;
                    end else begin
                        estado <= CHECK_PIN;
                    end
                end

                MASTER_OK: begin
                    if (senha_master_update) begin
                        estado <= UPDATE_FLAG;
                    end
                end

                MASTER_VALID: begin
                    if (senha_master) begin
                        estado <= SETUP_FLAG;
                    end
                end

                UPDATE_FLAG: begin
                    if (data_setup.master_pin.status) begin
                        estado <= TEMP;
                    end
                end

                PIN_VALID: begin
                    estado <= PIN_FLAG;
                end

                FAIL_FLAG,
                SETUP_FLAG,
                PIN_FLAG: begin
                    estado <= HOLD_FLAGS;
                end

                HOLD_FLAGS: begin
                    estado <= TEMP;
                end

                TEMP: begin
                    if (!senha_fail && !senha_master && !senha_padrao) begin
                        estado <= ESPERA;
                        pin_temp <= '{status: 0, digit1: 4'b1110, digit2: 4'b1110, digit3: 4'b1110, digit4: 4'b1110};
                    end
                end

                default: estado <= ESPERA;
            endcase
        end
    end

    // Armazena estado anterior
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            estado_ant <= RESETADO;
        else
            estado_ant <= estado;
    end

    // Sinais de saída (antes combinacionais, agora sincronizados)
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            senha_fail <= 0;
            senha_padrao <= 0;
            senha_master <= 0;
            senha_master_update <= 1;
        end else begin
            // valores default
            senha_fail <= 0;
            senha_padrao <= 0;
            senha_master <= 0;

            case (estado)
                FAIL_FLAG: senha_fail <= 1;
                PIN_FLAG:  senha_padrao <= 1;
                MASTER_VALID,
                UPDATE_FLAG: senha_master <= 1;
                default: ; // já estão zerados
            endcase

            // senha_master_update deve ir para 0 quando sai do TEMP
            if (estado_ant == MASTER_OK) begin
                senha_master_update <= 0;
            end
        end
    end
endmodule
