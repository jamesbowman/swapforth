module top(
  input clk,
  input resetq,
  output [15:0] tail);
  parameter FIRMWARE = "<firmware>";

  j1 _j1 (.clk(clk), .resetq(resetq));

endmodule
