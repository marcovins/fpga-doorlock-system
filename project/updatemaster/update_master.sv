// UPDATE MASTER
module update_master (
    input  logic      clk,
    input  logic      rst,
    input  logic      enable,
    input  pinPac_t   pin_in,
    output pinPac_t   new_master_pin
);
    typedef enum logic [1:0] {
        INICIAL,
        ATUALIZAR,
        TEMP,
        FINAL
    } estado_t;

    estado_t ESTADO_ATUAL;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            ESTADO_ATUAL <= INICIAL;
            new_master_pin <= '{status: 0, digit1: 4'b0, digit2: 4'b0, digit3: 4'b0, digit4: 4'b0};
        end else begin
            case (ESTADO_ATUAL)
                INICIAL: begin
                    if (enable) begin
                        ESTADO_ATUAL <= ATUALIZAR;
                    end
                end

                ATUALIZAR: begin
                    if (pin_in.status) begin
								new_master_pin <= pin_in;
							   new_master_pin.status <= 1;
							   ESTADO_ATUAL <= TEMP;
                    end
                end

                TEMP: begin
                    if (!enable) begin
                        ESTADO_ATUAL <= FINAL;
                    end
                end
	
                FINAL: begin
                    // Estado final, mantém valores
                end
            endcase
        end
    end
endmodule