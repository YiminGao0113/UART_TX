module UART_TX_CTRL
#(parameter CLKS_PER_BIT = 10416,
  parameter BIT_INDEX_MAX = 10)
    (
        input           send,
        input [7:0]     data,
        input           clk,
        output          ready,
        output          UART_TX
    );
    
    parameter IDLE =        3'b000;
    parameter LOAD_BIT =    3'b010;
    parameter SEND_BIT =    3'b100;

    reg [2:0]   r_state = IDLE;
    reg [9:0]   tx_data;
    reg [3:0]   index   = 0;
    reg [13:0]   bitTmr  = 0;



    wire bitDone;
    reg txBit = 1'b1;

    assign bitDone = (bitTmr == CLKS_PER_BIT)? 1'b1: 1'b0;

    // State transition logic
    always @(posedge clk)
    begin
        case (r_state)
            IDLE:
                if (send == 1'b1)
                    r_state <= LOAD_BIT;
            LOAD_BIT:
                r_state <= SEND_BIT;
            SEND_BIT:
                if (bitDone == 1'b1)
                begin
                    if (index == BIT_INDEX_MAX)
                        r_state <= IDLE;
                    else
                        r_state <= LOAD_BIT;
                end
            default:
                r_state <= IDLE;
        endcase
    end

    // Bit Timing
    always @(posedge clk)
    begin
        if (r_state == IDLE)
            bitTmr <= 0;
        else
            if (bitDone == 1'b1)
                bitTmr <= 0;
            else
                bitTmr <= bitTmr + 1;
    end

    // Bit counting
    always @(posedge clk)
    begin
        if (r_state == IDLE)
            index <= 0;
        else if(r_state == LOAD_BIT)
            index <= index + 1;
    end

    // tx data latch
    always @(posedge clk)
    begin
        if (send == 1'b1)
            tx_data <= {1'b1, data, 1'b0};
    end

    // tx bit process
    always @(posedge clk)
    begin
        if (r_state == IDLE)
            txBit <= 1'b1;
        else if(r_state == LOAD_BIT)
            txBit <= tx_data[index];
    end

    assign UART_TX = txBit;
    assign ready = (r_state == IDLE)? 1'b1: 1'b0;

endmodule