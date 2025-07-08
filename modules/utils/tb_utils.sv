`timescale 1ns/1ps

module tb_integrado;

    // ------------------------------------------------------
    // Tipos de dados
    // ------------------------------------------------------
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

    // ------------------------------------------------------
    // Sinais do Testbench
    // ------------------------------------------------------
    logic clk, rst;
    logic key_valid;
    logic [3:0] key_code;

    pinPac_t pin_from_montar;
    setupPac_t data_setup;

    logic senha_fail, senha_padrao, senha_pin, senha_master, senha_master_update;
    pinPac_t master_pin_temp;

    // ------------------------------------------------------
    // Clock 10ns (100 MHz)
    // ------------------------------------------------------
    always #5 clk = ~clk;

    // ------------------------------------------------------
    // Instâncias dos módulos
    // ------------------------------------------------------
    montar_pin u_montar_pin (
        .clk(clk),
        .rst(rst),
        .key_valid(key_valid),
        .key_code(key_code),
        .pin_out(pin_from_montar)
    );

    verificar_senha u_verificar (
        .clk(clk),
        .rst(rst),
        .pin_in(pin_from_montar),
        .data_setup(data_setup),
        .senha_fail(senha_fail),
        .senha_padrao(senha_padrao),
        .senha_pin(senha_pin),
        .senha_master(senha_master),
        .senha_master_update(senha_master_update)
    );

    update_master u_update_master (
        .clk(clk),
        .rst(rst),
        .enable(senha_master),
        .pin_in(pin_from_montar),
        .new_master_pin(master_pin_temp)
    );

    // ------------------------------------------------------
    // Atualização do master_pin com ou sem reset
    // ------------------------------------------------------
    always_comb begin
        if (rst) begin
            data_setup.master_pin = '{0, 4'd1, 4'd2, 4'd3, 4'd4}; // PIN padrão
        end else begin
            data_setup.master_pin = master_pin_temp;
        end
    end

    // ------------------------------------------------------
    // Inicialização e Estímulos
    // ------------------------------------------------------
    initial begin
        clk = 0;
        rst = 1;
        key_valid = 0;
        key_code = 4'b0000;

        // Configuração inicial dos PINs
        data_setup.pin1 = '{1, 5, 4, 3, 1};
        data_setup.pin2 = '{0, 0, 0, 0, 0};
        data_setup.pin3 = '{1, 0, 0, 8, 9};
        data_setup.pin4 = '{0, 0, 0, 0, 0};
        data_setup.bip_status = 0;
        data_setup.bip_time = 0;
        data_setup.tranca_aut_time = 0;

        #20 rst = 0;
        #20;

        // ------------------------------
        $display("========================================");
        $display(">> Teste 1: PIN MASTER PADRÃO + F");
        $display("========================================");
        send_key(4'd1);
        send_key(4'd2);
        send_key(4'd3);
        send_key(4'd4);
        #20 send_key(4'hF);

        #100;

        // ------------------------------
        $display("========================================");
        $display(">> Teste 2: NOVO MASTER PIN (6,5,7,0 + F)");
        $display("========================================");
        send_key(4'd6);
        send_key(4'd5);
        send_key(4'd7);
        send_key(4'd0);
        #20 send_key(4'hF);

        #100;

        // ------------------------------
        $display("========================================");
        $display(">> Teste 3: PIN PADRÃO 1 (5,4,3,1 + F)");
        $display("========================================");
        send_key(4'd5);
        send_key(4'd4);
        send_key(4'd3);
        send_key(4'd1);
        #20 send_key(4'hF);

        #100;

        // ------------------------------
        $display("========================================");
        $display(">> Teste 4: PIN DESATIVADO 2 (0,0,0,0 + F)");
        $display("========================================");
        send_key(4'd0);
        send_key(4'd0);
        send_key(4'd0);
        send_key(4'd0);
        #20 send_key(4'hF);

        #100;

        // ------------------------------
        $display("========================================");
        $display(">> Teste 5: PIN INCOMPLETO 3 (8,9 + F)");
        $display("========================================");
        send_key(4'd8);
        send_key(4'd9);
        #20 send_key(4'hF);

        #100;

        // ------------------------------
        $display("========================================");
        $display(">> Teste Finalizado");
        $display(">> Novo master PIN salvo: status=%b digits=%0d %0d %0d %0d",
                 data_setup.master_pin.status,
                 data_setup.master_pin.digit1,
                 data_setup.master_pin.digit2,
                 data_setup.master_pin.digit3,
                 data_setup.master_pin.digit4);
        $display("========================================");

        $stop;
    end

    // ------------------------------------------------------
    // Tarefa: Envia uma tecla com sincronismo de clock
    // ------------------------------------------------------
    task send_key(input logic [3:0] key);
        begin
            @(negedge clk);
            key_code = key;
            key_valid = 1;
            @(negedge clk);
            key_valid = 0;
            @(negedge clk);
            key_code = 0;
        end
    endtask

    // ------------------------------------------------------
    // Monitor para depuração em tempo real
    // ------------------------------------------------------
    initial begin
        $monitor("T=%0t | key_code=%h key_valid=%b | senha_padrao=%b | senha_pin=%b | senha_fail=%b | pin_out=[%b %0d %0d %0d %0d] | senha_master=%b | senha_update=%b | estados: update=%s verificar=%s montar=%s",
            $time, key_code, key_valid, senha_padrao, senha_pin, senha_fail,
            pin_from_montar.status,
            pin_from_montar.digit1,
            pin_from_montar.digit2,
            pin_from_montar.digit3,
            pin_from_montar.digit4,
            senha_master,
            senha_master_update,
            u_update_master.ESTADO_ATUAL.name(),
            u_verificar.estado.name(),
            u_montar_pin.ESTADO_ATUAL.name()
        );
    end

endmodule
