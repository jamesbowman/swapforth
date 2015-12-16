
module decoder24 (input wire en, input wire [1:0] a, output wire [3:0] d);
  assign d[0] = (en & ~a[1] & ~a[0]);
  assign d[1] = (en & ~a[1] & a[0]);
  assign d[2] = (en & a[1] & ~a[0]);
  assign d[3] = (en & a[1] & a[0]);
endmodule

