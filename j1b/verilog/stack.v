`default_nettype none
`define WIDTH 32

module stack( 
  input wire clk,
  output wire [`WIDTH-1:0] rd,
  input wire we,
  input wire [1:0] delta,
  input wire [`WIDTH-1:0] wd);
  parameter DEPTH = 18;
  localparam BITS = (`WIDTH * DEPTH) - 1;

  wire move = delta[0];

  reg [31:0] head;
  reg [BITS:0] tail;
  wire [31:0] headN;
  wire [BITS:0] tailN;

  assign headN = we ? wd : tail[31:0];
  assign tailN = delta[1] ? {32'h55aa55aa, tail[BITS:32]} : {tail[BITS-32:0], head};

  always @(posedge clk) begin
    if (we | move)
      head <= headN;
    if (move)
      tail <= tailN;
  end

  assign rd = head;
endmodule

