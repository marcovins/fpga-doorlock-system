// OPERACIONAL
module operacional (
	input logic clk, 
	input logic rst, 
	input logic sensor_de_contato, 
	input logic botao_interno,
	input logic key_valid,
	input logic [3:0] key_code,
	output bcdPac_t bcd_out,
	output logic bcd_enable,
	output logic tranca,
	output logic bip,
	output logic setup_on,
	input logic setup_end,
	output setupPac_t data_setup_old,
	input setupPac_t data_setup_new
);

	typedef enum logic [3:0] {
		RESETADO,
		MONTAR_PIN,
		VERIFICAR_SENHA,
		ESPERA,
		SETUP,
		TRAVA_OFF,
		TRAVA_ON,
		PORTA_ABERTA,
		PORTA_FECHADA,
		UPDATE_MASTER,
		FALHA
	} estado_t;
	 
	estado_t estado, proximo_estado;

	pinPac_t pin_input, novo_master;
	logic senha_fail, senha_padrao, senha_master, senha_master_update;
	logic fluxo_pos_reset;

	logic botao_interno_prev;
	logic botao_pressionado;

	setupPac_t setup_data;
	logic reset_contadores_porta, reset_cont_falha;
	
	logic [7:0] cont_falha;
	logic [15:0] cont_espera_falha; 
	logic [6:0] cont_bip, cont_trava;
	
	logic [31:0] tempo_espera_seg;
	
	logic [9:0] cont_1s;
	logic one_sec_tick;

	logic rising_key_valid;

	// Instanciações dos submódulos
	montar_pin montar (
		.clk(clk), 
		.rst(rst), 
		.key_valid(rising_key_valid),
		.key_code(key_code), 
		.pin_out(pin_input)
	);

	verificar_senha verifica (
		.clk(clk), 
		.rst(rst), 
		.pin_in(pin_input), 
		.data_setup(setup_data),
		.senha_fail(senha_fail), 
		.senha_padrao(senha_padrao),
		.senha_master(senha_master), 
		.senha_master_update(senha_master_update)
	);
	
	update_master atualizar (
		.clk(clk), 
		.rst(rst), 
		.enable(estado == UPDATE_MASTER),
		.pin_in(pin_input), 
		.new_master_pin(novo_master)
	);

	always_ff @(posedge clk or posedge rst) begin
		if(rst) begin
			estado <= RESETADO;
			fluxo_pos_reset <= 1'b1;
			setup_data.bip_status <= 1;
			setup_data.bip_time <= 5;
			setup_data.tranca_aut_time <= 5;
			setup_data.master_pin.status <= 1;
			setup_data.master_pin.digit1 <= 4'h1;
			setup_data.master_pin.digit2 <= 4'h2;
			setup_data.master_pin.digit3 <= 4'h3;
			setup_data.master_pin.digit4 <= 4'h4;
			setup_data.pin1.status <= 1;
			setup_data.pin1.digit1 <= 4'h0;
			setup_data.pin1.digit2 <= 4'h0;
			setup_data.pin1.digit3 <= 4'h0;
			setup_data.pin1.digit4 <= 4'h0;
			setup_data.pin2.status <= 0;
			setup_data.pin3.status <= 0;
			setup_data.pin4.status <= 0;
		end else begin
			estado <= proximo_estado;
			
			if (estado == UPDATE_MASTER && novo_master.status && fluxo_pos_reset) begin
				fluxo_pos_reset <= 1'b0;
			end

			if (novo_master.status) begin
				setup_data.master_pin <= novo_master;
			end
			
			if (setup_end) begin
				setup_data <= data_setup_new;
			end
		end
	end

	always_ff @(posedge clk or posedge rst) begin
		if (rst) begin
			cont_falha <= 0;
			cont_bip <= 0;
			cont_trava <= 0;
			cont_espera_falha <= 0;
			cont_1s <= 0;
			one_sec_tick <= 0;
			botao_interno_prev <= 0;
		end else begin
			botao_interno_prev <= botao_interno;

			if (cont_1s == 999) begin
				cont_1s <= 0;
				one_sec_tick <= 1;
			end else begin
				cont_1s <= cont_1s + 1;
				one_sec_tick <= 0;
			end
			
			if (reset_cont_falha) begin
				cont_falha <= 0;
			end else if (estado == VERIFICAR_SENHA && senha_fail) begin
				cont_falha <= cont_falha + 1;
			end

			
			if (one_sec_tick) begin
				if (estado == ESPERA) begin
					if(cont_espera_falha < tempo_espera_seg)
						cont_espera_falha <= cont_espera_falha + 1;
				end else begin
					cont_espera_falha <= 0;
				end
				
				if (estado == PORTA_ABERTA && sensor_de_contato) begin 
					cont_trava <= 0;
					if (cont_bip < setup_data.bip_time)
						cont_bip <= cont_bip + 1;
				end
				
				if (estado == PORTA_FECHADA && !sensor_de_contato) begin
					cont_bip <= 0;
					if (cont_trava < setup_data.tranca_aut_time)
						cont_trava <= cont_trava + 1;
				end
			end
			
			if(reset_contadores_porta) begin
				cont_bip <= 0;
				cont_trava <= 0;
			end
		end
	end

	always_comb begin
		proximo_estado = estado;
		
		// Saídas padrão
		tranca = 1'b1; // Padrão é travado (0)
		bip = 0;
		bcd_enable = 0;
		bcd_out = '{default:4'hA};
		setup_on = 0;
		reset_contadores_porta = 0;
		reset_cont_falha = 0;
		
		// Lógica para tempo de espera por falhas
		if (cont_falha < 3)      tempo_espera_seg = 1;
		else if (cont_falha == 3) tempo_espera_seg = 10;
		else if (cont_falha == 4) tempo_espera_seg = 20;
		else                      tempo_espera_seg = 30;
		
		// Máquina de Estados Principal
		case (estado) 
			RESETADO: begin
				if (!sensor_de_contato) begin
					proximo_estado = MONTAR_PIN;
					tranca = 1;
				end else begin
					tranca = 0;
				end
			end
			
			MONTAR_PIN: begin
				bcd_enable = 1;
				bcd_out.BCD0 = pin_input.digit4;
				bcd_out.BCD1 = pin_input.digit3;
				bcd_out.BCD2 = pin_input.digit2;
				bcd_out.BCD3 = pin_input.digit1;

				if (botao_pressionado) begin 
					proximo_estado = TRAVA_OFF;
					bcd_out.BCD0 = 4'hE;
					bcd_out.BCD1 = 4'hE;
					bcd_out.BCD2 = 4'hE;
					bcd_out.BCD3 = 4'hE;
					bcd_out.BCD4 = 4'hE;
					bcd_out.BCD5 = 4'hE;
				end else if (pin_input.status)begin
					bcd_out.BCD0 = 4'hE;
					bcd_out.BCD1 = 4'hE;
					bcd_out.BCD2 = 4'hE;
					bcd_out.BCD3 = 4'hE;
					bcd_out.BCD4 = 4'hE;
					bcd_out.BCD5 = 4'hE;
					proximo_estado = VERIFICAR_SENHA;
				end
					
			end
			
			VERIFICAR_SENHA: begin
				if (senha_fail) begin
					bcd_enable = 1;
					bcd_out = '{default:4'hB};
					proximo_estado = ESPERA;
				end else if (senha_padrao) begin
					reset_cont_falha = 1;
					proximo_estado = TRAVA_OFF;
				end else if (senha_master && fluxo_pos_reset) begin
					proximo_estado = UPDATE_MASTER;
					reset_cont_falha = 1;
				end else if (senha_master) begin
					proximo_estado = SETUP;
					reset_cont_falha = 1;
				end
			end

			ESPERA: begin
				bcd_enable = 1;
				bcd_out = '{default:4'hB};
				if (cont_espera_falha >= tempo_espera_seg)
					proximo_estado = MONTAR_PIN;
			end
			
			TRAVA_OFF: begin 
				tranca = 1'b0; // DESTRAVADO
				reset_contadores_porta = 1;
				proximo_estado = PORTA_ABERTA;
			end
			
			PORTA_ABERTA: begin 
				tranca = 1'b0; // DESTRAVADO
				if (!sensor_de_contato) begin
					reset_contadores_porta = 1;
					proximo_estado = PORTA_FECHADA;
				end else if (cont_bip >= setup_data.bip_time && setup_data.bip_status) begin
					bip = 1; 
				end
			end
			
			PORTA_FECHADA: begin 
				tranca = 1'b0; // DESTRAVADO
				if (sensor_de_contato) begin
					reset_contadores_porta = 1;
					proximo_estado = PORTA_ABERTA;
				end else if (botao_pressionado) begin
					proximo_estado = TRAVA_ON; 
				end else if (cont_trava >= setup_data.tranca_aut_time) begin
					proximo_estado = TRAVA_ON; 
				end
			end
			
			TRAVA_ON: begin 
				tranca = 1'b1; // TRAVADO
				bip = 0;
				bcd_enable = 1;
				bcd_out = '{default:4'hA};

				proximo_estado = MONTAR_PIN;
			end
			
			UPDATE_MASTER: begin
				bcd_enable = 1;

				bcd_out.BCD3 = pin_input.digit1;
				bcd_out.BCD2 = pin_input.digit2;
				bcd_out.BCD1 = pin_input.digit3;
				bcd_out.BCD0 = pin_input.digit4;

				if (novo_master.status && fluxo_pos_reset) begin
					proximo_estado = MONTAR_PIN;
				end else if(botao_pressionado) begin
					proximo_estado = TRAVA_OFF;
				end
				
			end
			
			SETUP: begin
				setup_on = 1; 
				if (setup_end)
					proximo_estado = TRAVA_ON;
			end
			
			default: proximo_estado = RESETADO;

		endcase
	end

	assign rising_key_valid = (!sensor_de_contato == 1'b1 || key_code > 4'h9) ? key_valid : 1'b0;
	assign botao_pressionado = (botao_interno == 1'b1 && botao_interno_prev == 1'b0);
	assign data_setup_old = setup_data;
endmodule