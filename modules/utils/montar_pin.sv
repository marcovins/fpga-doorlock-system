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

module montar_pin (
    input  logic      clk,
    input  logic      rst,
    input  logic      key_valid,
    input  logic [3:0] key_code,
    output pinPac_t   pin_out
);

  typedef enum logic [2:0] {
        INICIAL,
        DIGITO_LIDO,
        STATUS_TRUE,
        HOLD_STATUS,
        TEMP
    } estado_t;

    estado_t ESTADO_ATUAL;

    logic key_valid_d, key_valid_rise;
    logic pin_complete;

    assign pin_complete = (pin_out.digit1 != 4'b1110) &&
                          (pin_out.digit2 != 4'b1110) &&
                          (pin_out.digit3 != 4'b1110) &&
                          (pin_out.digit4 != 4'b1110);

    assign key_valid_rise = key_valid && !key_valid_d;

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin
            ESTADO_ATUAL <= INICIAL;
            pin_out.digit1 <= 4'b1110;
            pin_out.digit2 <= 4'b1110;
            pin_out.digit3 <= 4'b1110;
            pin_out.digit4 <= 4'b1110;
            pin_out.status <= 1'b0;
            key_valid_d <= 1'b0;

        end else begin
 
            key_valid_d <= key_valid;

            case (ESTADO_ATUAL)
                INICIAL: begin
                    pin_out.status <= 1'b0;
                    if (key_valid_rise && key_code < 4'b1010) begin
                        pin_out.digit4 <= pin_out.digit3;
                        pin_out.digit3 <= pin_out.digit2;
                        pin_out.digit2 <= pin_out.digit1;
                        pin_out.digit1 <= key_code;
                        ESTADO_ATUAL <= DIGITO_LIDO;
                    end
                end

                DIGITO_LIDO: begin
                    if (key_valid_rise && key_code == 4'hF && pin_complete) begin
                        ESTADO_ATUAL <= STATUS_TRUE;
                    end else if (key_valid_rise && key_code < 4'b1010) begin
                        pin_out.digit4 <= pin_out.digit3;
                        pin_out.digit3 <= pin_out.digit2;
                        pin_out.digit2 <= pin_out.digit1;
                        pin_out.digit1 <= key_code;
                    end
                end

                STATUS_TRUE: begin
                    pin_out.status <= 1'b1;
                    ESTADO_ATUAL <= HOLD_STATUS;
                end

                HOLD_STATUS: begin
                    pin_out.status <= 1'b1;
                    ESTADO_ATUAL <= TEMP;
                end

                TEMP: begin
                    if (pin_out.status) begin
                        pin_out.status <= 1'b0;
                    end else begin
                        pin_out.digit1 <= 4'b1110;
                        pin_out.digit2 <= 4'b1110;
                        pin_out.digit3 <= 4'b1110;
                        pin_out.digit4 <= 4'b1110;
                        ESTADO_ATUAL <= INICIAL;
                    end
                end

            endcase
        end
    end
endmodule