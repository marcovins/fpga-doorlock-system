`timescale 1ns/1ps

module setup_tb;

    // Sinais de entrada/saída
    logic clk;
    logic rst;
    logic key_valid;
    logic [3:0] key_code;
    bcdPac_t bcd_out;
    logic bcd_enable;
    setupPac_t data_setup_new;
    setupPac_t data_setup_old;
    logic setup_on;
    logic setup_end;

    // Instancia o DUT
    setup dut (
        .clk(clk),
        .rst(rst),
        .key_valid(key_valid),
        .key_code(key_code),
        .bcd_out(bcd_out),
        .bcd_enable(bcd_enable),
        .data_setup_new(data_setup_new),
        .data_setup_old(data_setup_old),
        .setup_on(setup_on),
        .setup_end(setup_end)
    );

    // Clock 10ns (100 MHz)
    always #5 clk = ~clk;

    // Procedimento de simulação
    initial begin
        $display("Iniciando simulação...");
        $dumpfile("setup_tb.vcd");  // Para waveform
        $dumpvars(0, setup_tb);

        // Inicializa sinais
        clk = 0;
        rst = 1;
        key_valid = 0;
        key_code = 4'd0;
        setup_on = 0;
        data_setup_old = '{default:0};

        // Aplica reset
        #10 rst = 0;

        // Ativa o setup
        #10 setup_on = 1;

        // Espera DUT ler o setup_on
        #20;

        // Simula entrada para ativar o bip (digita '1')
        send_key(4'd1); // ativa o bip
        send_key(4'hF); // confirma e vai pro tempo do bip

        // Envia valor 23 para bip_time
        send_key(4'd2);
        send_key(4'd3);
        send_key(4'hF);

        // Envia valor 15 para tranca_aut_time
        send_key(4'd1);
        send_key(4'd5);
        send_key(4'hF);

        // Define PIN1 como 1234
        send_key(4'd1);
        send_key(4'd2);
        send_key(4'd3);
        send_key(4'd4);
        send_key(4'hF); // segue para ativar PIN2

        // Define PIN2 ativado
        send_key(4'd1);
        send_key(4'hF);

        // Define PIN2 como 5678
        send_key(4'd5);
        send_key(4'd6);
        send_key(4'd7);
        send_key(4'd8);
        send_key(4'hF);

        // Define PIN3 ativado
        send_key(4'd1);
        send_key(4'hF);

        // Define PIN3 como 9012
        send_key(4'd9);
        send_key(4'd0);
        send_key(4'd1);
        send_key(4'd2);
        send_key(4'hF);

        // Define PIN4 ativado
        send_key(4'd1);
        send_key(4'hF);

        // Define PIN4 como 3456
        send_key(4'd3);
        send_key(4'd4);
        send_key(4'd5);
        send_key(4'd6);
        send_key(4'hF);

        // Desativa setup_on para encerrar processo
        #20 setup_on = 0;

        // Aguarda DUT finalizar
        #100;

        // Checa se valores foram configurados
        $display("PIN1: %0d%0d%0d%0d", data_setup_new.pin1.digit1, data_setup_new.pin1.digit2, data_setup_new.pin1.digit3, data_setup_new.pin1.digit4);
        $display("BIP TIME: %0d", data_setup_new.bip_time);
        $display("TRANCA TIME: %0d", data_setup_new.tranca_aut_time);

        $finish;
    end
  
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
  
    // Monitor para depuração em tempo real
    // ------------------------------------------------------
    initial begin
      $monitor("T=%0t | key_code=%h key_valid=%b | ativar_bip=%b | bip_time=%d | tranca_time=%d | pin1=[%b %0d %0d %0d %0d] | pin2=[%b %0d %0d %0d %0d] | pin3=[%b %0d %0d %0d %0d] | pin4=[%b %0d %0d %0d %0d] | BCD=[%0d %0d %0d %0d %0d %0d] | estado=%s",
            $time, key_code, key_valid, dut.data_setup_new.bip_status, dut.data_setup_new.bip_time, dut.data_setup_new.tranca_aut_time,
            dut.data_setup_new.pin1.status,
            dut.data_setup_new.pin1.digit1,
            dut.data_setup_new.pin1.digit2,
            dut.data_setup_new.pin1.digit3,
            dut.data_setup_new.pin1.digit4,
            dut.data_setup_new.pin2.status,
            dut.data_setup_new.pin2.digit1,
            dut.data_setup_new.pin2.digit2,
            dut.data_setup_new.pin2.digit3,
            dut.data_setup_new.pin2.digit4,
            dut.data_setup_new.pin3.status,
            dut.data_setup_new.pin3.digit1,
            dut.data_setup_new.pin3.digit2,
            dut.data_setup_new.pin3.digit3,
            dut.data_setup_new.pin3.digit4,
            dut.data_setup_new.pin4.status,
            dut.data_setup_new.pin4.digit1,
            dut.data_setup_new.pin4.digit2,
            dut.data_setup_new.pin4.digit3,
            dut.data_setup_new.pin4.digit4,
            dut.bcd_out.BCD0,
            dut.bcd_out.BCD1,
            dut.bcd_out.BCD2,
            dut.bcd_out.BCD3,
            dut.bcd_out.BCD4,
            dut.bcd_out.BCD5,
            dut.ESTADO_ATUAL.name()
        );
    end
  

endmodule
