`timescale 1ns / 1ps

module uart_test();

localparam CLK_PERIOD = 10;
localparam UART_PERIOD = 10416*CLK_PERIOD;

reg clk = 0, uart_clk = 0;
always #CLK_PERIOD  clk <= ~clk;
always #UART_PERIOD uart_clk <= ~uart_clk;

reg rx;
wire tx;

reg [3:0] i;
reg [2:0] j;

wire [2:0] RGB;

wire [7:0] AN;
wire [7:0] SEG;

initial 
begin

    clk = 0; uart_clk = 0;
    
    rx = 1; 
    i = 0;

    send_number({8'd49, 8'd50, 8'd51, 8'd52});
    #(5*UART_PERIOD);
    //send_number({8'h37, 8'h43, 8'h30, 8'h30});
    
    #40_000_000;
    $finish;
end

wire led_ok;
wire led_view;

DEVICE device(
    .clk_old(clk),
    .UART_TXD_IN(rx),
    .UART_RXD_OUT(tx),
    .an(AN), // parts of led panel
    .seg(SEG), // parts of number
    .ok_led(led_ok), 
    .red_led(led_view)
);

task automatic send_byte(
    input [7:0] uart_buf
);
    begin
        @(posedge uart_clk);
        rx = 0;
        @(posedge uart_clk);
        for(i = 0; i < 8; i = i + 1)
        begin
            $display("uart_buf = %b, i = %d, uart_buf[i] = %b", uart_buf, i, uart_buf[i]);
            rx = uart_buf[i];
            @(posedge uart_clk);  
        end
        rx = 1;
        @(posedge uart_clk);
        $display("_");
    end
endtask

task send_number(
    input [31:0] a
);
begin
    for (j = 0; j < 4; j = j + 1)
        send_byte(a[31-j*8 -: 8]);
    send_byte(8'h0D); // CR
end
endtask

endmodule