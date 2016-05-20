`timescale 1 ns / 1 ps

`default_nettype none
`define WIDTH 16

module SB_RAM2048x2(
	output [1:0] RDATA,
	input        RCLK, RCLKE, RE,
	input  [10:0] RADDR,
	input         WCLK, WCLKE, WE,
	input  [10:0] WADDR,
	input  [1:0] MASK, WDATA
);
	parameter INIT_0 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_1 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_2 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_3 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_4 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_5 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_6 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_7 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_8 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_9 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_A = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_B = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_C = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_D = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_E = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_F = 256'h0000000000000000000000000000000000000000000000000000000000000000;

  wire [15:0] rd;

  SB_RAM40_4K #(
    .WRITE_MODE(3),
    .READ_MODE(3),
    .INIT_0(INIT_0),
    .INIT_1(INIT_1),
    .INIT_2(INIT_2),
    .INIT_3(INIT_3),
    .INIT_4(INIT_4),
    .INIT_5(INIT_5),
    .INIT_6(INIT_6),
    .INIT_7(INIT_7),
    .INIT_8(INIT_8),
    .INIT_9(INIT_9),
    .INIT_A(INIT_A),
    .INIT_B(INIT_B),
    .INIT_C(INIT_C),
    .INIT_D(INIT_D),
    .INIT_E(INIT_E),
    .INIT_F(INIT_F)
  ) _ram (
    .RDATA(rd),
    .RADDR(RADDR),
    .RCLK(RCLK), .RCLKE(RCLKE), .RE(RE),
    .WCLK(WCLK), .WCLKE(WCLKE), .WE(WE),
    .WADDR(WADDR),
    .MASK(16'h0000), .WDATA({4'b0, WDATA[1], 7'b0, WDATA[0], 3'b0}));

  assign RDATA[0] = rd[3];
  assign RDATA[1] = rd[11];

endmodule

module ioport(
  input clk,
  inout [7:0] pins,
  input we,
  input [7:0] wd,
  output [7:0] rd,
  input [7:0] dir);

  genvar i;
  generate 
    for (i = 0; i < 8; i = i + 1) begin : io
      // 1001   PIN_OUTPUT_REGISTERED_ENABLE 
      //     01 PIN_INPUT 
      SB_IO #(.PIN_TYPE(6'b1001_01)) _io (
        .PACKAGE_PIN(pins[i]),
        .CLOCK_ENABLE(we),
        .OUTPUT_CLK(clk),
        .D_OUT_0(wd[i]),
        .D_IN_0(rd[i]),
        .OUTPUT_ENABLE(dir[i]));
    end
  endgenerate

endmodule

module outpin(
  input clk,
  output pin,
  input we,
  input wd,
  output rd);

  reg q;
  always @(posedge clk)
    if (we)
      q <= wd;
  assign rd = q;

  SB_IO #(.PIN_TYPE(6'b0110_01)) _io (
        .PACKAGE_PIN(pin),
        .D_OUT_0(q));
endmodule

module inpin(
  input clk,
  input pin,
  output rd);

  SB_IO #(.PIN_TYPE(6'b0000_00)) _io (
        .PACKAGE_PIN(pin),
        .INPUT_CLK(clk),
        .D_IN_0(rd));
endmodule

module top(input pclk, output D1, output D2, output D3, output D4, output D5,

           output TXD,        // UART TX
           input RXD,         // UART RX

           input CLK,         // clock in
           output o_Segment1_A,
           output o_Segment1_B,
           output o_Segment1_C,
           output o_Segment1_D,
           output o_Segment1_E,
           output o_Segment1_F,
           output o_Segment1_G,
           output o_Segment2_A,
           output o_Segment2_B,
           output o_Segment2_C,
           output o_Segment2_D,
           output o_Segment2_E,
           output o_Segment2_F,
           output o_Segment2_G
);
  wire resetq = 1'b1;

  wire clk = CLK;
  // SB_PLL40_CORE #(.FEEDBACK_PATH("SIMPLE"),
  //                 .PLLOUT_SELECT("GENCLK"),
  //                 .DIVR(4'b0000),
  //                 .DIVF(7'd0),
  //                 .DIVQ(3'b000),
  //                 .FILTER_RANGE(3'b001),
  //                ) uut (
  //                 .REFERENCECLK(CLK),
  //                 .PLLOUTCORE(clk),
  //                 //.PLLOUTGLOBAL(clk),
  //                 // .LOCK(D5),
  //                 .RESETB(1'b1),
  //                 .BYPASS(1'b0)
  //                 );

  wire io_rd, io_wr;
  wire [15:0] mem_addr;
  wire mem_wr;
  wire [15:0] dout;
  wire [15:0] io_din;
  wire [12:0] code_addr;
  reg unlocked = 0;

`include "../build/ram.v"

  j1 _j1(
    .clk(clk),
    .resetq(resetq),
    .io_rd(io_rd),
    .io_wr(io_wr),
    .mem_wr(mem_wr),
    .dout(dout),
    .io_din(io_din),
    .mem_addr(mem_addr),
    .code_addr(code_addr),
    .insn(insn));

  // ######   IO SIGNALS   ####################################

