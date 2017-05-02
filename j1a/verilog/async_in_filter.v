module async_in_filter (
    input wire clk,
    input wire pin,
    output reg rd);
// This module is intended to accept up to a maximum 750 kHz async signal,
// and synchronise it safely to a 48 MHz clock. 
// It will add at least 27 clks of latency, and may not respond reliably to a 1MHz signal.
wire onereg;
SB_IO #(.PIN_TYPE(6'b0000_00)) inpin (
    .PACKAGE_PIN(pin),
    .CLOCK_ENABLE(1'b1),
    .INPUT_CLK(clk),
    .D_IN_0(onereg));
reg threereg, tworeg; always @(posedge clk) {threereg,tworeg} <= {tworeg,onereg};
// triple registering helps prevent metastability when synchronising an undefined signal into a clock domain.

// Final part is somewhat of a digital moving average glitch filter, with a digital Schmidt trigger output.
// this one takes 24 ticks to set rd on.
// saturates after 31 sequential highs.
// Then will take 24 sequential lows to turn off.
// Saturating back on zero after the 31st.
reg [4:0] fltr;
wire [1:0] tops = fltr[4:3]; // top two bits are used to decide whether to change output state.
// change the two above to change the timing.
//  (increase fltr size for slower signals,
// decrease for faster. should be no less than three bits.)
wire incr = ~&flrt & threereg;
wire decr = |flrt & ~threereg;
wire setr = &tops;
wire clrr = ~tops[1] & ~tops[0];
always @(posedge clk)
begin
  case({incr,decr})
	10: flrt <= flrt + 1;
	01: flrt <= flrt - 1;
	default: flrt <= flrt;
  endcase
  case({setr,clrr})
	10: rd <= 1'b1;
	01: rd <= 0'b0;
	default: rd <= rd;
  endcase
end

endmodule
