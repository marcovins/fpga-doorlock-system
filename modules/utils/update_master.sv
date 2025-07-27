module update_master (
    input logic	      clk,
    input logic 	    rst,
    input logic		    enable,
    input pinPac_t		pin_in,
    output pinPac_t 	new_master_pin
);

  typedef enum {
    INICIAL,
    ATUALIZAR,
    TEMP,
    FINAL
  } estado;
  
  estado ESTADO_ATUAL;
  
  always_ff @(posedge clk or posedge rst) begin
    if (rst)begin
      ESTADO_ATUAL <= INICIAL;
      new_master_pin.status <= 0;
    end
    else begin
      case (ESTADO_ATUAL)
        
        INICIAL: begin
          if (enable)
            ESTADO_ATUAL <= ATUALIZAR;
        end
        
        ATUALIZAR: begin
          if (pin_in.status)begin
            
            // Primeiro copia os valores
            new_master_pin.digit1 = (pin_in.digit1 == 4'b1110) ? 4'b0000 : pin_in.digit1;
            new_master_pin.digit2 = (pin_in.digit2 == 4'b1110) ? 4'b0000 : pin_in.digit2;
            new_master_pin.digit3 = (pin_in.digit3 == 4'b1110) ? 4'b0000 : pin_in.digit3;
            new_master_pin.digit4 = (pin_in.digit4 == 4'b1110) ? 4'b0000 : pin_in.digit4;

            // Verificando se os valores já foram copiados para subir o status para true
            if (new_master_pin.digit1 == pin_in.digit1 || new_master_pin.digit1 == 4'b0000 &&
                new_master_pin.digit2 == pin_in.digit2 || new_master_pin.digit2 == 4'b0000 &&
                new_master_pin.digit3 == pin_in.digit3 || new_master_pin.digit3 == 4'b0000 &&
                new_master_pin.digit4 == pin_in.digit4 || new_master_pin.digit4 == 4'b0000) begin
                new_master_pin.status <= 1;
                ESTADO_ATUAL <= TEMP;
            end
          end
        end
        
        TEMP: begin
          if(!enable)
            ESTADO_ATUAL <= FINAL;
        end
      endcase
    end
  end
endmodule