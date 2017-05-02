`default_nettype none

module buart(
    input clk, // The master clock for this module
    input resetq, // Synchronous reset, active low
    input rx, // Incoming serial line
    output tx, // Outgoing serial line
    input rd, // read strobe  -- used only to clear valid flag.
    input wr, // write strobe   
    output reg valid, // Indicates a new byte is available. clears on read.
    output reg busy, // Low when transmit line is idle.
    input [7:0] tx_data, // Byte to transmit
    output reg [7:0] rx_data, // *Most recent* byte received -- whether or not the last was collected.
    output reg error // reception error
    );
// you can override these on a per-port basis, looks like:
//  buart #(.BAUD(115200)) _youruart (.clk(clk)...etc);
// or
//  buart #(.CLOCK_DIVIDE(312)) _uart1 (...
// The latter might be better for designs with non-48MHz clocks. 
parameter BAUD = 9600;
parameter CLKFREQ = 48000000;   // frequency of incoming signal 'clk'
parameter CLOCK_DIVIDE = (CLKFREQ / (BAUD * 4)); // clock rate (48Mhz) / (baud rate (460800) * 4)
// will probably want to support at least down to 9600 baud, which will require a CLOCK_DIVIDE == 1250

localparam CDSIZE = $clog2(CLOCK_DIVIDE)+1; // one more to accomodate assumed signed arithmatic
reg [5:0] bytephase;
reg [CDSIZE-1:0] rxclkcounter; 
wire rxqtick = rxclkcounter == CLOCK_DIVIDE; // strobes high one clk every 1/4 bit time
wire rxrst = rx & (~|bytephase); // rx goes low with the beginning of the start bit. synchronous to system clk, not sample clk.
always @(posedge clk) rxclkcounter <= rxrst | rxqtick ? 1 : rxclkcounter + 1; // initially held in reset
// very important: idle rx line holds rxrst asserted,
// this goes on *until* the start edge is found.
// thus synchronising further sampling to that edge, rather than remaining in phase with however it was reset.
 
wire rxstop = bytephase == 6'd40; // 11th sample 'tick' would have been at 42.
wire nonstarter;
always @(posedge clk) bytephase <= rxstop|nonstarter ? 0 : rxqtick ? bytephase + 1 : bytephase;
wire sample = (bytephase[1:0] == 2'b10) & rxqtick; // one clk for each of ten bits
// note sample is false while rxrst is true.
assign nonstarter = (bytephase == 6'd2) & rx; // start bit should still be low when sample strobes first.
// if it isn't, then it will go back to a rxrst state.

// after this point, we have a sample strobe, a rxstop strobe
reg [9:0] capture; always @(posedge clk) capture <= sample ? {rx, capture[9:1]} : capture;
// note bits are sent least-significant first.
wire startbit = capture[0]; // valid when rxstop strobes, and until rxrst releases for the next byte.
wire stopbit = capture[9];
wire good = stopbit&~startbit; // valid when rxstop is asserted. stop bit should be 1, start bit should have been zero.
always @(posedge clk) 
begin
valid <= rd ? 1'b0 : rxstop & good ? 1'b1 : valid;
rx_data <= rxstop & good ? capture[8:1] : rx_data;
error <= nonstarter ? 1'b1 : rxstop ? ~good : error ;
end
// tx parts
reg [CDSIZE+1:0] txclkcounter; // note, two extra bits to accomodate a limit 4x as large.
wire txtick = txclkcounter == 4*CLOCK_DIVIDE; // ticks for a clk once every bit, not every quarter bit.
always @(posedge clk) txclkcounter <= txtick ? 1 : txclkcounter + 1;
// note txclkcounter never needs to be reset out-of-phase with itself.
reg [3:0] sentbits; 
wire done = sentbits == 4'd10; // eventually stays 'done'. Reset to zero again when wr strobes.
always @(posedge clk) sentbits <= txtick & ~done ? sentbits + 1 : wr ? 4'd0 : sentbits ;
reg [9:0] sender;
// wr strobe might come any clk, not synchronous to txtick. No real need to force txtick to be synchronous to it either.
always @(posedge clk) sender <= wr ? {tx_data, 1'b0, 1'b1} : txtick ? {1'b1, sender[9:1]} : sender;
assign tx = sender[0]; // wr loads this 1, because tranmission doesn't start until the next txtick, whenever it arrives.
assign busy = ~done;
endmodule
