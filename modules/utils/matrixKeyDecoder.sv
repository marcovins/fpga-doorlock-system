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
  logic [6:0] debounce_cnt;
  localparam int DEBOUNCE_MAX = 25;

  logic [1:0] current_row;
  logic [3:0] active_cols;
  logic one_pressed;

  assign one_pressed = (($countones(~col_matrix)) == 1);

  logic [3:0] lin_temp;

  // Codifica (linha, coluna) para número
  function logic [3:0] matrix_to_number(input logic [5:0] code);
    case (code)
      6'b111110: matrix_to_number = 4'd1;
      6'b111101: matrix_to_number = 4'd2;
      6'b111011: matrix_to_number = 4'd3;
      6'b110111: matrix_to_number = 4'd10;
      6'b101110: matrix_to_number = 4'd4;
      6'b101101: matrix_to_number = 4'd5;
      6'b101011: matrix_to_number = 4'd6;
      6'b100111: matrix_to_number = 4'd11;
      6'b011110: matrix_to_number = 4'd7;
      6'b011101: matrix_to_number = 4'd8;
      6'b011011: matrix_to_number = 4'd9;
      6'b010111: matrix_to_number = 4'd12;
      6'b001110: matrix_to_number = 4'd14;
      6'b001101: matrix_to_number = 4'd0;
      6'b001011: matrix_to_number = 4'd15;
      6'b000111: matrix_to_number = 4'd13;
      default:   matrix_to_number = 4'd0;
    endcase
  endfunction

  // FSM + varredura de linha
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= STATE_IDLE;
      debounce_cnt <= 0;
      tecla_valid <= 0;
      tecla_value <= 0;
      current_row <= 0;
      lin_matrix <= 4'b1111;
    end else begin
      
      case (state)
        STATE_IDLE: begin
          lin_temp = 4'b1111;
          lin_temp[current_row] = 1'b0;
          lin_matrix <= lin_temp;
          
          if (one_pressed) begin
            debounce_cnt <= 0;
            state <= STATE_DEBOUNCE;
          end else begin
              current_row <= current_row + 1;
            end
        end

        STATE_DEBOUNCE: begin
          if (one_pressed) begin
            debounce_cnt <= debounce_cnt + 1;
            if (debounce_cnt >= DEBOUNCE_MAX)
              state <= STATE_ACTIVE;
          end else begin
            debounce_cnt <= 0;
            state <= STATE_IDLE;
          end
        end

        STATE_ACTIVE: begin
          tecla_valid <= 1;
          tecla_value <= matrix_to_number({~current_row + 1, col_matrix});
          state <= STATE_WAIT_RELEASE;
        end

        STATE_WAIT_RELEASE: begin
          if (!one_pressed) begin
            tecla_valid <= 0;
            state <= STATE_IDLE;
          end
        end

        default: state <= STATE_IDLE;
      endcase
    end
  end

endmodule