// RESET HOLD
module ResetHold5s #(parameter TIME_TO_RST = 5) (
    input logic clk,
    input logic reset_in, // Sinal vindo do botão físico (ativo alto)
    output logic reset_out // Saída de reset para o sistema
    ); 
    int count;

    always_ff @(posedge clk) begin
        if (reset_in) begin
            if (count < 250000000) begin 
                count <= count + 1; 
                reset_out <= 1'b0; // Mantém o reset desativado enquanto conta
            end else begin 
                reset_out <= 1'b1; // Ativa o reset após 5 segundos
            end
        end else begin 
            count <= 0;
            reset_out <= 0;
        end
    end
endmodule