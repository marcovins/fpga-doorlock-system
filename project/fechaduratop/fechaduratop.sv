// FECHADURA TOP
module FechaduraTop (
	input 	logic clk, 
	input 	logic rst, 
	input 	logic sensor_de_contato, 
	input 	logic botao_interno,
	input		logic [3:0] matricial_col,
	output	logic [3:0] matricial_lin,
	output 	logic [6:0] dispHex0, 
	output 	logic [6:0] dispHex1, 
	output 	logic [6:0] dispHex2, 
	output 	logic [6:0] dispHex3, 
	output 	logic [6:0] dispHex4, 
	output 	logic [6:0] dispHex5,
	output 	logic tranca, 
	output 	logic bip 
	);
    wire clk_1k;

	logic key_valid, setup_on, setup_end, bcd_enable, bcd_enable_setup, bcd_enable_operacional;
    logic [3:0] key_code;
    bcdPac_t bcd_out, bcd_out_setup, bcd_out_operacional;
    setupPac_t data_setup_old, data_setup_new;

    logic reset_5;

    divfreq my_divfreq(
        .reset(rst), 
        .clock(clk), 
        .clk_i(clk_1k)
    );

    operacional m_operacional (
        .clk(clk_1k),
        .rst(reset_5),
        .sensor_de_contato(sensor_de_contato),
        .botao_interno(botao_interno),
        .key_valid(key_valid),
        .key_code(key_code),
        .bcd_out(bcd_out_operacional),
        .bcd_enable(bcd_enable_operacional),
        .tranca(tranca),
        .bip(bip),
        .setup_on(setup_on),
        .setup_end(setup_end),
        .data_setup_old(data_setup_old),
        .data_setup_new(data_setup_new)
    );

    setup m_setup (
        .clk(clk_1k),
        .rst(reset_5),
        .key_valid(key_valid),
        .key_code(key_code),
        .bcd_out(bcd_out_setup),
        .bcd_enable(bcd_enable_setup),
        .data_setup_new(data_setup_new),
        .data_setup_old(data_setup_old),
        .setup_on(setup_on),
        .setup_end(setup_end)
    );

    matrixKeyDecoder m_matrix (
        .clk(clk_1k),
        .reset(reset_5),
        .col_matrix(matricial_col),
        .lin_matrix(matricial_lin),
        .tecla_value(key_code),
        .tecla_valid(key_valid)
    );

    SixDigit7SegCtrl m_sixdigit (
        .clk(clk_1k),
        .rst(reset_5),
        .enable(bcd_enable),
        .bcd_packet(bcd_out),
        .HEX0(dispHex0),
        .HEX1(dispHex1),
        .HEX2(dispHex2),
        .HEX3(dispHex3),
        .HEX4(dispHex4),
        .HEX5(dispHex5)
    );

    ResetHold5s reset_hold (
        .clk(clk),
        .reset_in(rst),
        .reset_out(reset_5)
    );

    always_comb begin
        if(setup_on)begin
            bcd_out = bcd_out_setup;
            bcd_enable = bcd_enable_setup;
        end else begin
            bcd_out = bcd_out_operacional;
            bcd_enable = bcd_enable_operacional;
        end
    end
endmodule