`timescale 1ns/1ps

module safecrack_fsm_tb;

    // Sinais
    logic       clk;
    logic       rst;
    logic [3:0] btn;
    logic       unlocked;

    // Instancia do DUT
    safecrack_fsm dut (
        .clk      (clk),
        .rst    (rst),
        .btn      (btn),
        .unlocked (unlocked)
    );

    // Geracao de clock (50 MHz)
    initial clk = 0;
    always #10 clk = ~clk;

    // Task: pressiona um botao especifico
    // btn_val: 4'b0001 (Azul), 4'b0010 (Amarelo), 4'b0100 (Verde), 4'b1000 (Vermelho)
    task press_button(input logic [3:0] btn_val, input int hold_cycles);
        @(negedge clk);
        btn = ~btn_val;                 // Pressiona a cor especifica
        repeat (hold_cycles) @(posedge clk);
        @(negedge clk);
        btn = 4'b1111;                 // Solta o botao (estado inativo do RTL)
        repeat (3) @(posedge clk);     // Aguarda estabilizar
    endtask

    // Task: verifica o estado da trava
    task check_state(input logic expected, input string msg);
        @(negedge clk);
        if (unlocked === expected)
            $display("[PASS] %s | unlocked = %b", msg, unlocked);
        else
            $display("[FAIL] %s | esperado = %b, obtido = %b", msg, expected, unlocked);
    endtask

    // Sequencia de testes
    initial begin
        $dumpfile("safecrack_fsm.vcd");
        $dumpvars(0, safecrack_fsm_tb);

        // Condicao inicial
        rst = 1'b1;
        btn   = 4'b1111; // Todos soltos

        // Teste 1: Reset
        $display("\n=== Teste 1: Reset ===");
        rst = 1'b0;
        repeat (3) @(posedge clk);
        rst = 1'b1;
        @(posedge clk);
        check_state(1'b0, "Apos reset -> Cofre trancado");

        // Teste 2: Inserir a senha correta (Azul, Amarelo, Amarelo, Vermelho)
        $display("\n=== Teste 2: Sequencia correta para abrir o cofre ===");
        
        press_button(4'b0001, 2); // Azul
        check_state(1'b0, "Apos Azul -> Trancado (S_AZUL)");
        
        press_button(4'b0010, 2); // Amarelo
        check_state(1'b0, "Apos Amarelo 1 -> Trancado (S_AMARELO1)");
        
        press_button(4'b0010, 2); // Amarelo
        check_state(1'b0, "Apos Amarelo 2 -> Trancado (S_AMARELO2)");
        
        press_button(4'b1000, 2); // Vermelho
        check_state(1'b1, "Apos Vermelho -> COFRE ABERTO! (S_OPEN)");

        $display("\n=== Simulacao concluida ===\n");
        $finish;
    end

endmodule