`timescale 1 ns / 1 ps

`default_nettype none
`define WIDTH 16

module j1a(input wire clk,
           input wire resetq,
           output wire uart0_wr,
           output wire uart0_rd,
           output wire [7:0] uart_w,
           input wire uart0_valid,
           input wire [7:0] uart0_data
);
  wire io_rd, io_wr;
  wire [15:0] mem_addr;
  wire mem_wr;
  wire [15:0] dout;
  wire [15:0] io_din;
  /* verilator lint_off UNUSED */
  wire [12:0] code_addr;
  /* verilator lint_on UNUSED */
  reg [15:0] insn;

  reg [15:0] ram_prog[0:4095] /* verilator public_flat */;
  always @(posedge clk) begin
    // $display("pc=%x", code_addr * 2);
    insn <= ram_prog[code_addr[11:0]];
    if (mem_wr)
      ram_prog[mem_addr[12:1]] <= dout;
  end

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

  reg io_wr_, io_rd_;
  /* verilator lint_off UNUSED */
  reg [15:0] dout_;
  reg [15:0] io_addr_;
  /* verilator lint_on UNUSED */

  always @(posedge clk) begin
    {io_rd_, io_wr_, dout_} <= {io_rd, io_wr, dout};
    if (io_rd | io_wr)
      io_addr_ <= mem_addr;
  end

  // ######   UART   ##########################################

  assign uart0_wr = io_wr_ & io_addr_[12];
  assign uart0_rd = io_rd_ & io_addr_[12];
  assign uart_w = dout_[7:0];

  // always @(posedge clk) begin
  //   if (uart0_wr)
  //     $display("--- out %x %c", uart_w, uart_w);
  //   if (uart0_rd)
  //     $display("--- in %x %c", uart0_data, uart0_data);
  // end

  // ######   IO PORTS   ######################################

  /*        bit READ            WRITE
      1000  12  UART RX         UART TX
      2000  13  misc.in
  */

  assign io_din =
    (io_addr_[12] ? {8'd0, uart0_data}                                  : 16'd0) |
    (io_addr_[13] ? {12'd0, 1'b0, 1'b0, uart0_valid, 1'b1} : 16'd0);

endmodule
