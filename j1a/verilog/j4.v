`default_nettype none
`define WIDTH 16


module j4(
  input wire clk,
  input wire resetq,

  output wire io_rd,
  output wire io_wr,
  output wire [15:0] mem_addr,
  output wire mem_wr,
  output wire [`WIDTH-1:0] dout,

  input  wire [`WIDTH-1:0] io_din,

  output wire [12:0] code_addr,
  input  wire [15:0] insn,
  output wire [1:0] io_slot,
  output wire [15:0] return_top,
  input wire [3:0] kill_slot_rq);
  
  reg [1:0] slot, slotN; // slot select
  
  greycount tc(.last(slot), .next(slotN));
  
  reg [4:0] dsp, dspN, dspD [2:0];          // data stack pointers, -N is not registered, -D are the delay registers.
  reg [`WIDTH-1:0] st0, st0N, st0D [2:0];   // top of data stacks
  
  
  reg [12:0] pc /* verilator public_flat */, pcN, pcD [2:0];           // program counters
  wire [12:0] pc_plus_1 = pc + 13'd1;
  
  reg reboot = 1;
  reg [3:0] kill_slot = 4'h0;

  assign mem_addr = st0[15:0];
  assign code_addr = pcN;

  // The D and R stacks
  wire [`WIDTH-1:0] st1, rst0;
  
  // stack delta controls 
  wire [1:0] dspI, rspI;
  
  reg dstkW,rstkW; // data stack write / return stack write
 
  wire [`WIDTH-1:0] rstkD;      // return stack write value
  
  stack2pipe4 #(.DEPTH(16)) dstack_(.clk(clk), .rd(st1),  .we(dstkW), .wd(st0),   .delta(dspI));
  stack2pipe4 #(.DEPTH(19)) rstack_(.clk(clk), .rd(rst0), .we(rstkW), .wd(rstkD), .delta(rspI));

  
  // stack2 #(.DEPTH(24)) dstack(.clk(clk), .rd(st1),  .we(dstkW), .wd(st0),   .delta(dspI));
  // stack2 #(.DEPTH(24)) rstack(.clk(clk), .rd(rst0), .we(rstkW), .wd(rstkD), .delta(rspI));

  always @*
  begin
    // Compute the new value of st0. Could be pipelined now.
    casez ({pc[12], insn[15:8]})
      9'b1_???_?????: st0N = insn;                    // literal
      9'b0_1??_?????: st0N = { {(`WIDTH - 15){1'b0}}, insn[14:0] };    // literal
      9'b0_000_?????: st0N = st0;                     // jump
      9'b0_010_?????: st0N = st0;                     // call
      9'b0_001_?????: st0N = st1;                     // conditional jump
      9'b0_011_?0000: st0N = st0;                     // ALU operations...
      9'b0_011_?0001: st0N = st1;
      9'b0_011_?0010: st0N = st0 + st1;
      9'b0_011_?0011: st0N = st0 & st1;
      9'b0_011_?0100: st0N = st0 | st1;
      9'b0_011_?0101: st0N = st0 ^ st1;
      9'b0_011_?0110: st0N = ~st0;
      9'b0_011_?0111: st0N = {`WIDTH{(st1 == st0)}};
      9'b0_011_?1000: st0N = {`WIDTH{($signed(st1) < $signed(st0))}};
      9'b0_011_?1001: st0N = {st0[`WIDTH - 1], st0[`WIDTH - 1:1]};
      9'b0_011_?1010: st0N = {st0[`WIDTH - 2:0], 1'b0};
      9'b0_011_?1011: st0N = rst0;
      9'b0_011_?1100: st0N = io_din;
      9'b0_011_?1101: st0N = io_din;
      9'b0_011_?1110: st0N = {{(`WIDTH - 5){1'b0}}, dsp};
      9'b0_011_?1111: st0N = {`WIDTH{(st1 < st0)}};
      default: st0N = {`WIDTH{1'bx}};
    endcase
  end

  wire func_T_N =   (insn[6:4] == 1);
  wire func_T_R =   (insn[6:4] == 2);
  wire func_write = (insn[6:4] == 3);
  wire func_iow =   (insn[6:4] == 4);
  wire func_ior =   (insn[6:4] == 5);

  wire is_alu = !pc[12] & (insn[15:13] == 3'b011);
  assign mem_wr = !reboot & is_alu & func_write;
  assign dout = st1;
  assign io_wr = !reboot & is_alu & func_iow;
  assign io_rd = !reboot & is_alu & func_ior;
  assign io_slot = slot;

  assign rstkD = (insn[13] == 1'b0) ? {{(`WIDTH - 14){1'b0}}, pc_plus_1, 1'b0} : st0;

  always @*
  begin
    casez ({pc[12], insn[15:13]})
    4'b1_???,
    4'b0_1??:   {dstkW, dspI} = {1'b1,      2'b01};
    4'b0_001:   {dstkW, dspI} = {1'b0,      2'b11};
    4'b0_011:   {dstkW, dspI} = {func_T_N,  {insn[1:0]}};
    default:    {dstkW, dspI} = {1'b0,      2'b00};
    endcase
    dspN = dsp + {dspI[1], dspI[1], dspI[1], dspI};

    casez ({pc[12], insn[15:13]})
    4'b1_???:   {rstkW, rspI} = {1'b0,      2'b11};
    4'b0_010:   {rstkW, rspI} = {1'b1,      2'b01};
    4'b0_011:   {rstkW, rspI} = {func_T_R,  insn[3:2]};
    default:    {rstkW, rspI} = {1'b0,      2'b00};
    endcase

    casez ({reboot, pc[12], insn[15:13], insn[7], |st0})
    7'b1_0_???_?_?:   pcN = 0;
    7'b0_0_000_?_?,
    7'b0_0_010_?_?,
    7'b0_0_001_?_0:   pcN = insn[12:0];
    7'b0_1_???_?_?,
    7'b0_0_011_1_?:   pcN = rst0[13:1];
    default:          pcN = pc_plus_1;
    endcase
  end

  assign return_top = {2'b0,rst0[13:0]};

  always @(posedge clk)
  begin
    if (!resetq) begin
      reboot <= 1'b1;
      { pc, dsp, st0} <= 0;
      
      { pcD[0], pcD[1], pcD[2] } <= 0;
      {dspD[0],dspD[1],dspD[2] } <= 0; 
      { st0D[0], st0D[1], st0D[2]} <= 0;
      
      slot <= 2'b00;
      kill_slot <= 4'h0;
    end else begin
      
      reboot <= kill_slot[slotN] | kill_slot_rq[slotN]; 
      

      kill_slot[3] <= kill_slot_rq[3] ? 1'b1 : ( (slot == 2'd3) ? 1'b0 : kill_slot[3]) ;
      kill_slot[2] <= kill_slot_rq[2] ? 1'b1 : ( (slot == 2'd2) ? 1'b0 : kill_slot[2]) ;
      kill_slot[1] <= kill_slot_rq[1] ? 1'b1 : ( (slot == 2'd1) ? 1'b0 : kill_slot[1]) ; 
      kill_slot[0] <= kill_slot_rq[0] ? 1'b1 : ( (slot == 2'd0) ? 1'b0 : kill_slot[0]) ; 

      { pc, dsp, st0} <= { pcD[2], dspD[2], st0D[2] };
      
      {pcD[2],pcD[1],pcD[0]} <= {pcD[1], pcD[0], pcN};
      {dspD[2],dspD[1], dspD[0]} <= {dspD[1], dspD[0], dspN};
      {st0D[2], st0D[1],st0D[0]} <= {st0D[1], st0D[0], st0N};
      slot <= slotN;
    end
  end

endmodule
