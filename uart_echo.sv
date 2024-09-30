`include "uart_top.sv"


module UART_ECHO(
    input clk, rx, n_rst,
    output tx);

    reg ready, data_out_sync, data_in_sync;
    reg [7:0] data;
    wire flag_full_out, flag_full_in, valid_out;
    wire [7:0] data_out;

    UART_TOP my_uart (.clk              (clk),
                      .n_rst            (n_rst),
                      .rx               (rx),
                      .data_in          (data),
                      .data_in_sync     (data_in_sync),
                      .data_out_sync    (data_out_sync),
                      .tx               (tx),
                      .data_out         (data_out),
                      .full_out         (flag_full_out),
                      .valid_out        (valid_out),
                      .full_in          (flag_full_in));

    initial begin
        ready           <= 1'b0;
        data_out_sync   <= 1'b0;
        data_in_sync    <= 1'b0;
        data            <= 0;

    end

    always @(posedge clk) begin
        if (valid_out) begin
            data <= data_out;
            ready <= 1'b1;
            data_out_sync <= 1'b1;
        end else if (ready) begin
            data_out_sync <= 1'b0;
            data_in_sync <= 1'b1;
            ready <= 1'b0;
        end else begin
            data_out_sync <= 1'b0;
            data_in_sync <= 1'b0;
            ready <= 1'b0;
        end
    end
    
endmodule