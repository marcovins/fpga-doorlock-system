`timescale 1ns / 1ps

module tb_FechaduraTop;

  // ---- sinais de top ----
  logic clk, rst;
  logic sensor_de_contato, botao_interno;
  logic [3:0] matricial_col;
  logic [3:0] matricial_lin;
  logic [6:0] dispHex0, dispHex1, dispHex2, dispHex3, dispHex4, dispHex5;
  logic tranca, bip;

  // Instanciação do DUT
  FechaduraTop DUT (
    .clk(clk),
    .rst(rst),
    .sensor_de_contato(sensor_de_contato),
    .botao_interno(botao_interno),
    .matricial_col(matricial_col),
    .matricial_lin(matricial_lin),
    .dispHex0(dispHex0),
    .dispHex1(dispHex1),
    .dispHex2(dispHex2),
    .dispHex3(dispHex3),
    .dispHex4(dispHex4),
    .dispHex5(dispHex5),
    .tranca(tranca),
    .bip(bip)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Função auxiliar para converter tecla para código (linha, coluna)
  function void get_matrix_pos(input logic [3:0] tecla,
                               output logic [1:0] row,
                               output logic [3:0] col_mask);
    logic [5:0] code;
    begin
      case (tecla)
        4'd1:  code = 6'b001110;
        4'd2:  code = 6'b001101;
        4'd3:  code = 6'b001011;
        4'd10: code = 6'b000111;
        
        4'd4:  code = 6'b011110;
        4'd5:  code = 6'b011101;
        4'd6:  code = 6'b011011;
        4'd11: code = 6'b010111;
        
        4'd7:  code = 6'b101110;
        4'd8:  code = 6'b101101;
        4'd9:  code = 6'b101011;
        4'd12: code = 6'b100111;
        
        4'd15: code = 6'b111110;
        4'd0:  code = 6'b111101;
        4'd13: code = 6'b111011;
        4'd14: code = 6'b110111;
        default: code = 6'b000000;
      endcase

      col_mask = code[3:0];
      row = code[5:4];
      
      $display("ativando linha=%b",row);
      $display("ativando coluna=%b",col_mask);

      
    end
  endfunction

  // Conversor 7 segmentos para BCD/hex (combinacional pura)
  // Espera os mesmos padrões da função original (ativos baixos/altos conforme definido)
  function logic [3:0] sevenseg_to_bcd(input logic [6:0] seg);
    case (seg)
      7'b1000000: sevenseg_to_bcd = 4'h0;
      7'b1111001: sevenseg_to_bcd = 4'h1;
      7'b1011011: sevenseg_to_bcd = 4'h2;
      7'b0110000: sevenseg_to_bcd = 4'h3;
      7'b0011001: sevenseg_to_bcd = 4'h4;
      7'b0010010: sevenseg_to_bcd = 4'h5;
      7'b0000010: sevenseg_to_bcd = 4'h6;
      7'b1111000: sevenseg_to_bcd = 4'h7;
      7'b0000000: sevenseg_to_bcd = 4'h8;
      7'b0011000: sevenseg_to_bcd = 4'h9;
      7'b1111110: sevenseg_to_bcd = 4'hA;
      7'b0000011: sevenseg_to_bcd = 4'hB;
      7'b1000110: sevenseg_to_bcd = 4'hC;
      7'b0100001: sevenseg_to_bcd = 4'hD;
      7'b0000110: sevenseg_to_bcd = 4'hE;
      7'b1111111: sevenseg_to_bcd = 4'hF; // conforme mapeamento original
      default:    sevenseg_to_bcd = 4'hF; // inválido / não reconhecido
    endcase
  endfunction

  // Task para pressionar tecla na matriz
  task automatic press_key(input logic [3:0] tecla);
    logic [1:0] target_row;
    logic [3:0] col_pattern;
    logic [3:0] expected_line;
    integer timeout;
    begin
      get_matrix_pos(tecla, target_row, col_pattern);
      matricial_col = 4'b1111; // nada pressionado
      expected_line = 4'b1111;
      expected_line[target_row] = 1'b0;

      timeout = 0;
      wait (matricial_lin == expected_line);
      matricial_col = col_pattern;
      repeat (30) @(posedge clk);
      matricial_col = 4'b1111;
      wait (!DUT.key_valid);
    end
  endtask

  initial begin
    $display("--- RESETANDO SISTEMA ---");
    rst = 1;
    sensor_de_contato = 0;
    botao_interno = 0;
    matricial_col = 4'b1111; // corrigido
    #20;
    rst = 0;
    #20;
    sensor_de_contato = 1;
    #20;

    $display("--- Atualizar master pin ---");
    $display("--- Teclando: 1 ---");
    press_key(4'd1);
    $display("--- Teclando: 2 ---");
    press_key(4'd2);
    $display("--- Teclando: 3 ---");
    press_key(4'd3);
    $display("--- Teclando: 4 ---");
    press_key(4'd4);
    $display("--- Teclando: * ---");
    press_key(4'hf);
    #200;
    $display("--- Teclando: 6 ---");
    press_key(4'd6);
    $display("--- Teclando: 7 ---");
    press_key(4'd7);
    $display("--- Teclando: 8 ---");
    press_key(4'd8);
    $display("--- Teclando: 9 ---");
    press_key(4'd9);
    $display("--- Teclando: * ---");
    press_key(4'hf);
    #200
    
    
    $display("=== FIM DOS TESTES ===");
    $display("master_pin=[%d %d %d %d]",
    DUT.m_operacional.data_setup_old.master_pin.digit1,
    DUT.m_operacional.data_setup_old.master_pin.digit2,
    DUT.m_operacional.data_setup_old.master_pin.digit3,
    DUT.m_operacional.data_setup_old.master_pin.digit4);

    $finish;
  end

  initial begin
    $monitor("Time=%0t | rst=%b | setup_on=%b | setup_end=%b | tranca=%b | bip=%b | key_valid=%b | key_code=%d | bcd_enable=%b | setup_state=%s | op_state=%s | matrix_state=%s | cnt_debounce=%d | displays=[%d %d %d %d %d %d] | montar_pin_state=%s | verificar_senha_state=%s | update_master_state=%s",
               $time,
               DUT.rst,
               DUT.setup_on,
               DUT.setup_end,
               DUT.tranca,
               DUT.bip,
               DUT.key_valid,
               DUT.key_code,
               DUT.bcd_enable,
               DUT.m_setup.ESTADO_ATUAL.name(),
               DUT.m_operacional.ESTADO_ATUAL.name(),
               DUT.m_matrix.state.name(),
               DUT.m_matrix.debounce_cnt,
               sevenseg_to_bcd(dispHex0),
               sevenseg_to_bcd(dispHex1),
               sevenseg_to_bcd(dispHex2),
               sevenseg_to_bcd(dispHex3),
               sevenseg_to_bcd(dispHex4),
               sevenseg_to_bcd(dispHex5),
               DUT.m_operacional.inst_montar_pin.ESTADO_ATUAL.name(),
               DUT.m_operacional.inst_verificar_senha.estado.name(),
               DUT.m_operacional.inst_update_master.ESTADO_ATUAL.name()
      );
   end

endmodule
