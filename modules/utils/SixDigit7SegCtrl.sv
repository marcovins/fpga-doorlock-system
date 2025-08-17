// SIX DIGIT
module SixDigit7SegCtrl (
    input logic clk, 
    input logic rst,
    input logic enable,
    input bcdPac_t bcd_packet,
    output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5
);
    bcdPac_t bcd_reg;

    // Registra o valor do pacote BCD quando habilitado
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            bcd_reg <= '{default: 4'hB}; // Apaga todos os displays
        end else if (enable) begin
            bcd_reg <= bcd_packet;
        end
    end
    
    // Instancia um conversor para cada um dos 6 displays
    BCDto7SEGMENT conv0 (.bcd(bcd_reg.BCD0), .Seg(HEX0));
    BCDto7SEGMENT conv1 (.bcd(bcd_reg.BCD1), .Seg(HEX1));
    BCDto7SEGMENT conv2 (.bcd(bcd_reg.BCD2), .Seg(HEX2));
    BCDto7SEGMENT conv3 (.bcd(bcd_reg.BCD3), .Seg(HEX3));
    BCDto7SEGMENT conv4 (.bcd(bcd_reg.BCD4), .Seg(HEX4));
    BCDto7SEGMENT conv5 (.bcd(bcd_reg.BCD5), .Seg(HEX5));
endmodule