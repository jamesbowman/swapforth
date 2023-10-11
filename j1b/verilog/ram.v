`default_nettype none

module bram_tdp #(
    parameter DATA = 72,
    parameter ADDR = 10
) (
    // Port A
    input   wire                a_clk,
    input   wire                a_wr,
    input   wire    [ADDR-1:0]  a_addr,
    input   wire    [DATA-1:0]  a_din,
    output  reg     [DATA-1:0]  a_dout,
     
    // Port B
    input   wire                b_clk,
    input   wire                b_wr,
    input   wire    [ADDR-1:0]  b_addr,
    input   wire    [DATA-1:0]  b_din,
    output  reg     [DATA-1:0]  b_dout
);
 
// Shared memory
reg [DATA-1:0] mem [(2**ADDR)-1:0];
  initial begin
    $readmemh("../build/nuc.hex", mem);
  end
 
// Port A
always @(posedge a_clk) begin
    a_dout      <= mem[a_addr];
   if(a_wr) begin
      a_dout      <= a_din;
      mem[a_addr] <= a_din;
    end
end
 
// Port B
always @(posedge b_clk) begin
    b_dout      <= mem[b_addr];
    if(b_wr) begin
        b_dout      <= b_din;
        mem[b_addr] <= b_din;
    end
end
 
endmodule

// A 32Kbyte RAM (8192x32) with two ports:
//   port a, 32 bits read/write 
//   port b, 16 bits read-only, lower 16K only

module ram16k(
  input wire        clk,

  input  wire[15:0] a_addr,
  output wire[31:0] a_q,
  input  wire[31:0] a_d,
  input  wire       a_wr,

  input  wire[12:0] b_addr,
  output wire[15:0] b_q);

  wire [31:0] insn32;

  bram_tdp #(.DATA(32), .ADDR(13)) nram (
    .a_clk(clk),
    .a_wr(a_wr),
    .a_addr(a_addr[14:2]),
    .a_din(a_d),
    .a_dout(a_q),

    .b_clk(clk),
    .b_wr(1'b0),
    .b_addr({1'b0, b_addr[12:1]}),
    .b_din(32'd0),
    .b_dout(insn32));

  reg ba_;
  always @(posedge clk)
    ba_ <= b_addr[0];
  assign b_q = ba_ ? insn32[31:16] : insn32[15:0];

endmodule
