`timescale 1ns/1ps

module tb_operacional;

  // Clock e Reset
  logic clk;
  logic rst;

  // Entradas
  logic sensor_de_contato;
  logic botao_interno;
  logic key_valid;
  logic [3:0] key_code;
  logic setup_end;

  // Saídas
  bcdPac_t bcd_out;
  logic bcd_enable;
  logic tranca;
  logic bip;
  logic setup_on;

  // Setup data
  setupPac_t data_setup_old;
  setupPac_t data_setup_new;

  // Clock generation
  always #5 clk = ~clk; // Clock de 100MHz

  // DUT
  operacional dut (
    .clk(clk),
    .rst(rst),
    .sensor_de_contato(sensor_de_contato),
    .botao_interno(botao_interno),
    .key_valid(key_valid),
    .key_code(key_code),
    .bcd_out(bcd_out),
    .bcd_enable(bcd_enable),
    .tranca(tranca),
    .bip(bip),
    .setup_on(setup_on),
    .setup_end(setup_end),
    .data_setup_old(data_setup_old),
    .data_setup_new(data_setup_new)
  );

  // Task para simular entrada de senha
  task digitar_senha(input logic [3:0] d1, d2, d3, d4);
    begin
      send_key(d1); #20;
      send_key(d2); #20;
      send_key(d3); #20;
      send_key(d4); #20;
      send_key(4'hF); // Finalizador da senha
    end
  endtask

  // Task para simular tecla
  task send_key(input logic [3:0] code);
    begin
      key_code = code;
      key_valid = 1;
      #10;
      key_valid = 0;
    end
  endtask

  // Estímulo principal
  initial begin
    // Inicialização
    clk = 0;
    rst = 1;
    key_valid = 0;
    sensor_de_contato = 0;
    botao_interno = 0;
    setup_end = 0;
    data_setup_new = '0;
    #20;

    rst = 0;
    sensor_de_contato = 1; // Porta fechada (sensor ativo)
    #20;

    // Digitar senha correta padrão: 1-2-3-4
    digitar_senha(4'd1, 4'd2, 4'd3, 4'd4);
    #100;

    // Simular abertura e fechamento da porta
    sensor_de_contato = 0; // Porta aberta
    #1000;
    sensor_de_contato = 1; // Porta fechada
    #100;

    // Teste botão interno para abrir a porta
    botao_interno = 1;
    #20;
    botao_interno = 0;
    #200;

    // Teste atualização de senha master
    digitar_senha(4'd1, 4'd2, 4'd3, 4'd4); // Senha padrão
    #100;

    // Digitar sequência mágica de update master (1-2-3-4 + F)
    digitar_senha(4'd1, 4'd2, 4'd3, 4'd4);
    #200;

    // Simular final do setup
    setup_end = 1;
    #20;
    setup_end = 0;

    // Encerrar simulação
    #500;
    $finish;
  end

    // Monitor
    initial begin
        $monitor("Time=%0t State=%s Tranca=%b Bip=%b Setup_on=%b Tentativas=%d",
                 $time, dut.ESTADO_ATUAL.name(), tranca, bip, setup_on, dut.tentativas);
    end

endmodule