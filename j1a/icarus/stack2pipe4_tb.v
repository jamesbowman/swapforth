`timescale 1 ns / 1 ps

`include "../verilog/greycount.v"

module top;
  reg clk = 1'b0;
  integer t = 0;
  
  
  reg [15:0] wd = 16'b1;
  wire [15:0] rd;
  reg we = 1'b1;
  reg move = 1'b1;
  reg pop = 1'b0;
  reg twe = 1'b1;
  reg tmove = 1'b1;
  reg tpop = 1'b0;  
  
  stack2pipe4 #(.DEPTH(4)) dstack_(.clk(clk), .rd(rd),  .we(we), .wd(wd),   .delta({pop,move}));
  // delta[0] is 'move\freeze'
  // delta[1] is 'pop\push'
  
  
  reg [1:0] state = 2'b00;
  wire [1:0] last,next;
  greycount gc_(.last(last), .next(next));
  assign last = state;
  
  always @(posedge clk or negedge clk) begin
    if (!clk) begin
      state <= next;
      wd <= wd + 1;
    end
    t = t + 1;
    
  end
  
  always @(posedge clk) begin
    case (state)
      2'b10:  begin
        {we, move, pop} <= {twe, tmove, tpop};
        
      end 
      default: begin
        {we, move, pop} <= (t<9)? 3'b110 : 3'b000;
      end
    endcase
  end
  
  
  
  initial
  begin
    $display("Stack2pipe4 testbench.\n t, clk, state, we, move\\freeze, pop\\push, wd, rd");
  end
  
  always @* begin
    if (t==64) {twe, tmove, tpop} <= 3'b011; //
    if (t==64) {twe, tmove, tpop} <= 3'b011; // start popping out data.
    
    clk <=  !clk;
    $display(t, " ", clk, " S:", state, ," ", we, move, pop, wd, rd);
    if (t>128) $finish;
  end
  
  
  
endmodule
