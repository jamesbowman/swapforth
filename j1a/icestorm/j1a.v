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

module top(input clk, output D1, output D2, output D3, output D4, output D5,

           output TXD,        // UART TX
           input RXD,         // UART RX

           output PIOS_00,    // flash SCK
           input PIOS_01,     // flash MISO
           output PIOS_02,    // flash MOSI
           output PIOS_03,    // flash CS

           output PIO1_02,    // PMOD 1
           output PIO1_03,    // PMOD 1
           output PIO1_04,    // PMOD 1
           output PIO1_05,    // PMOD 1
           output PIO1_06,    // PMOD 1
           output PIO1_07,    // PMOD 1
           output PIO1_08,    // PMOD 1
           output PIO1_09,    // PMOD 1

           output PIO1_18,    // IR TXD
           input  PIO1_19,    // IR RXD
           output PIO1_20,    // IR SD

           input resetq,
);
  localparam MHZ = 12;

  wire io_rd, io_wr;
  wire [15:0] mem_din;
  wire [15:0] mem_addr;
  wire mem_wr;
  wire [15:0] dout;
  wire [15:0] io_din;
  wire [12:0] code_addr;
  wire [15:0] insn;
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
    .mem_din(mem_din),
    .mem_addr(mem_addr),
    .code_addr(code_addr),
    .insn(insn));

  /*
  // ######   TICKS   #########################################

  reg [15:0] ticks;
  always @(posedge clk)
    ticks <= ticks + 16'd1;
  */

  // ######   IO SIGNALS   ####################################

  reg io_wr_, io_rd_;
  reg [15:0] dout_;
  reg [15:0] io_addr_;

  always @(posedge clk) begin
    {io_rd_, io_wr_, dout_} <= {io_rd, io_wr, dout};
    if (io_rd | io_wr)
      io_addr_ <= mem_addr;
  end

  // ######   PMOD   ##########################################

  reg [7:0] pmod_dir;   // 1:output, 0:input
  assign {PIO1_09, PIO1_08, PIO1_07, PIO1_06, PIO1_05, PIO1_04, PIO1_03, PIO1_02} = pmod_dir;

  // ######   UART   ##########################################

  wire uart0_valid, uart0_busy;
  wire [7:0] uart0_data;
  wire uart0_wr = io_wr_ & io_addr_[12];
  wire uart0_rd = io_rd_ & io_addr_[12];
  reg [31:0] uart_baud = 31'd115200;
  wire UART0_RX;
  buart #(.CLKFREQ(MHZ * 1000000)) _uart0 (
     .clk(clk),
     .resetq(1'b1),
     .baud(uart_baud),
     .rx(RXD),
     .tx(TXD),
     .rd(uart0_rd),
     .wr(uart0_wr),
     .valid(uart0_valid),
     .busy(uart0_busy),
     .tx_data(dout_[7:0]),
     .rx_data(uart0_data));

  reg [4:0] PIOS;
  assign {PIO1_20, PIO1_18, PIOS_00, PIOS_02, PIOS_03} = PIOS;
  reg [4:0] LEDS;
  assign {D1,D2,D3,D4,D5} = LEDS;

  // ######   IO PORTS   ######################################

  /*        bit READ            WRITE
      0001  0   PMOD rd         PMOD wr
      0002  1                   PMOD direction
      0004  2                   LEDS
      0008  3                   misc.out
      1000  12  UART RX         UART TX
      2000  13  misc.in
  */

  assign io_din =
    (io_addr_[ 1] ? {8'd0, pmod_dir}                                    : 16'd0) |
    (io_addr_[12] ? {8'd0, uart0_data}                                  : 16'd0) |
    (io_addr_[13] ? {12'd0, PIO1_19, PIOS_01, uart0_valid, !uart0_busy} : 16'd0);

  always @(posedge clk) begin
    if (io_wr_ & io_addr_[1])
      pmod_dir <= dout_[7:0];
    if (io_wr_ & io_addr_[2])
      LEDS <= dout_[4:0];
    if (io_wr_ & io_addr_[3])
      PIOS <= dout_[4:0];
  end

  /*
  SB_IO #(
    .PIN_TYPE(6'b011001)
  ) io0 (
	.PACKAGE_PIN(PIO1_02));
  */

  always @(negedge resetq or posedge clk)
    if (!resetq)
      unlocked <= 0;
    else
      unlocked <= unlocked | io_wr_;

endmodule // top
