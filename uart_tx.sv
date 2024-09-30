




module UART_TX (
    input clk, send_clk, n_rst, send,
    input [7:0] data,

    output tx, busy);


    parameter IDLE = 2'h0, START_BIT = 2'h1, SENDING_DATA = 2'h2, STOP_BIT = 2'h3;

    reg [1:0] state, next_state;
    reg [2:0] count;

    reg start_sending, got_n_rst;
    
    reg [7:0] data_to_send;
    initial begin
        state           <= IDLE;
        count           <= 3'h0;
        start_sending   <= 1'b0; 
        got_n_rst       <= 1'b0;
    end

    always @(*) begin 
        case (state)
            IDLE            : next_state <= start_sending   ? START_BIT : IDLE;
            START_BIT       : next_state <=                               SENDING_DATA;
            SENDING_DATA    : next_state <= &count          ? STOP_BIT  : SENDING_DATA; 
            STOP_BIT        : next_state <= &count          ? IDLE      : STOP_BIT; 
            default         : next_state <=                               IDLE;
        endcase   
    end

    always @(posedge clk) begin
        if (~n_rst) begin 
            got_n_rst <= 1'b1;
            start_sending   <= 1'b0;
        end else if (state == IDLE) begin
            got_n_rst <= 1'b0;
            if (send&(~start_sending)) begin
                data_to_send <= data;
                start_sending <= 1'b1;
            end
        end else start_sending <= 1'b0;
    end

    always @(posedge send_clk) begin
        if (got_n_rst) begin 
            state <= IDLE;
            count <= 3'h0; 
        end else if (|state) begin // any state other than IDLE
            if (state != START_BIT) count <= count + 1;
            else count <= 3'b0;
            
        end
        state <= next_state;
    end

    assign tx   = (state == IDLE || state == STOP_BIT) ? 1'b1 : ((state == START_BIT) ? 1'b0 : data_to_send[count]) ;
    assign busy = (|state)|start_sending; // any state other than IDLE
    
endmodule