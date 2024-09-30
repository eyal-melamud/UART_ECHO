`include "fifo.sv"
`include "uart_tx.sv"
`include "uart_rx.sv"

/**
    input:
        clk             - the system clk
        n_rst           - reset tne logic and buffers

        rx              - the data in line
       
        data_in         - 8 bits to send as a packet
        data_in_sync    - signals to read the data

        data_out_sync   - signals to move to next packege


    output:
        tx              - the data out line 

        data_out        - 8 bits to recived from packet
        full_out        - the recived buffer is full
        valid_out       - is there data that have been recived and its ok

        full_in         - the to send buffer is full


    parameters:

        RX_BUFFER_SIZE  - the how many bytes the recived buffer should be   - DEFAULT 8
        tX_BUFFER_SIZE  - the how many bytes the to send buffer should be   - DEFAULT 8
        CLK_FRQ         - the frequency of the input clock                  - DEFAULT 27_000_000 [MHz]
        UART_BOUAD      - the uart speed                                    - DEFAULT 115200 [bps]


*/ 



module UART_TOP #(
    parameter RX_BUFFER_SIZE = 8,
    parameter TX_BUFFER_SIZE = 8,
    parameter CLK_FRQ        = 27000000,
    parameter UART_BOUAD     = 115200) 
(
    input clk,             
    input n_rst,           
    input rx,              
    input [7:0] data_in,    
    input data_in_sync,    
    input data_out_sync,   

    output tx,             
    output [7:0] data_out,  
    output full_out,       
    output valid_out,      
    output full_in);
    

// ===================================================================================================================
// CLOCK area
// ===================================================================================================================


    reg                         sample_clk, send_clk;
    parameter                   TO_DIV_BY = CLK_FRQ/(UART_BOUAD*32); 
    reg [$clog2(TO_DIV_BY)-1:0] sample_clk_count;
    reg [3:0]                   send_clk_count;

    initial begin
        sample_clk_count    <= 0;
        sample_clk          <= 0;
        send_clk_count      <= 0;
        send_clk            <= 0;
    end

    always @(posedge clk) begin
        sample_clk          <= (sample_clk_count==TO_DIV_BY)                    ? ~sample_clk           : sample_clk;
        sample_clk_count    <= (sample_clk_count>=TO_DIV_BY)                    ? 0                     : sample_clk_count + 1;
        
        send_clk            <= (sample_clk_count==TO_DIV_BY && &send_clk_count) ? ~send_clk             : send_clk;
        send_clk_count      <= (sample_clk_count==TO_DIV_BY)                    ? send_clk_count + 1    : send_clk_count;
    end


// ===================================================================================================================
// buffers area
// ===================================================================================================================

    wire data_ready_tx;
    wire [7:0] data_from_rx, data_to_tx;

    

    FIFO #(RX_BUFFER_SIZE, 8) rx_buffer (.clk        (clk),
                                         .n_rst      (n_rst),
                                         .push       (rx_push),
                                         .pop        (data_out_sync),
                                         .data_in    (data_from_rx), 
                                         .data_out   (data_out),
                                         .valid      (valid_out),
                                         .buff_full  (full_out));

    FIFO #(TX_BUFFER_SIZE, 8) tx_buffer (.clk        (clk),
                                         .n_rst      (n_rst),
                                         .push       (data_in_sync), 
                                         .pop        (tx_pop),
                                         .data_in    (data_in), 
                                         .data_out   (data_to_tx),
                                         .valid      (data_ready_tx),
                                         .buff_full  (full_in));



// ===================================================================================================================
// TX RX area
// ===================================================================================================================

    wire tx_busy, rx_data_ready;
    reg tx_pop, tx_send, rx_done, rx_push;

    initial begin
        tx_pop  <= 1'b0;
        tx_send <= 1'b0; 
        rx_done <= 1'b0; 
        rx_push <= 1'b0;
    end

    UART_TX tx_module (.clk         (clk),
                       .send_clk    (send_clk),
                       .n_rst       (n_rst),
                       .send        (tx_send),
                       .data        (data_to_tx),
                       .tx          (tx),
                       .busy        (tx_busy)); 

    UART_RX rx_module (.clk         (clk),
                       .sample_clk  (sample_clk),   
                       .n_rst       (n_rst),
                       .done        (rx_push), 
                       .rx          (rx),
                       .data        (data_from_rx),
                       .data_ready  (rx_data_ready)); 


    always @(posedge clk) begin // TX controler
        if (data_ready_tx&&(~tx_busy)) begin
            tx_send <= 1'b1;
            tx_pop  <= 1'b1; 
        end else begin
            tx_send <= 1'b0;
            tx_pop  <= 1'b0;
        end
    end

    always @(posedge clk) begin // RX controler
        if (rx_data_ready) begin
            rx_done <= 1'b1;
            rx_push <= 1'b1;
        end else begin
            rx_done <= 1'b0;
            rx_push <= 1'b0;
        end
        
    end


endmodule



























