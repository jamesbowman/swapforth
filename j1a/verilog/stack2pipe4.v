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
  
  localparam STATESIZE = `WIDTH * (DEPTH + 1); // complete size of stack, ie tail+head
  
  localparam STATEBITS = STATESIZE - 1; // for wire into delay and out of delay
  
  localparam DELAYBITS = (STATESIZE * 3) - 1; // bits to hold the other three stacks.

  wire move = delta[0];

    // these two still written to "now", ie, are the results to save from the present cycle.
  reg [15:0] head;
  reg [BITS:0] tail;
  
  reg [DELAYBITS:0] delay;
  
  wire [15:0] headN, heado;
  wire [BITS:0] tailN, tailo;
  
  wire [STATEBITS:0] stackstate;
  wire [DELAYBITS:0] delayN;

    // read from the delay fifo, replaced head and tail as place read from old version of current stack.
  assign {tailo, heado} = delay[STATEBITS:0]; 

  assign headN = we ? wd : tailo[15:0];
  assign tailN = delta[1] ? {16'h55aa, tailo[BITS:16]} : {tailo[BITS-16:0], heado};
  
    // this is a clock stale already, since it takes it *from* head and tail.
  assign stackstate = {tail, head};
  
    // delay will delay it another three clock cycles.
  assign delayN = {stackstate, delay[DELAYBITS:STATESIZE]};
  
  

  always @(posedge clk) begin
      // pass around the other three stacks.
    delay <= delayN;
    
      // update the current stack.
    if (we | move)
      head <= headN;
    if (move)
      tail <= tailN;
      
      
  end

  assign rd = heado;



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

