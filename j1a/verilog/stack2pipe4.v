`default_nettype none
`define WIDTH 16

module stack2pipe4( 
  input wire clk,
  output wire [`WIDTH-1:0] rd,
  input wire we,
  input wire [1:0] delta,
  input wire [`WIDTH-1:0] wd);
  parameter DEPTH = 18; 
  localparam BITS = (`WIDTH * DEPTH) - 1; 
  
  localparam STATESIZE = `WIDTH * (DEPTH + 1); // complete size of a stack, ie tail+head.
  // there are four stacks in total, accessed always in round-robin order.
  
  localparam STATEBITS = STATESIZE - 1; // for wire out of delay
  
  localparam DELAYBITS = (STATESIZE * 3) - 1; // bits to hold the other three stacks.

  

  wire move = delta[0];
  wire pop = delta[1];

   // these two still written to "now", ie, are the results to save from the present cycle.
  reg [15:0] head;
  reg [BITS:0] tail;
  
  reg [DELAYBITS:0] delay;
  
  wire [15:0] headN, oldhead;
  wire [BITS:0] tailN, oldtail;
  
  wire [DELAYBITS:0] delayN;
  
 
   // read from the delay fifo, replaced head and tail as the place to read from the old version of current stack.
  assign {oldtail, oldhead} = delay[STATEBITS:0]; 
  assign rd = oldhead; 
  

   // note these retain old values if not move (and not we and not push). This used to be implicit, but can't be now, since head and tail will cycle through all the stacks, even if neither a move nor a write.
  assign headN = we ? wd : (move ? oldtail[15:0] : oldhead);
  assign tailN = move ? (pop ? {16'h55aa, oldtail[BITS:16]} : {oldtail[BITS-16:0], oldhead}) : oldtail;
  
   // this is a clock stale already, since it takes it *from* head and tail.
   // delay will delay it another three clock cycles.
  assign delayN = {tail, head, delay[DELAYBITS:STATESIZE]};
  
  

  always @(posedge clk) begin
     // pass around the other three stacks.
    delay <= delayN;
    
     // update the current stack.
    head <= headN;
    tail <= tailN;
  end

 



`ifdef VERILATOR
  int depth /* verilator public_flat */;
  always @(posedge clk) begin
    if (delta == 2'b11)
      depth <= depth - 1;
    if (delta == 2'b01)
      depth <= depth + 1;
  end
`endif

endmodule

