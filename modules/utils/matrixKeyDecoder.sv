module matrixKeyDecoder (
  input  logic clk, reset,
  input  logic [3:0] col_matrix,
  output logic [3:0] lin_matrix,
  output logic [3:0] tecla_value,
  output logic tecla_valid
);

  typedef enum logic [1:0] {
    STATE_IDLE,
    STATE_DEBOUNCE,
    STATE_ACTIVE,
    STATE_WAIT_RELEASE
  } state_t;

  state_t state;
  int debounce_cnt;
  localparam int DEBOUNCE_MAX = 50;

  logic [1:0] current_row;
  logic [3:0] active_cols;
  logic one_pressed;

  assign active_cols = ~col_matrix;
  assign one_pressed = ($countones(active_cols) == 1);

  // Codifica (linha, coluna) para número
  function logic [3:0] matrix_to_number(input logic [5:0] code);
    case (code)
      6'b000001: matrix_to_number = 4'd1;
      6'b000010: matrix_to_number = 4'd2;
      6'b000100: matrix_to_number = 4'd3;
      6'b001000: matrix_to_number = 4'd10;
      6'b010001: matrix_to_number = 4'd4;
      6'b010010: matrix_to_number = 4'd5;
      6'b010100: matrix_to_number = 4'd6;
      6'b011000: matrix_to_number = 4'd11;
      6'b100001: matrix_to_number = 4'd7;
      6'b100010: matrix_to_number = 4'd8;
      6'b100100: matrix_to_number = 4'd9;
      6'b101000: matrix_to_number = 4'd12;
      6'b110001: matrix_to_number = 4'd14;
      6'b110010: matrix_to_number = 4'd0;
      6'b110100: matrix_to_number = 4'd15;
      6'b111000: matrix_to_number = 4'd13;
      default:   matrix_to_number = 4'd0;
    endcase
  endfunction

  // Controle das linhas do teclado
  always_comb begin
    lin_matrix = 4'b1111;
    lin_matrix[current_row] = 1'b0;
  end

  // FSM + varredura de linha
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      state       <= STATE_IDLE;
      debounce_cnt<= 0;
      tecla_valid   <= 0;
      tecla_value   <= 0;
      current_row <= 0;
    end else begin
      // Scan de linhas
      if (state != STATE_DEBOUNCE) begin
        if (current_row == 2'b11)
          current_row <= 2'b00;
        else
          current_row <= current_row + 1;
      end

      case (state)
        STATE_IDLE: begin
          debounce_cnt <= 0;
          tecla_valid <= 0;
          if (one_pressed)
            state <= STATE_DEBOUNCE;
        end

        STATE_DEBOUNCE: begin
          if (one_pressed) begin
            debounce_cnt <= debounce_cnt + 1;
            if (debounce_cnt >= DEBOUNCE_MAX)
              state <= STATE_ACTIVE;
          end else begin
            state <= STATE_IDLE;
          end
        end

        STATE_ACTIVE: begin
          tecla_valid <= 1;
          tecla_value <= matrix_to_number({current_row, active_cols});
          state <= STATE_WAIT_RELEASE;
        end

        STATE_WAIT_RELEASE: begin
          if (!one_pressed) begin
            tecla_valid <= 0;
            state <= STATE_IDLE;
          end
        end
      endcase
    end
  end

endmodule