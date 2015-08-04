`include "common.h"

module j1(
  input wire clk,
  input wire resetq,

  output wire io_rd,
  output wire io_wr,
  output wire [15:0] mem_addr,
  output wire mem_wr,
  output wire [`WIDTH-1:0] dout,
  input  wire [`WIDTH-1:0] mem_din,

  input  wire [`WIDTH-1:0] io_din,

  output wire [12:0] code_addr,
  input  wire [15:0] insn);

  reg [4:0] dsp, dspN;      // Data stack pointer
  reg [`WIDTH-1:0] st0;     // Top of data stack
  reg [`WIDTH-1:0] st0N;
  reg dstkW;                // D stack write

  reg [12:0] pc, pcN;      
  reg [4:0] rsp, rspN;
  reg rstkW;          // R stack write
  wire [`WIDTH-1:0] rstkD;   // R stack write value
  reg reboot = 1;
  wire [12:0] pc_plus_1 = pc + 1;

  assign mem_addr = st0[15:0];
  assign code_addr = {pcN};

  // The D and R stacks
  wire [`WIDTH-1:0] st1, rst0;
  stack dstack(.clk(clk), .ra(dsp), .rd(st1), .we(dstkW), .wa(dspN), .wd(st0));
  stack rstack(.clk(clk), .ra(rsp), .rd(rst0), .we(rstkW), .wa(rspN), .wd(rstkD));

  always @*
  begin
    // Compute the new value of st0
    casez ({insn[15:8]})
      8'b1??_?????: st0N = { {(`WIDTH - 15){1'b0}}, insn[14:0] };    // literal
      8'b000_?????: st0N = st0;                     // jump
      8'b010_?????: st0N = st0;                     // call
      8'b001_?????: st0N = st1;                     // conditional jump
      8'b011_?0000: st0N = st0;                     // ALU operations...
      8'b011_?0001: st0N = st1;
      8'b011_?0010: st0N = st0 + st1;
      8'b011_?0011: st0N = st0 & st1;
      8'b011_?0100: st0N = st0 | st1;
      8'b011_?0101: st0N = st0 ^ st1;
      8'b011_?0110: st0N = ~st0;
      8'b011_?0111: st0N = {`WIDTH{(st1 == st0)}};
      8'b011_?1000: st0N = {`WIDTH{($signed(st1) < $signed(st0))}};
      8'b011_?1001: st0N = st1 >> st0[4:0];
      8'b011_?1010: st0N = st1 << st0[4:0];
      8'b011_?1011: st0N = rst0;
      8'b011_?1100: st0N = mem_din;
      8'b011_?1101: st0N = io_din;
      8'b011_?1110: st0N = {{(`WIDTH - 8){1'b0}}, rsp, dsp};
      8'b011_?1111: st0N = {`WIDTH{(st1 < st0)}};
      default: st0N = {`WIDTH{1'bx}};
    endcase
  end

  wire func_T_N =   (insn[6:4] == 1);
  wire func_T_R =   (insn[6:4] == 2);
  wire func_write = (insn[6:4] == 3);
  wire func_iow =   (insn[6:4] == 4);
  wire func_ior =   (insn[6:4] == 5);

  wire is_alu = (insn[15:13] == 3'b011);
  assign mem_wr = !reboot & is_alu & func_write;
  assign dout = st1;
  assign io_wr = !reboot & is_alu & func_iow;
  assign io_rd = !reboot & is_alu & func_ior;

  assign rstkD = (insn[13] == 1'b0) ? {{(`WIDTH - 14){1'b0}}, pc_plus_1, 1'b0} : st0;

  reg [4:0] dspI, rspI;
  always @*
  begin
    casez ({insn[15:13]})
    3'b1??:   {dstkW, dspI} = {1'b1,      5'b00001};
    3'b001:   {dstkW, dspI} = {1'b0,      5'b11111};
    3'b011:   {dstkW, dspI} = {func_T_N,  {insn[1], insn[1], insn[1], insn[1:0]}};
    default:  {dstkW, dspI} = {1'b0,      5'b00000};
    endcase
    dspN = dsp + dspI;

    casez ({insn[15:13]})
    3'b010:   {rstkW, rspI} = {1'b1,      5'b00001};
    3'b011:   {rstkW, rspI} = {func_T_R,  {insn[3], insn[3], insn[3], insn[3:2]}};
    default:  {rstkW, rspI} = {1'b0,      5'b00000};
    endcase
    rspN = rsp + rspI;

    casez ({reboot, insn[15:13], insn[7], |st0})
    6'b1_???_?_?:   pcN = 0;
    6'b0_000_?_?,
    6'b0_010_?_?,
    6'b0_001_?_0:   pcN = insn[12:0];
    6'b0_011_1_?:   pcN = rst0[13:1];
    default:        pcN = pc_plus_1;
    endcase
  end

  always @(negedge resetq or posedge clk)
  begin
    if (!resetq) begin
      reboot <= 1'b1;
      { pc, dsp, st0, rsp } <= 0;
    end else begin
      reboot <= 0;
      { pc, dsp, st0, rsp } <= { pcN, dspN, st0N, rspN };
    end
  end
endmodule
