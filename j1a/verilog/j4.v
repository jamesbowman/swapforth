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
  
  reg [4:0] dsp, dspN [3:0];          // data stack pointers
  reg [`WIDTH-1:0] st0, st0N [3:0];   // top of data stacks
  
  
  reg [12:0] pc /* verilator public_flat */, pcN [3:0];           // program counters
  wire [12:0] pc_plus_1 = pc + 13'd1;
  
  reg reboot = 1;
  reg [3:0] kill_slot = 4'h0;

  assign mem_addr = st0[15:0];
  assign code_addr = pcN[0];

  // The D and R stacks
  wire [`WIDTH-1:0] st1n [3:0],  rst [3:0];
  reg [`WIDTH-1:0] st1, rst0;
  
  // stack delta controls
  reg [3:0] dspIn1, dspIn0, rspIn1, rspIn0; 
  wire [1:0] dspI, rspI;
  
  reg dstkW,rstkW; // data stack write / return stack write
  reg [3:0] dstkWn, rstkWn; // decoded write lines                   
                
  wire [`WIDTH-1:0] rstkD;      // return stack write value
  
  decoder24 msdec_dspI1(.en(dspI[1]), .a(slot), .d(dspIn1));
  decoder24 msdec_dspI0(.en(dspI[0]), .a(slot), .d(dspIn0));
  decoder24 msdec_rspI1(.en(rspI[1]), .a(slot), .d(rspIn1));
  decoder24 msdec_rspI0(.en(rspI[0]), .a(slot), .d(rspIn0));
  
  decoder24 msdec_dstkW(.en(dstkW), .a(slot), .d(dstkWn));
  decoder24 msdec_rstkW(.en(rstkW), .a(slot), .d(rstkWn));
  
  stack2 #(.DEPTH(16)) dstack0(.clk(clk), .rd(st1n[0]),  .we(dstkWn[0]), .wd(st0),   .delta({dspIn1[0], dspIn0[0]}));
  stack2 #(.DEPTH(19)) rstack0(.clk(clk), .rd(rst[0]), .we(rstkWn[0]), .wd(rstkD), .delta({rspIn1[0], rspIn0[0]}));
  
   
  stack2 #(.DEPTH(16)) dstack1(.clk(clk), .rd(st1n[1]),  .we(dstkWn[1]), .wd(st0),   .delta({dspIn1[1], dspIn0[1]}));
  stack2 #(.DEPTH(19)) rstack1(.clk(clk), .rd(rst[1]), .we(rstkWn[1]), .wd(rstkD), .delta({rspIn1[1], rspIn0[1]}));
  
  
  stack2 #(.DEPTH(16)) dstack2(.clk(clk), .rd(st1n[2]),  .we(dstkWn[2]), .wd(st0),   .delta({dspIn1[2], dspIn0[2]}));
  stack2 #(.DEPTH(19)) rstack2(.clk(clk), .rd(rst[2]), .we(rstkWn[2]), .wd(rstkD), .delta({rspIn1[2], rspIn0[2]}));
  
  
  stack2 #(.DEPTH(16)) dstack3(.clk(clk), .rd(st1n[3]),  .we(dstkWn[3]), .wd(st0),   .delta({dspIn1[3], dspIn0[3]}));
  stack2 #(.DEPTH(19)) rstack3(.clk(clk), .rd(rst[3]), .we(rstkWn[3]), .wd(rstkD), .delta({rspIn1[3], rspIn0[3]}));
  // note: might decrese stack depths assymetrically, since they'll be used for different things.
  
  always @*
  begin
    case (slot)
      2'b00: {st1, rst0} = {st1n[0] , rst[0]};
      2'b01: {st1, rst0} = {st1n[1] , rst[1]};
      2'b10: {st1, rst0} = {st1n[2] , rst[2]};
      2'b11: {st1, rst0} = {st1n[3] , rst[3]};
    endcase
  end
  
  // stack2 #(.DEPTH(24)) dstack(.clk(clk), .rd(st1),  .we(dstkW), .wd(st0),   .delta(dspI));
  // stack2 #(.DEPTH(24)) rstack(.clk(clk), .rd(rst0), .we(rstkW), .wd(rstkD), .delta(rspI));

  always @*
  begin
    // Compute the new value of st0. Could be pipelined now.
    casez ({pc[12], insn[15:8]})
      9'b1_???_?????: st0N[3] = insn;                    // literal
      9'b0_1??_?????: st0N[3] = { {(`WIDTH - 15){1'b0}}, insn[14:0] };    // literal
      9'b0_000_?????: st0N[3] = st0;                     // jump
      9'b0_010_?????: st0N[3] = st0;                     // call
      9'b0_001_?????: st0N[3] = st1;                     // conditional jump
      9'b0_011_?0000: st0N[3] = st0;                     // ALU operations...
      9'b0_011_?0001: st0N[3] = st1;
      9'b0_011_?0010: st0N[3] = st0 + st1;
      9'b0_011_?0011: st0N[3] = st0 & st1;
      9'b0_011_?0100: st0N[3] = st0 | st1;
      9'b0_011_?0101: st0N[3] = st0 ^ st1;
      9'b0_011_?0110: st0N[3] = ~st0;
      9'b0_011_?0111: st0N[3] = {`WIDTH{(st1 == st0)}};
      9'b0_011_?1000: st0N[3] = {`WIDTH{($signed(st1) < $signed(st0))}};
      9'b0_011_?1001: st0N[3] = {st0[`WIDTH - 1], st0[`WIDTH - 1:1]};
      9'b0_011_?1010: st0N[3] = {st0[`WIDTH - 2:0], 1'b0};
      9'b0_011_?1011: st0N[3] = rst0;
      9'b0_011_?1100: st0N[3] = io_din;
      9'b0_011_?1101: st0N[3] = io_din;
      9'b0_011_?1110: st0N[3] = {{(`WIDTH - 5){1'b0}}, dsp};
      9'b0_011_?1111: st0N[3] = {`WIDTH{(st1 < st0)}};
      default: st0N[3] = {`WIDTH{1'bx}};
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
    dspN[3] = dsp + {dspI[1], dspI[1], dspI[1], dspI};

    casez ({pc[12], insn[15:13]})
    4'b1_???:   {rstkW, rspI} = {1'b0,      2'b11};
    4'b0_010:   {rstkW, rspI} = {1'b1,      2'b01};
    4'b0_011:   {rstkW, rspI} = {func_T_R,  insn[3:2]};
    default:    {rstkW, rspI} = {1'b0,      2'b00};
    endcase

    casez ({reboot, pc[12], insn[15:13], insn[7], |st0})
    7'b1_0_???_?_?:   pcN[3] = 0;
    7'b0_0_000_?_?,
    7'b0_0_010_?_?,
    7'b0_0_001_?_0:   pcN[3] = insn[12:0];
    7'b0_1_???_?_?,
    7'b0_0_011_1_?:   pcN[3] = rst0[13:1];
    default:          pcN[3] = pc_plus_1;
    endcase
  end

  assign return_top = rst0[13:1]; // used by slot management for null tasks.

  always @(negedge resetq or posedge clk)
  begin
    if (!resetq) begin
      reboot <= 1'b1;
      { pc, dsp, st0, pcN[0], pcN[1], pcN[2] } <= 0;
      
      {dspN[0],dspN[1],dspN[2] } <= 0; 

      st0N[0] <= 0; // NB. [3] of each is not registered!
      st0N[1] <= 0;
      st0N[2] <= 0;
      
      slot <= 2'b00;
      kill_slot <= 4'h0;
    end else begin
      case(slot)// needs to come from a register so slot 0 can kill the others.
        2'b00:  reboot <= kill_slot[0]; 
        2'b01:  reboot <= kill_slot[1];
        2'b11:  reboot <= kill_slot[3];
        2'b10:  reboot <= kill_slot[2];
      endcase
      casez({kill_slot_rq, slot})
        6'b1???_??: kill_slot[3] <= 1'b1;
        6'b0???_11: kill_slot[3] <= 1'b0;
        
        6'b?1??_??: kill_slot[2] <= 1'b1;
        6'b?0??_10: kill_slot[2] <= 1'b0;
        
        6'b??1?_??: kill_slot[1] <= 1'b1;
        6'b??0?_01: kill_slot[1] <= 1'b0;
        
        6'b???1_??: kill_slot[0] <= 1'b1;
        6'b???0_00: kill_slot[0] <= 1'b0; 
      endcase
      //reboot <= 0; // whatever mechanism might be used so slot zero can reboot others should be here.
      { pc, dsp, st0} <= { pcN[0], dspN[0], st0N[0] };
      {pcN[0],pcN[1],pcN[2]} <= {pcN[1], pcN[2], pcN[3]};
      {dspN[0],dspN[1], dspN[2]} <= {dspN[1], dspN[2], dspN[3]};
      {st0N[0], st0N[1],st0N[2]} <= {st0N[1], st0N[2], st0N[3]};
      slot <= slotN;
    end
  end

endmodule
