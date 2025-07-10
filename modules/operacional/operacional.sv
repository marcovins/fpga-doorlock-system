// Tipos de dados
typedef struct packed {
    logic status;
    logic [3:0] digit1;
    logic [3:0] digit2;
    logic [3:0] digit3;
    logic [3:0] digit4;
} pinPac_t;

typedef struct packed {
    logic bip_status;
    logic [15:0] bip_time; // Qnt de bits alterada do documento
    logic [15:0] tranca_aut_time; // Qnt de bits alterada do documento
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

    // Sinais e saídas de submódulos
    logic senha_fail;
    logic senha_pin;
    logic senha_master_update, senha_master, senha_padrao;
    pinPac_t pin_montado;

    // Contadores
    logic [2:0] tentativas;
    logic [14:0] counter_espera, tempo_espera;
    logic [15:0] counter_travamento, counter_bip;

    // Tempos para 1KHz
    localparam logic [14:0] UM_SEG = 1000, CINCO_SEG = 5000, DEZ_SEG = 10000,
    VINTE_SEG = 20000, TRINTA_SEG = 30000;

    setupPac_t data_setup_old_reg;
    assign data_setup_old = data_setup_old_reg;
    
    pinPac_t novo_master_pin;

    logic key_valid_d;
    logic key_valid_rise;

    assign key_valid_rise = key_valid && !key_valid_d;
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            tentativas <= 0;
            counter_espera <= 0;
            counter_travamento <= 0;
            counter_bip <= 0;
            setup_default();
            bcd_out <= '{default: 4'b1111}; // Apaga o display
            key_valid_d <= 1'b0;
            ESTADO_ATUAL <= RESET;
        end
        else begin
            key_valid_d <= key_valid;

            case (ESTADO_ATUAL)
                RESET: begin
                    if (sensor_de_contato)
                        ESTADO_ATUAL <= MONTAR_PIN;
                end

                MONTAR_PIN: begin
                    if (key_code == 4'hF && key_valid_rise)
                        ESTADO_ATUAL <= VERIFICAR_SENHA;
                    else if (botao_interno)
                        ESTADO_ATUAL <= TRAVA_OFF;
                end

                VERIFICAR_SENHA: begin
                    if (senha_fail) begin
                        if (tentativas < 5)
                            tentativas <= tentativas + 1;
                        ESTADO_ATUAL <= ESPERA;
                    end else begin
                        tentativas <= 0;
                        if (senha_master && !senha_master_update)
                            ESTADO_ATUAL <= UPDATE_MASTER;
                        else if (senha_master && senha_master_update)
                            ESTADO_ATUAL <= SETUP;
                        else if (senha_padrao)
                            ESTADO_ATUAL <= TRAVA_OFF;
                    end
                end

                ESPERA: begin
                    counter_espera <= counter_espera + 1;
                    if (counter_espera == tempo_espera) begin
                        counter_espera <= 0;             
                        ESTADO_ATUAL <= MONTAR_PIN;
                    end
                end

                SETUP: begin
                    if (setup_end)
                        ESTADO_ATUAL <= MONTAR_PIN;
                end

                UPDATE_MASTER: begin
                    if (novo_master_pin.status) begin
                        data_setup_old_reg.master_pin <= novo_master_pin;
                        ESTADO_ATUAL <= MONTAR_PIN;
                    end
                end

                TRAVA_OFF: begin
                    tentativas <= 0;
                    bcd_out <= '{default: 4'b1111}; // Apaga o display
                    ESTADO_ATUAL <= PORTA_FECHADA;
                end

                PORTA_FECHADA: begin
                    if (!sensor_de_contato)
                        ESTADO_ATUAL <= PORTA_ABERTA;
                    else if ((counter_travamento >= data_setup_old_reg.tranca_aut_time) || botao_interno) begin
                        counter_travamento <= 0;
                        ESTADO_ATUAL <= TRAVA_ON;
                    end
                    else if (counter_travamento < data_setup_old_reg.tranca_aut_time)
                        counter_travamento <= counter_travamento + 1;     
                end

                PORTA_ABERTA: begin
                    if (sensor_de_contato) begin
                        counter_travamento <= 0;
                        counter_bip <= 0;
                        ESTADO_ATUAL <= PORTA_FECHADA;
                    end
                    else if (counter_bip < data_setup_old_reg.bip_time)
                        counter_bip <= counter_bip + 1;

                end

                TRAVA_ON: begin
                    ESTADO_ATUAL <= MONTAR_PIN;
                end

            endcase
        end

    end

    always_comb begin
        case (ESTADO_ATUAL)
            RESET: begin
                tempo_espera = 0;
                tranca = 0;
                bip = 0;
                setup_on = 0;
                bcd_enable = 1;
            end

            MONTAR_PIN: begin
                bcd_enable = 1;
                tranca = 1;
                setup_on = 0;
            end

            VERIFICAR_SENHA: begin
                if (tentativas < 3)
                    tempo_espera = UM_SEG;
                else if (tentativas == 3)
                    tempo_espera = DEZ_SEG;
                else if (tentativas == 4)
                    tempo_espera = VINTE_SEG;
                else
                    tempo_espera = TRINTA_SEG;
            end

            PORTA_FECHADA:
                bip = 0;

            PORTA_ABERTA: begin
                if ((counter_bip >= data_setup_old_reg.bip_time) && data_setup_old_reg.bip_status)
                    bip = 1;
            end

            TRAVA_OFF: begin
                bcd_enable = 1;
                tranca = 0;
            end

            TRAVA_ON:
                tranca = 1;

            SETUP:
                setup_on = 1;

            default:
                bcd_enable = 0;
        endcase
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
        .senha_pin(senha_pin),
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

endmodule;