`define EASE_IO_TIMING
`ifdef EASE_IO_TIMING
  reg io_wr_, io_rd_;
  reg [15:0] dout_;
  reg [15:0] io_addr_;

  always @(posedge clk) begin
    {io_rd_, io_wr_, dout_} <= {io_rd, io_wr, dout};
    if (io_rd | io_wr)
      io_addr_ <= mem_addr;
  end
`else
  wire io_wr_ = io_wr, io_rd_ = io_rd;
  wire [15:0] dout_ = dout;
  wire [15:0] io_addr_ = mem_addr;
`endif

  // ######   UART   ##########################################

  wire uart0_valid, uart0_busy;
  wire [7:0] uart0_data;
  wire uart0_wr = io_wr_ & io_addr_[12];
  wire uart0_rd = io_rd_ & io_addr_[12];
  wire uart_RXD;
  inpin _rcxd(.clk(clk), .pin(RXD), .rd(uart_RXD));
  buart _uart0 (
     .clk(clk),
     .resetq(1'b1),
     .rx(uart_RXD),
     .tx(TXD),
     .rd(uart0_rd),
     .wr(uart0_wr),
     .valid(uart0_valid),
     .busy(uart0_busy),
     .tx_data(dout_[7:0]),
     .rx_data(uart0_data));

  wire w4 = io_wr_ & io_addr_[2];

  wire [13:0] LEDS;
  outpin led0 (.clk(clk),  .we(w4), .pin(o_Segment1_A), .wd(dout_[ 0]), .rd(LEDS[ 0]));
  outpin led1 (.clk(clk),  .we(w4), .pin(o_Segment1_B), .wd(dout_[ 1]), .rd(LEDS[ 1]));
  outpin led2 (.clk(clk),  .we(w4), .pin(o_Segment1_C), .wd(dout_[ 2]), .rd(LEDS[ 2]));
  outpin led3 (.clk(clk),  .we(w4), .pin(o_Segment1_D), .wd(dout_[ 3]), .rd(LEDS[ 3]));
  outpin led4 (.clk(clk),  .we(w4), .pin(o_Segment1_E), .wd(dout_[ 4]), .rd(LEDS[ 4]));
  outpin led5 (.clk(clk),  .we(w4), .pin(o_Segment1_F), .wd(dout_[ 5]), .rd(LEDS[ 5]));
  outpin led6 (.clk(clk),  .we(w4), .pin(o_Segment1_G), .wd(dout_[ 6]), .rd(LEDS[ 6]));
  outpin led7 (.clk(clk),  .we(w4), .pin(o_Segment2_A), .wd(dout_[ 7]), .rd(LEDS[ 7]));
  outpin led8 (.clk(clk),  .we(w4), .pin(o_Segment2_B), .wd(dout_[ 8]), .rd(LEDS[ 8]));
  outpin led9 (.clk(clk),  .we(w4), .pin(o_Segment2_C), .wd(dout_[ 9]), .rd(LEDS[ 9]));
  outpin led10 (.clk(clk), .we(w4), .pin(o_Segment2_D), .wd(dout_[10]), .rd(LEDS[10]));
  outpin led11 (.clk(clk), .we(w4), .pin(o_Segment2_E), .wd(dout_[11]), .rd(LEDS[11]));
  outpin led12 (.clk(clk), .we(w4), .pin(o_Segment2_F), .wd(dout_[12]), .rd(LEDS[12]));
  outpin led13 (.clk(clk), .we(w4), .pin(o_Segment2_G), .wd(dout_[13]), .rd(LEDS[13]));

  // ######   RING OSCILLATOR   ###############################

  wire [1:0] buffers_in, buffers_out;
  assign buffers_in = {buffers_out[0:0], ~buffers_out[1]};
  SB_LUT4 #(
          .LUT_INIT(16'd2)
  ) buffers [1:0] (
          .O(buffers_out),
          .I0(buffers_in),
          .I1(1'b0),
          .I2(1'b0),
          .I3(1'b0)
  );
  wire random = ~buffers_out[1];

  // ######   IO PORTS   ######################################

  /*        bit   mode    device
      0001  0     r/w     PMOD GPIO
      0002  1     r/w     PMOD direction
      0004  2     r/w     LEDS
      0008  3     r/w     misc.out
      0010  4     r/w     HDR1 GPIO
      0020  5     r/w     HDR1 direction
      0040  6     r/w     HDR2 GPIO
      0080  7     r/w     HDR2 direction
      0800  11      w     sb_warmboot
      1000  12    r/w     UART RX, UART TX
      2000  13    r       misc.in
  */

  assign io_din =
    (io_addr_[ 2] ? LEDS                                                : 16'd0) |
    (io_addr_[12] ? {8'd0, uart0_data}                                  : 16'd0) |
    (io_addr_[13] ? {11'd0, random, 1'b0, 1'b0, uart0_valid, !uart0_busy} : 16'd0);

  always @(negedge resetq or posedge clk)
    if (!resetq)
      unlocked <= 0;
    else
      unlocked <= unlocked | io_wr_;

endmodule // top
