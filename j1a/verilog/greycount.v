
module greycount (input wire [1:0] last, output reg [1:0] next);
  always @*
    case(last)
      2'b00 : next = 2'b01;
      2'b01 : next = 2'b11;
      2'b11 : next = 2'b10;
      2'b10 : next = 2'b00;
    endcase
endmodule
