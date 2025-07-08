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

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            ESTADO_ATUAL <= INICIAL;
            pin_out.digit1 <= 4'b1111;
            pin_out.digit2 <= 4'b1111;
            pin_out.digit3 <= 4'b1111;
            pin_out.digit4 <= 4'b1111;
            pin_out.status <= 1'b0;
        end else begin
            case (ESTADO_ATUAL)
                INICIAL: begin
                    pin_out.status <= 1'b0;
                    if (key_valid && key_code == 4'hF) begin
                        ESTADO_ATUAL <= STATUS_TRUE;
                    end else if (key_valid) begin
                        ESTADO_ATUAL <= DIGITO_LIDO;
                      	pin_out.digit1 <= pin_out.digit2;
                      	pin_out.digit2 <= pin_out.digit3;
                      	pin_out.digit3 <= pin_out.digit4;
                      	pin_out.digit4 <= key_code;
                    end
                end

                DIGITO_LIDO: begin
                    if (key_code == 4'hF) begin
                        ESTADO_ATUAL <= STATUS_TRUE;
                    end else if (key_valid) begin
                        pin_out.digit1 <= pin_out.digit2;
                      	pin_out.digit2 <= pin_out.digit3;
                      	pin_out.digit3 <= pin_out.digit4;
                      	pin_out.digit4 <= key_code;
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
                        pin_out.digit1 <= 4'b1111;
                        pin_out.digit2 <= 4'b1111;
                        pin_out.digit3 <= 4'b1111;
                        pin_out.digit4 <= 4'b1111;
                        ESTADO_ATUAL <= INICIAL;
                    end
                end

            endcase
        end
    end

endmodule