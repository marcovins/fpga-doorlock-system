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
      send_key(4'hF); #20; // Finalizador da senha
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
    botao_interno = 0;
    setup_end = 0;
    data_setup_new = '0;
    sensor_de_contato = 1; // Porta fechada (sensor ativo)
    #20;

    rst = 0;

    // Digitar senha correta padrão: 1-2-3-4
    digitar_senha(4'd1, 4'd2, 4'd3, 4'd4);
	#20
    
    // Teste atualização de senha master
    digitar_senha(4'd5, 4'd6, 4'd7, 4'd8); // atualiza a master para 5678
    #20;
    
    digitar_senha(4'd0, 4'd0, 4'd0, 4'd0); 
    
    sensor_de_contato = 0;
    repeat (6000) @(posedge clk);  // Espera 6000 ciclos
    
    sensor_de_contato = 1;
    repeat (1000) @(posedge clk); 
    $finish;
  end

        initial begin
          $display("\n==== Monitor de Sinais Operacional====");
          $display("Formato: T=tempo | key_code | key_valid | bip_status | tranca | sensor_de_contato | master_pin | pin1..4 | BCD | Estado FSM\n");
        $monitor("T=%0t | key_code=%h key_valid=%b | bip=%b | bip_time=%0d | tranca=%0d| sensor_de_contato=%b | master_pin=[%b %0d %0d %0d %0d] | pin1=[%b %0d %0d %0d %0d] | pin2=[%b %0d %0d %0d %0d] | pin3=[%b %0d %0d %0d %0d] | pin4=[%b %0d %0d %0d %0d] | BCD=[%0d %0d %0d %0d %0d %0d] | estado=%s",
            $time,
            key_code,
            key_valid,
            dut.bip,
            dut.data_setup_old.bip_time,
            dut.tranca,
            sensor_de_contato,

            // master_pin
            dut.data_setup_old.master_pin.status,
            dut.data_setup_old.master_pin.digit1,
            dut.data_setup_old.master_pin.digit2,
            dut.data_setup_old.master_pin.digit3,
            dut.data_setup_old.master_pin.digit4,

            // pin1
            dut.data_setup_old.pin1.status,
            dut.data_setup_old.pin1.digit1,
            dut.data_setup_old.pin1.digit2,
            dut.data_setup_old.pin1.digit3,
            dut.data_setup_old.pin1.digit4,

            // pin2
            dut.data_setup_old.pin2.status,
            dut.data_setup_old.pin2.digit1,
            dut.data_setup_old.pin2.digit2,
            dut.data_setup_old.pin2.digit3,
            dut.data_setup_old.pin2.digit4,

            // pin3
            dut.data_setup_old.pin3.status,
            dut.data_setup_old.pin3.digit1,
            dut.data_setup_old.pin3.digit2,
            dut.data_setup_old.pin3.digit3,
            dut.data_setup_old.pin3.digit4,

            // pin4
            dut.data_setup_old.pin4.status,
            dut.data_setup_old.pin4.digit1,
            dut.data_setup_old.pin4.digit2,
            dut.data_setup_old.pin4.digit3,
            dut.data_setup_old.pin4.digit4,

            // BCD
            dut.bcd_out.BCD0,
            dut.bcd_out.BCD1,
            dut.bcd_out.BCD2,
            dut.bcd_out.BCD3,
            dut.bcd_out.BCD4,
            dut.bcd_out.BCD5,

            // Estado FSM
            dut.ESTADO_ATUAL.name()
        );
    end


endmodule