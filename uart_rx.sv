



module UART_RX(
    input clk, sample_clk, n_rst, done, rx,

    output [7:0] data,
    output data_ready
);
    
    parameter IDLE = 2'h0, START_BIT = 2'h1, READ_DATA = 2'h2, FINISH = 2'h3;
    reg [7:0] data_in_buff, data_out;
    reg data_ready_reg, got_n_rst;
    reg [1:0] state, next_state;
    reg [3:0] bit_avg;
    reg [2:0] bit_count;
    reg [3:0] over_sample_count;

    initial begin
        state               <= IDLE;
        data_ready_reg      <= 1'b0;
        data_out            <= 8'b0;
        data_in_buff        <= 8'b0;
        bit_avg             <= 4'b0;
        over_sample_count   <= 4'b0;
        bit_count           <= 3'b0;
    end


    always @(*) begin 
        case (state)
            IDLE        : next_state <= rx                                  ? IDLE      : START_BIT;
            START_BIT   : next_state <= &over_sample_count                  ? READ_DATA : START_BIT;
            READ_DATA   : next_state <= (&over_sample_count)&&(&bit_count)  ? FINISH    : READ_DATA;
            FINISH      : next_state <= (&over_sample_count)                ? IDLE      : FINISH;
            default     : next_state <= IDLE;
        endcase 
    end

    always @(posedge clk) begin
        if (~n_rst) begin
            data_ready_reg  <= 1'b0;
            got_n_rst       <= 1'b1;
        end else if (state == IDLE) begin
            got_n_rst       <= 1'b0; 
            data_ready_reg  <= done ? 1'b0 : data_ready_reg;       
        end else if (state == FINISH) data_ready_reg <= 1'b1;
    end

    always @(posedge sample_clk) begin
        if (got_n_rst || ~n_rst) begin
            state               <= IDLE;
            bit_avg             <= 4'b0;
            bit_count           <= 3'b0; 
            over_sample_count   <= 4'b0;
        end else begin
            if (|state) begin // cheks if not IDLE
                if (state == READ_DATA) begin
                    if (&over_sample_count) begin
                        data_in_buff[bit_count] <= bit_avg[3];
                        bit_avg                 <= 4'b0;
                        bit_count               <= bit_count + 3'b1;
                    end else begin
                        bit_avg <= bit_avg + rx;
                    end
                end else if ((state == FINISH)&(&over_sample_count)) begin
                    data_out <= data_in_buff;
                end
                over_sample_count <= over_sample_count + 4'b1;
            end else begin
                bit_count           <= 3'b0; 
                over_sample_count   <= 4'b0;
            end
            state <= next_state;
        end   
    end

    assign data         = data_out;
    assign data_ready   = data_ready_reg&(state!=FINISH);


endmodule