typedef struct packed {
    logic [3:0] BCD0;
    logic [3:0] BCD1;
    logic [3:0] BCD2;
    logic [3:0] BCD3;
    logic [3:0] BCD4;
    logic [3:0] BCD5;
} bcdPac_t;

module SixDigit7SegCtrl (
    input  logic clk, 
    input  logic rst,
    input  logic enable,
    input  bcdPac_t bcd_packet,
    output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);

  function logic [6:0] bcd_to_7seg(input logic [3:0] hex);
    case (hex)
      4'h0: bcd_to_7seg = 7'b1000000;
      4'h1: bcd_to_7seg = 7'b1111001;
      4'h2: bcd_to_7seg = 7'b1011011;
      4'h3: bcd_to_7seg = 7'b0110000;
      4'h4: bcd_to_7seg = 7'b0011001;
      4'h5: bcd_to_7seg = 7'b0010010;
      4'h6: bcd_to_7seg = 7'b0000010;
      4'h7: bcd_to_7seg = 7'b1111000;
      4'h8: bcd_to_7seg = 7'b0000000;
      4'h9: bcd_to_7seg = 7'b0011000;
      4'hA: bcd_to_7seg = 7'b1111110;
      4'hB: bcd_to_7seg = 7'b0000011;
      4'hC: bcd_to_7seg = 7'b1000110;
      4'hD: bcd_to_7seg = 7'b0100001;
      4'hE: bcd_to_7seg = 7'b0000110;
      4'hF: bcd_to_7seg = 7'b1111111;
    endcase
  endfunction

  // Atualiza os displays apenas se enable estiver ativo
  always_comb begin
    if (enable) begin
      HEX0 = bcd_to_7seg(bcd_packet.BCD0);
      HEX1 = bcd_to_7seg(bcd_packet.BCD1);
      HEX2 = bcd_to_7seg(bcd_packet.BCD2);
      HEX3 = bcd_to_7seg(bcd_packet.BCD3);
      HEX4 = bcd_to_7seg(bcd_packet.BCD4);
      HEX5 = bcd_to_7seg(bcd_packet.BCD5);
    end
  end

endmodule