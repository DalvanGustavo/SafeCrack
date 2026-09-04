module safecrack_fsm (
    input  logic       clk,    // Clock de 50 MHz
    input  logic       rst,  // Reset assincrono, ativo baixo (KEY[0])
    input  logic [3:0] btn,    // botoes de desbloqueio
    output logic unlocked    // 1 = cofre aberto
);

// ===== cores de acordo com o slide =====
localparam logic [3:0] BTN_AZUL     = 4'b0001;
localparam logic [3:0] BTN_AMARELO  = 4'b0010;
localparam logic [3:0] BTN_VERDE    = 4'b0100;
localparam logic [3:0] BTN_VERMELHO = 4'b1000;

typedef enum logic [4:0] {
    S_INIT = 5'b00001, // aguarda azul
	 S_AZUL = 5'b00010, // aguarda amarelo 1
	 S_AMARELO1  = 5'b00100, // aguarda amarelo 2
	 S_AMARELO2  = 5'b01000, // aguarda vermelho
	 S_OPEN = 5'b10000 // abriu
} state_t;

state_t state, next_state;

logic [3:0] btn_active;
assign btn_active = ~btn;

logic [3:0] btn_prev;
logic btn_press; // ativo quando qualquer botao e pressionado

assign btn_press = (btn_active != 4'b0000) && (btn_prev == 4'b0000);


// Registra o estado anterior do botao (FF simples)
always_ff @(posedge clk or negedge rst) begin
    if (!rst)
		btn_prev <= 4'b0000;
    else
		btn_prev <= btn_active;
end


// estado sequencial
always_ff @(posedge clk or negedge rst) begin
	if(!rst)
		state <= S_INIT;
	else
		state <= next_state;
end


always_comb begin
    next_state = state;  // Default: mantem estado se nao houver borda
	
	if(btn_press) begin
		unique case(state)
			S_INIT: begin
				if(btn_active == BTN_AZUL)
					next_state = S_AZUL;
				else
					next_state = S_INIT;
			end
			
			S_AZUL: begin
				if(btn_active == BTN_AMARELO)
					next_state = S_AMARELO1;
				else
					next_state = S_INIT;
			end
			
			S_AMARELO1: begin
				if(btn_active == BTN_AMARELO)
					next_state = S_AMARELO2;
				else
					next_state = S_INIT;
			end
			
			S_AMARELO2: begin
				if(btn_active == BTN_VERMELHO)
					next_state = S_OPEN;
				else
					next_state = S_INIT;
			end
			
			S_OPEN: begin
				next_state = S_OPEN;
			end
			
			default: next_state = S_INIT;
		endcase
	end
end


assign unlocked = (state == S_OPEN); // caso o estado seja S_OPEN, esta destravado

endmodule
