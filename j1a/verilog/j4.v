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

  input  wire [`WIDTH-1:0] io_din, //note: this is always a cycle late, as io_addr_ is registered because EASE_IO_TIMING is always defined in j4a.v

  output wire [12:0] code_addr,
  input  wire [15:0] insn,
  output wire [1:0] io_slot,
  output wire [15:0] return_top,
  input wire [3:0] kill_slot_rq);
  
  reg [1:0] slot, slotN; // slot select
  
  greycount tc(.last(slot), .next(slotN));
  
  reg [4:0] dsp, dspN;// data stack pointers, -N is not registered,
  reg [14:0] dspD;    // -D is the delay shift register.
  
  reg [`WIDTH-1:0] st0, st0N;// top of data stacks
  reg [3*`WIDTH-1:0] st0D;   // top delay
  
  
  reg [12:0] pc /* verilator public_flat */, pcN; // program counters
  reg [38:0] pcD; // pc Delay
            
  wire [12:0] pc_plus_1 = pc + 13'd1;
  
  reg reboot = 1;
  reg [3:0] kill_slot = 4'h0;

  assign mem_addr = st0[15:0];
  assign code_addr = pcD[25:13];// was pcN;. The read for next context needs to be pre-fetched from the ram.
  // because this *was* pcN, we will instead use what will be pc one clock cycle in the future, which is pcD[12:0]. But wait:
  // We make this two clock cycles into the future, and then register again insn so
  // that the instruction is already available, not needing to be read from ram... This is why it's pcD[25:13], then:
  
  reg [15:0] insn_now = 0;

   // adds a clock delay, but this is fine.
  always @(posedge clk) insn_now <= insn; 
  // note every reference below here which was to insn will now be to inst_now instead.
  // this automatically includes all memory reads, instructions or otherwise.

 
  // io_din is registered once in j4a.v, so it still needs 3 delays to be good.
  reg [3*`WIDTH-1:0] io_din_delay = 0;
  always @(posedge clk) io_din_delay <= {io_din, io_din_delay[3*`WIDTH-1:`WIDTH]};
   wire [`WIDTH-1:0] io_din_now = io_din_delay[`WIDTH-1:0];
  
  
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
    casez ({pc[12], insn_now[15:8]})
      9'b1_???_?????: st0N = insn_now;                    // fetch from ram cycle. pc[12] isn't part of ram memory, rather is used to signify that a fetch from ram was requested, not a call.
      9'b0_1??_?????: st0N = { {(`WIDTH - 15){1'b0}}, insn_now[14:0] };    // literal
      9'b0_000_?????: st0N = st0;                     // jump
      9'b0_010_?????: st0N = st0;                     // call, or fetch from ram if insn[12] is set.
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
      9'b0_011_?1100: st0N = io_din_now; // was io_din, which was a cycle late like insn and st0/st1/rst0/pc/dsp etc
      9'b0_011_?1101: st0N = io_din_now;
      9'b0_011_?1110: st0N = {{(`WIDTH - 5){1'b0}}, dsp};
      9'b0_011_?1111: st0N = {`WIDTH{(st1 < st0)}};
      default: st0N = {`WIDTH{1'bx}};
    endcase
  end

  wire func_T_N =   (insn_now[6:4] == 1);
  wire func_T_R =   (insn_now[6:4] == 2);
  wire func_write = (insn_now[6:4] == 3);
  wire func_iow =   (insn_now[6:4] == 4);
  wire func_ior =   (insn_now[6:4] == 5);

  wire is_alu = !pc[12] & (insn_now[15:13] == 3'b011);
  assign mem_wr = !reboot & is_alu & func_write;
  assign dout = st1;
  assign io_wr = !reboot & is_alu & func_iow;
  assign io_rd = !reboot & is_alu & func_ior;
  assign io_slot = slot;

   // return stack pushes pc_plus_1 for call only, or pushes st0 if the opcode asks.
  assign rstkD = (insn_now[13] == 1'b0) ? {{(`WIDTH - 14){1'b0}}, pc_plus_1, 1'b0} : st0;

  always @*
  begin
    casez ({pc[12], insn_now[15:13]})
    4'b1_???, /* load from ram 2nd cycle */
    4'b0_1??: /* immediate */ {dstkW, dspI} = {1'b1,      2'b01}; // push st0
    4'b0_001: /* 0branch */ {dstkW, dspI} = {1'b0,      2'b11}; // pop d
    4'b0_011: /* ALU  */ {dstkW, dspI} = {func_T_N,  {insn_now[1:0]}}; // as ALU opcode asks
    default:    {dstkW, dspI} = {1'b0,      2'b00}; // nop d stack
    endcase
    dspN = dsp + {dspI[1], dspI[1], dspI[1], dspI};

    casez ({pc[12], insn_now[15:13]})
    4'b1_???: /* readram */  {rstkW, rspI} = {1'b0,      2'b11};// pop r to pcN, so execution continues after an inserted fetch from ram cycle
    4'b0_010: /* call */   {rstkW, rspI} = {1'b1,      2'b01}; // push PC+1 to rstkD. Abused with 13th bit set to allow fetches from ram.
    4'b0_011: /* ALU  */  {rstkW, rspI} = {func_T_R,  insn_now[3:2]}; // as ALU opcode asks.
    default:    {rstkW, rspI} = {1'b0,      2'b00}; // nop r stack, same on jumps.
    endcase

    casez ({reboot, pc[12], insn_now[15:13], insn_now[7], |st0})
    7'b1_?_???_?_?:   pcN = 0; // reboot request must override all else, even a fetch cycle.
    7'b0_0_000_?_?,
    7'b0_0_010_?_?,
    7'b0_0_001_?_0:   pcN = insn_now[12:0];
    7'b0_1_???_?_?, /* fetch from ram cycle, abuses instruction fetch to load the stack instead */
    7'b0_0_011_1_?:   pcN = rst0[13:1]; // r stack is 16 bits wide, but PC is always even.
    default:          pcN = pc_plus_1;
    endcase
  end

  assign return_top = {2'b0,rst0[13:0]};

  always @(posedge clk) begin
    pcD <= {pcN, pcD[38:13]};
    dspD <= {dspN, dspD[14:5]};
    st0D <= {st0N, st0D[47:16]};
  end

  always @(negedge resetq or posedge clk) begin
    if (!resetq) begin
      reboot <= 1'b1;
      { pc, dsp, st0} <= 0;
      
      slot <= 2'b00;
      kill_slot <= 4'hf;
    end else begin
      // reboot needs to be set a clock in advance of the targeted slot. 
                                    // kill_slot_rq is read-ahead in case the next thread to execute's time should be up already.
      reboot <= kill_slot[slotN] | kill_slot_rq[slotN]; 
      
     	// kill_slot register holds the signals until the right time, and are auto-cleared as each slot is reached, as it will already have been reset by the clock before.
      kill_slot[3] <= kill_slot_rq[3] ? 1'b1 : ( (slot == 2'd3) ? 1'b0 : kill_slot[3]) ;
      kill_slot[2] <= kill_slot_rq[2] ? 1'b1 : ( (slot == 2'd2) ? 1'b0 : kill_slot[2]) ;
      kill_slot[1] <= kill_slot_rq[1] ? 1'b1 : ( (slot == 2'd1) ? 1'b0 : kill_slot[1]) ; 
      kill_slot[0] <= kill_slot_rq[0] ? 1'b1 : ( (slot == 2'd0) ? 1'b0 : kill_slot[0]) ; 

      pc <= pcD[12:0];
      dsp <= dspD[4:0];
      st0 <= st0D[15:0];

      slot <= slotN;
    end
  end

endmodule
