`timescale 1ns / 1ps

module DEVICE(
    input clk_old,
    
    input UART_TXD_IN,
    output UART_RXD_OUT,
    
    output reg [7:0] an, // parts of led panel
    output reg [7:0] seg, // parts of number
    output ok_led, red_led
);

reg [31:0] memory;

reg [7:0] mask;
wire [7:0] catod;
wire clk;

wire [19:0] dataOut; // for result PRIMA
wire [19:0] inForPrima;

wire set_signal;
wire reset_signal;
wire read_signal;

wire [2:0] count;


//assign clk = clk_old; //------------commite for bitstream
CLK_DIV div26(
    .clk(clk_old), 
    .new_clk(clk));  //-----------uncommite for bitstream

COUNTER #(.mod(8), .out(3)) counter ( //counter for output leds
    .clk(clk),
    .rst(reset_signal),
    .ce(1'b1),
    .value(count));

LED led(
    .clk(clk),
    .switcher(memory[((count+1)*4-1)-:4]),
    .SEG(catod));

initial begin
    memory = 0;
    mask = 8'b00011111;
    an = ~1'b1;
    seg = ~8'b0;
end

assign red_led = set_signal;

wire txclk_en, rxclk_en;
wire [7:0] received_data;
wire recR_O;
wire trNext, trStart, trData;

UART uart(.clk(clk_old), 
    .recR_O(recR_O), 
    .recData(received_data), 
    .OutFsmData(dataOut), 
    .fsmR_O(ok_led), 
    .fsmData(inForPrima), 
    .trStart(trStart), 
    .trData(trData), 
    .trNext(trNext), 
    .set(set_signal), 
    .read(read_signal), 
    .reset(reset_signal));

TRANSCEIVER_uart tranceiver(
    .clk(clk_old), .start(trStart), .data(trData), //.clk_en(txclk_en),
    .t(UART_RXD_OUT), .trNext(trNext));

RECEIVER_uart rec_uart(
    .r(UART_TXD_IN), .clk(clk_old), //.clk_en(rxclk_en),
    .R_O(recR_O), .code(received_data));

//RATE_GEN rate(.clk(clk), .rxclk_en(rxclk_en), .txclk_en(txclk_en));

prima prima3(
    .clk(clk_old),
    .dataIn(inForPrima),
    .rst(reset_signal),
    .R_I(set_signal),
    .get_out(read_signal),
    .readIn(set_signal),
    .dataOut(dataOut),
    .R_O(ok_led));
    
always@ (posedge clk_old)
begin    
    an <= ~((1'd1 << count) & mask);
    seg <= catod;
    if(reset_signal)
        memory <= 32'b0;
    else
        begin
            if(set_signal)
                memory <= {12'b0, inForPrima};
            if(ok_led || read_signal)
                memory <= {12'b0, dataOut[19:0]};
        end
end
endmodule
