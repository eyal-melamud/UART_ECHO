`include "uart_echo.sv"


module uart_echo_tb();


    reg my_clk, my_rx, my_n_rst;
    wire my_tx;

    UART_ECHO my_uart_echo (.clk    (my_clk),
                            .rx     (my_rx),
                            .n_rst  (my_n_rst),
                            .tx     (my_tx));



    initial begin     
        my_rx       <= 1'b1;
        my_n_rst    <= 1'b1;
    end

    initial begin
        my_clk <= 1'b0;
       forever #10 my_clk <= ~my_clk; 
    end

    initial begin
        $dumpfile("tb_uart_echo.v.vcd");
        $dumpvars(0, uart_echo_tb);
        //=======================
        #1000 my_n_rst <= 1'b1;
        #10000;
       
        #4680 my_rx <= 1'b0;
        #4680 my_rx <= 1'b1;
        #4680 my_rx <= 1'b0;
        #4680 my_rx <= 1'b1;
        #4680 my_rx <= 1'b1;
        #4680 my_rx <= 1'b0;
        #4680 my_rx <= 1'b0;
        #4680 my_rx <= 1'b1;
        #4680 my_rx <= 1'b0;
        #4680 my_rx <= 1'b1;
        #10000;
        #4680 my_rx <= 1'b0;
        #4680 my_rx <= 1'b1;
        #4680 my_rx <= 1'b0;
        #4680 my_rx <= 1'b0;
        #4680 my_rx <= 1'b0;
        #4680 my_rx <= 1'b0;
        #4680 my_rx <= 1'b0;
        #4680 my_rx <= 1'b1;
        #4680 my_rx <= 1'b0;
        #4680 my_rx <= 1'b1;
        #50000
        #1500000

        

        
       
        
        
        $finish();
        $display("tset complete");

    end
    

endmodule
    
