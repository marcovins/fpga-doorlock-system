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

module setup(
input	logic 		clk, 
input 	logic 		rst,
input 	logic 		key_valid,
input	logic [3:0] key_code,
output 	bcdPac_t 	bcd_out,
output 	logic 		bcd_enable,
output 	setupPac_t 	data_setup_new,
input 	setupPac_t 	data_setup_old,
input 	logic 		setup_on,
output	logic 		setup_end
 );

    typedef enum logic [3:0] {  
        IDLE,
        RECEBER_DATA_SETUP_OLD,
        ATIVAR_BIP,
        TEMPO_BIP,
        TEMPO_TRAVAMENTO_AUTO,
        SENHA_PIN1,
        ATIVAR_PIN2,
        SENHA_PIN2,
        ATIVAR_PIN3,
        SENHA_PIN3,
        ATIVAR_PIN4,
        SENHA_PIN4,
        GERAR_DATA_SETUP_NEW,
        BAIXAR_SETUP_END,
        ESPERAR_SETUP_ON,
        LEVANTAR_SETUP_END

    } estados_setup;

    estados_setup ESTADO_ATUAL;

    task automatic shift_digits(
        inout logic [3:0] d1, d2, d3, d4,
        input logic [3:0] new_value,
        inout bcdPac_t bcd_in
    );
        d1 = d2;
        d2 = d3;
        d3 = d4;
        d4 = new_value;
        
        bcd_in.BCD2 = d1;
        bcd_in.BCD3 = d2;
        bcd_in.BCD4 = d3;
        bcd_in.BCD5 = d4;
    endtask

    task automatic update_bcd(
        input logic [3:0] d0, d1, d2, d3, d4, d5,
        inout bcdPac_t bcd_in
    );
        bcd_in.BCD0 = d0;
        bcd_in.BCD1 = d1;
        bcd_in.BCD2 = d2;
        bcd_in.BCD3 = d3;
        bcd_in.BCD4 = d4;
        bcd_in.BCD5 = d5;

    endtask

    always_ff@(posedge clk or posedge rst) begin
        if(rst)begin
            ESTADO_ATUAL <= IDLE;
            setup_end <= 1;
            bcd_enable <= 1;
            
        end else begin
            int valor, dezena, unidade;

            case(ESTADO_ATUAL)
                
                IDLE:begin
                    update_bcd( 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, bcd_out);

                    if(bcd_enable)
                        bcd_enable = 0;
                    setup_end <= 1;
                    if(setup_on)
                        ESTADO_ATUAL <= RECEBER_DATA_SETUP_OLD;
                end

                RECEBER_DATA_SETUP_OLD:begin
                    data_setup_new = data_setup_old;
                    bcd_enable = 1;
                    update_bcd( 4'd0, 4'd1, 4'hF, 4'hF, 4'hF, data_setup_new.bip_status, bcd_out);
                    
                    ESTADO_ATUAL = ATIVAR_BIP;
                end

                ATIVAR_BIP: begin
                    if (key_valid) begin
                        if (key_code == 4'hF) begin
                            
                            valor   = data_setup_new.bip_time;
                            dezena  = valor / 10;
                            unidade = valor % 10;

                            update_bcd( 4'd0, 4'd2, 4'hF, 4'hF, dezena[3:0], unidade[3:0], bcd_out);

                            while (key_valid);

                            if (bcd_enable)
                                bcd_enable = 0;
                            ESTADO_ATUAL = TEMPO_BIP;
                        end
                        else if (key_code < 4'd2) begin
                            data_setup_new.bip_status <= |key_code;
                            bcd_out.BCD5 <= |key_code;
                            if (!bcd_enable)
                                bcd_enable <= 1;
                    end else begin
                        if (bcd_enable)
                            bcd_enable <= 0;
                        end
                    end
                end

                TEMPO_BIP: begin
                    if (key_valid) begin
                        if(key_code == 4'hF)begin


                            valor   = data_setup_new.tranca_aut_time;
                            dezena  = valor / 10;
                            unidade = valor % 10;

                            update_bcd( 4'd0, 4'd3, 4'hF, 4'hF, dezena[3:0], unidade[3:0], bcd_out);
        
                            while (key_valid);

                            if(bcd_enable)
                                bcd_enable = 0;
                            ESTADO_ATUAL = TEMPO_TRAVAMENTO_AUTO;
                        end
                        else if(key_code < 4'd10)begin
                            // Move unidade atual para dezena, insere nova unidade
                            if(bcd_out.BCD5 != 4'hF)
                                bcd_out.BCD4 = bcd_out.BCD5;
                            bcd_out.BCD5 = key_code;

                            // Atualiza valor a partir dos dois dígitos
                            dezena = bcd_out.BCD4;
                            unidade = bcd_out.BCD5;
                            valor = (dezena * 10) + unidade;

                            // Limita entre 5 e 60
                            if (valor > 60)
                                valor = 60;
                            else if (valor < 5)
                                valor = 5;

                            // Atualiza valor armazenado
                            data_setup_new.bip_time = valor[6:0];
                        end
                    end else begin
                        if (!bcd_enable)
                            bcd_enable <= 1;
                    end
                end

                TEMPO_TRAVAMENTO_AUTO:begin
                    if (key_valid) begin
                        if(key_code == 4'hF)begin
                            update_bcd( 4'd0, 4'd4, data_setup_new.pin1.digit1,
                             data_setup_new.pin1.digit2,
                             data_setup_new.pin1.digit3,
                             data_setup_new.pin1.digit4,
                             bcd_out
                             );

                            while(key_valid);

                            if(bcd_enable)
                                bcd_enable = 0;
                            ESTADO_ATUAL = SENHA_PIN1;
                        end
                        else if(key_code < 4'd10)begin
                            // Move unidade atual para dezena, insere nova unidade
                            bcd_out.BCD4 = bcd_out.BCD5;
                            bcd_out.BCD5 = key_code;

                            // Atualiza valor a partir dos dois dígitos
                            dezena = bcd_out.BCD4;
                            unidade = bcd_out.BCD5;
                            valor = (dezena * 10) + unidade;

                            // Limita entre 5 e 60
                            if (valor > 60)
                                valor = 60;
                            else if (valor < 5)
                                valor = 5;

                            // Atualiza valor armazenado
                            data_setup_new.tranca_aut_time = valor[6:0];
                        end
                    end else begin
                        if(!bcd_enable)
                            bcd_enable <= 1;
                    end
                end

                SENHA_PIN1:begin
                    if(key_valid)begin
                        if(key_code == 4'hF)begin
                            update_bcd(4'd0, 4'd5, 4'hF, 4'hF, 4'hF, data_setup_new.pin2.status, bcd_out);
                            
                            while(key_valid);

                            if(bcd_enable)
                                bcd_enable = 0;
                            ESTADO_ATUAL = ATIVAR_PIN2;
                        end
                        else if(key_code < 4'd10)begin
                            shift_digits(data_setup_new.pin1.digit1,
                                         data_setup_new.pin1.digit2,
                                         data_setup_new.pin1.digit3,
                                         data_setup_new.pin1.digit4,
                                         key_code, bcd_out);
                        
                        end
                    end else begin
                        if(!bcd_enable)
                            bcd_enable <= 1;
                    end
                end

                ATIVAR_PIN2:begin
                    if(key_valid)begin
                        if(key_code == 4'hF)begin
                            update_bcd(4'd0, 4'd6, data_setup_new.pin2.digit1,
                                                   data_setup_new.pin2.digit2,
                                                   data_setup_new.pin2.digit3,
                                                   data_setup_new.pin2.digit4,
                                                   bcd_out);
                           
                            while(key_valid);

                            if(bcd_enable)
                                bcd_enable = 0;
                            ESTADO_ATUAL = SENHA_PIN2;
                        end
                        else if(key_code < 4'd2)begin
                            data_setup_new.pin2.status <= |key_code;
                        end
                    end
                    else begin
                        if(bcd_enable)
                            bcd_enable <= 1;
                    end
                end

                SENHA_PIN2:begin
                    if(key_valid)
                        if(key_code == 4'hF)begin
                            update_bcd(4'd0, 4'd7, 4'hF, 4'hF, 4'hF, data_setup_new.pin3.status, bcd_out);
                            
                            while(key_valid);

                            if(bcd_enable)
                                bcd_enable = 0;
                            ESTADO_ATUAL = ATIVAR_PIN3;
                        end
                        else if(key_code < 4'd10)begin
                            shift_digits(data_setup_new.pin2.digit1,
                                         data_setup_new.pin2.digit2,
                                         data_setup_new.pin2.digit3,
                                         data_setup_new.pin2.digit4,
                                         key_code, bcd_out);
                        end
                    else begin
                        if(!bcd_enable)
                            bcd_enable <= 1;
                    end
                end

                ATIVAR_PIN3:begin
                    if(key_valid)
                        if(key_code == 4'hF)begin
                            update_bcd(4'd0, 4'd8, data_setup_new.pin3.digit1,
                                                   data_setup_new.pin3.digit2,
                                                   data_setup_new.pin3.digit3,
                                                   data_setup_new.pin3.digit4,
                                                   bcd_out);
                           
                            while(key_valid);

                            if(bcd_enable)
                                bcd_enable = 0;
                            ESTADO_ATUAL = SENHA_PIN3;
                        end
                        else if(key_code < 4'd2)begin
                            data_setup_new.pin3.status <= |key_code;
                        end
                    else begin
                        if(!bcd_enable)
                            bcd_enable <= 1;
                    end
                end

                SENHA_PIN3:begin
                    if(key_valid)
                        if(key_code == 4'hF)begin
                            update_bcd(4'd0, 4'd9, 4'hF, 4'hF, 4'hF, data_setup_new.pin4.status, bcd_out);
                            
                            while(key_valid);

                            if(bcd_enable)
                                bcd_enable <= 0;
                            ESTADO_ATUAL <= ATIVAR_PIN4;
                        end
                        else if(key_code < 4'd10)begin
                            shift_digits(data_setup_new.pin3.digit1,
                                         data_setup_new.pin3.digit2,
                                         data_setup_new.pin3.digit3,
                                         data_setup_new.pin3.digit4,
                                         key_code, bcd_out);
                        end
                    else begin
                        if(!bcd_enable)
                            bcd_enable <= 1;
                        
                    end
                end

                ATIVAR_PIN4: begin
                    if(key_valid)
                        if(key_code == 4'hF)begin
                            update_bcd(4'd1, 4'd0, data_setup_new.pin4.digit1,
                                                   data_setup_new.pin4.digit2,
                                                   data_setup_new.pin4.digit3,
                                                   data_setup_new.pin4.digit4,
                                                   bcd_out);
                            
                            while(key_valid);

                            if(bcd_enable)
                                bcd_enable = 0;
                            ESTADO_ATUAL = SENHA_PIN4;
                        end
                        else if(key_code < 4'd2)begin
                            data_setup_new.pin4.status <= |key_code;
                        end
                    else begin
                        if(!bcd_enable)
                            bcd_enable <= 1;
                    end
                end

                SENHA_PIN4:begin
                    if(key_valid)
                        if(key_code == 4'hF)begin
                            update_bcd( 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, 4'hF, bcd_out);

                            if(bcd_enable)
                                bcd_enable = 0;
                            ESTADO_ATUAL = GERAR_DATA_SETUP_NEW;
                        end
                        else if(key_code < 4'd10)begin
                            shift_digits(data_setup_new.pin4.digit1,
                                         data_setup_new.pin4.digit2,
                                         data_setup_new.pin4.digit3,
                                         data_setup_new.pin4.digit4,
                                         key_code, bcd_out);
                        end
                    else begin
                        if(!bcd_enable)
                            bcd_enable <= 1;
                    end
                end

                GERAR_DATA_SETUP_NEW:begin
                    if(setup_end)
                        setup_end = 0;
                    ESTADO_ATUAL <= BAIXAR_SETUP_END;
                end

                BAIXAR_SETUP_END:begin
                    if(!setup_end)
                        ESTADO_ATUAL <= ESPERAR_SETUP_ON;
                end

                ESPERAR_SETUP_ON:begin
                    if (!setup_on) begin
                        if(!setup_end)
                            setup_end = 1;
                        ESTADO_ATUAL <= LEVANTAR_SETUP_END;
                    end
                end

                LEVANTAR_SETUP_END:begin
                    if(setup_end)
                        ESTADO_ATUAL <= IDLE;
                end
            endcase
        end
    end
endmodule;
