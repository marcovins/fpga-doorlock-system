`timescale 1ns/1ps

module tb_matrix;

  // Sinais para matrixKeyDecoder
  logic clk, reset;
  logic [3:0] col_matrix;
  logic [3:0] lin_matrix;
  logic [3:0] tecla_value;
  logic tecla_valid;

  // Sinais para SixDigit7SegCtrl
  logic rst7seg, enable7seg;
  bcdPac_t bcd_packet;
  logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

  // Instancia matrixKeyDecoder
  matrixKeyDecoder uut_matrix (
    .clk(clk),
    .reset(reset),
    .col_matrix(col_matrix),
    .lin_matrix(lin_matrix),
    .tecla_value(tecla_value),
    .tecla_valid(tecla_valid)
  );

  // Instancia SixDigit7SegCtrl
  SixDigit7SegCtrl uut_7seg (
    .clk(clk),
    .rst(rst7seg),
    .enable(enable7seg),
    .bcd_packet(bcd_packet),
    .HEX0(HEX0),
    .HEX1(HEX1),
    .HEX2(HEX2),
    .HEX3(HEX3),
    .HEX4(HEX4),
    .HEX5(HEX5)
  );

  // Clock
  initial clk = 0;
  always #5 clk = ~clk;

  initial begin
    // Inicialização
    reset = 1;
    rst7seg = 1;
    enable7seg = 1;
    col_matrix = 4'b1111;
    bcd_packet = '{default:4'd0};

    #20;
    reset = 0;
    rst7seg = 0;

    // Simula pressionamento de teclas na matriz
    // Exemplo: Pressiona coluna 0 (linha será varrida pelo decoder)
    repeat (4) begin
      @(posedge clk);
      col_matrix = 4'b1110; // coluna 0 pressionada
      @(posedge clk);
      col_matrix = 4'b1111; // libera
      #20;
    end

    // Atualiza bcd_packet para mostrar tecla_value nos displays
    @(posedge clk);
    bcd_packet.BCD0 = tecla_value;
    bcd_packet.BCD1 = tecla_value + 1;
    bcd_packet.BCD2 = tecla_value + 2;
    bcd_packet.BCD3 = tecla_value + 3;
    bcd_packet.BCD4 = tecla_value + 4;
    bcd_packet.BCD5 = tecla_value + 5;

    // Aguarda e finaliza
    #100;
    $finish;
  end

  // Monitor
  initial begin
    $monitor("t=%0t | col_matrix=%b | lin_matrix=%b | tecla_value=%d | tecla_valid=%b | HEX0=%b",
      $time, col_matrix, lin_matrix, tecla_value, tecla_valid, HEX0);
  end

endmodule