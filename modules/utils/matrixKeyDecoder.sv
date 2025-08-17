// MATRIX DECODER
module matrixKeyDecoder (
    input clk, reset,
    input logic [3:0] col_matrix, // Leitura das colunas
    output logic [3:0] lin_matrix, // Ativação das linhas
    output logic [3:0] tecla_value,
    output logic tecla_valid
);
    localparam DEBOUNCE_TIME = 25; 

    typedef enum {IDLE, SET_ROW, WAIT_STABILIZE, READ_COLS, DEBOUNCE, HOLD_KEY} state_t;
    state_t state;
    
    logic [3:0] lin_reg;
    logic [3:0] key_code_reg;
    logic [1:0] row_scan_counter;
    logic [31:0] debounce_counter;

    assign lin_matrix = lin_reg;
    assign tecla_value = key_code_reg;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            row_scan_counter <= 0;
            debounce_counter <= 0;
            tecla_valid <= 0;
            lin_reg <= 4'b1111;
            key_code_reg <= 4'hA;
        end else begin
            tecla_valid <= 0;

            case(state)
                IDLE: begin
                    row_scan_counter <= 0;
                    state <= SET_ROW;
                end

                SET_ROW: begin
                    case(row_scan_counter)
                        2'b00: lin_reg <= 4'b1110; 2'b01: lin_reg <= 4'b1101;
                        2'b10: lin_reg <= 4'b1011; 2'b11: lin_reg <= 4'b0111;
                    endcase
                    state <= WAIT_STABILIZE;
                end

                WAIT_STABILIZE: state <= READ_COLS;

                READ_COLS: begin
                    if (col_matrix != 4'b1111) begin
                        debounce_counter <= 0;
                        state <= DEBOUNCE;
                    end else begin
                        row_scan_counter <= (row_scan_counter == 3) ? 0 : row_scan_counter + 1;
                        state <= SET_ROW;
                    end
                end

                DEBOUNCE: begin
                    if (col_matrix != 4'b1111) begin
                        if (debounce_counter < DEBOUNCE_TIME) begin
                            debounce_counter <= debounce_counter + 1;
                        end else begin
                            case(row_scan_counter)
                                2'b00: case(col_matrix)
                                    4'b1110: key_code_reg <= 4'hD;// 
                                    4'b1101: key_code_reg <= 4'hE;// 
                                    4'b1011: key_code_reg <= 4'h0;//
                                    4'b0111: key_code_reg <= 4'hF;// 
                                    default: key_code_reg <= 4'hA;
                                endcase
                                
                                // Linha 1 (teclas 7, 8, 9, C)
                                2'b01: case(col_matrix)
                                    4'b1110: key_code_reg <= 4'hC;//
                                    4'b1101: key_code_reg <= 4'h9;// 
                                    4'b1011: key_code_reg <= 4'h8;// 
                                    4'b0111: key_code_reg <= 4'h7;//
                                    default: key_code_reg <= 4'hA;
                                endcase
                                
                                // Linha 2 (teclas 4, 5, 6, B)
                                2'b10: case(col_matrix)
                                    4'b1110: key_code_reg <= 4'hB;// 
                                    4'b1101: key_code_reg <= 4'h6;// 
                                    4'b1011: key_code_reg <= 4'h5;// 
                                    4'b0111: key_code_reg <= 4'h4;// 
                                    default: key_code_reg <= 4'hA;
                                endcase
                                
                                // Linha 3 (teclas 1, 2, 3, A)
                                2'b11: case(col_matrix)
                                    4'b1110: key_code_reg <= 4'hA; // 
                                    4'b1101: key_code_reg <= 4'h3; //
                                    4'b1011: key_code_reg <= 4'h2; //
                                    4'b0111: key_code_reg <= 4'h1; //
                                    default: key_code_reg <= 4'hA;
                                endcase
                            endcase
                            
                            tecla_valid <= 1;
                            state <= HOLD_KEY;
                        end
                    end else begin
                        state <= READ_COLS;
                    end
                end
                
                HOLD_KEY: begin
                    if (col_matrix == 4'b1111) begin
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule