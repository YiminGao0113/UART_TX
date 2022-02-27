module top
(   
    input [3:0] button,
    input clk,
    output UART_TXD
);


reg [3:0] button0;
reg press3, press2, press1, press0;
wire press;

// The type definition for the UART state machine type. Here is a description of what
// occurs during each state:
// RST_REG     -- Do Nothing. This state is entered after configuration or a user reset.
//                The state is set to LD_INIT_STR.
// LD_INIT_STR -- The Welcome String is loaded into the sendStr variable and the strIndex
//                variable is set to zero. The welcome string length is stored in the StrEnd
//                variable. The state is set to SEND_CHAR.
// SEND_CHAR   -- uartSend is set high for a single clock cycle, signaling the character
//                data at sendStr(strIndex) to be registered by the UART_TX_CTRL at the next
//                cycle. Also, strIndex is incremented (behaves as if it were post 
//                incremented after reading the sendStr data). The state is set to RDY_LOW.
// RDY_LOW     -- Do nothing. Wait for the READY signal from the UART_TX_CTRL to go low, 
//                indicating a send operation has begun. State is set to WAIT_RDY.
// WAIT_RDY    -- Do nothing. Wait for the READY signal from the UART_TX_CTRL to go high, 
//                indicating a send operation has finished. If READY is high and strEnd = 
//                StrIndex then state is set to WAIT_BTN, else if READY is high and strEnd /=
//                StrIndex then state is set to SEND_CHAR.
// WAIT_BTN    -- Do nothing. Wait for a button press on BTNU, BTNL, BTND, or BTNR. If a 
//                button press is detected, set the state to LD_BTN_STR.
// LD_BTN_STR  -- The Button String is loaded into the sendStr variable and the strIndex
//                variable is set to zero. The button string length is stored in the StrEnd
//                variable. The state is set to SEND_CHAR.

integer i;
parameter RESET_CNT_MAX = 200000; // wait for 2ms

parameter RST_REG       = 3'b000;
parameter LD_INIT_STR   = 3'b001;
parameter SEND_CHAR     = 3'b010;
parameter RDY_LOW       = 3'b110;
parameter WAIT_RDY      = 3'b111;
parameter WAIT_BTN      = 3'b101;
parameter LD_BTN_STR    = 3'b100;



parameter line1dataEnd = 12;
parameter line2dataEnd = 13;
reg [7:0] uartData;
reg [7:0] strIndex;
reg [2:0] uartState;
reg [7:0] strEnd;
reg [7:0] sendStr [15:0];
reg uartSend;

wire uartRdy;


wire [7:0] line1data [15:0];
assign line1data[15]  = " ";
assign line1data[14]  = " ";
assign line1data[13]  = " ";
assign line1data[12]  = " ";
assign line1data[11]  = "H";
assign line1data[10]  = "e";
assign line1data[9]  = "l";
assign line1data[8]  = "l";
assign line1data[7]  = "o";
assign line1data[6]  = " ";
assign line1data[5]  = "W";
assign line1data[4]  = "o";
assign line1data[3]  = "r";
assign line1data[2]  = "l";
assign line1data[1] = "d";
assign line1data[0] = "!";


wire [7:0] line2data [15:0];
assign line2data[15]  = " ";
assign line2data[14]  = 4'h0A;
assign line2data[13]  = " ";
assign line2data[12]  = " ";
assign line2data[11]  = "!";
assign line2data[10]  = "n";
assign line2data[9]  = "i";
assign line2data[8]  = "m";
assign line2data[7]  = "i";
assign line2data[6]  = "Y";
assign line2data[5]  = " ";
assign line2data[4]  = "o";
assign line2data[3]  = "l";
assign line2data[2]  = "l";
assign line2data[1] = "e";
assign line2data[0] = "H";

// Next state logic
always @(posedge clk)
begin
    case (uartState)
        RST_REG:
            uartState <= LD_INIT_STR;
        LD_INIT_STR:
            uartState <= SEND_CHAR;
        SEND_CHAR:
            uartState <= RDY_LOW;
        RDY_LOW:
            if (uartRdy == 1'b0)
                uartState <= WAIT_RDY;
        WAIT_RDY:
            if (uartRdy == 1'b1)
                if (strEnd == strIndex)
                    uartState <= WAIT_BTN;
                else
                    uartState <= SEND_CHAR;
        WAIT_BTN:
            if (press == 1'b1)
                uartState <= LD_BTN_STR;
        LD_BTN_STR:
            uartState <= SEND_CHAR;
        default:
            uartState <= RST_REG;
    endcase
end

// String loading process
always @(posedge clk)
begin
    if (uartState == LD_INIT_STR)
    begin
        strEnd <= 15;
        for (i = 0; i < 16; i = i + 1)
        begin
            sendStr[i] <= line1data[i];
        end
    end
    else if (uartState == LD_BTN_STR)
    begin
        strEnd <= 15;
        for (i = 0; i < 16; i = i + 1)
        begin
            sendStr[i] <= line2data[i];
        end
    end
end


// char counting process
always @(posedge clk)
begin
    if ((uartState == LD_INIT_STR) || (uartState == LD_BTN_STR))
        strIndex <= 0;
    else if(uartState == SEND_CHAR)
        strIndex <= strIndex + 1;
end



// char loading process
always @(posedge clk)
begin
    if (uartState == SEND_CHAR)
    begin
        uartSend <= 1'b1;
        uartData <= sendStr[strIndex];
    end
    else
        uartSend <= 1'b0;
end


always @ (posedge clk)
begin
    press3 <= (button[3] == 1'b0) && (button0[3] == 1'b1)? 1'b1 : 1'b0;
    press2 <= (button[2] == 1'b0) && (button0[2] == 1'b1)? 1'b1 : 1'b0;
    press1 <= (button[1] == 1'b0) && (button0[1] == 1'b1)? 1'b1 : 1'b0;
    press0 <= (button[0] == 1'b0) && (button0[0] == 1'b1)? 1'b1 : 1'b0;
    button0 <= button;
end

assign press = press3 | press2 | press1 | press0;


UART_TX_CTRL u(
    .send(uartSend),
    .data(uartData),
    .clk(clk),
    .ready(uartRdy),
    .UART_TX(UART_TXD)
);


endmodule