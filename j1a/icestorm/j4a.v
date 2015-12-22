`timescale 1 ns / 1 ps

`default_nettype none
`define WIDTH 16

module SB_RAM2048x2(
	output [1:0] RDATA,
	input        RCLK, RCLKE, RE,
	input  [10:0] RADDR,
	input         WCLK, WCLKE, WE,
	input  [10:0] WADDR,
	input  [1:0] MASK, WDATA
);
	parameter INIT_0 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_1 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_2 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_3 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_4 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_5 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_6 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_7 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_8 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_9 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_A = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_B = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_C = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_D = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_E = 256'h0000000000000000000000000000000000000000000000000000000000000000;
	parameter INIT_F = 256'h0000000000000000000000000000000000000000000000000000000000000000;

  wire [15:0] rd;

  SB_RAM40_4K #(
    .WRITE_MODE(3),
    .READ_MODE(3),
    .INIT_0(INIT_0),
    .INIT_1(INIT_1),
    .INIT_2(INIT_2),
    .INIT_3(INIT_3),
    .INIT_4(INIT_4),
    .INIT_5(INIT_5),
    .INIT_6(INIT_6),
    .INIT_7(INIT_7),
    .INIT_8(INIT_8),
    .INIT_9(INIT_9),
    .INIT_A(INIT_A),
    .INIT_B(INIT_B),
    .INIT_C(INIT_C),
    .INIT_D(INIT_D),
    .INIT_E(INIT_E),
    .INIT_F(INIT_F)
  ) _ram (
    .RDATA(rd),
    .RADDR(RADDR),
    .RCLK(RCLK), .RCLKE(RCLKE), .RE(RE),
    .WCLK(WCLK), .WCLKE(WCLKE), .WE(WE),
    .WADDR(WADDR),
    .MASK(16'h0000), .WDATA({4'b0, WDATA[1], 7'b0, WDATA[0], 3'b0}));

  assign RDATA[0] = rd[3];
  assign RDATA[1] = rd[11];

endmodule

module ioport(
  input clk,
  inout [7:0] pins,
  input we,
  input [7:0] wd,
  output [7:0] rd,
  input [7:0] dir);

  genvar i;
  generate 
    for (i = 0; i < 8; i = i + 1) begin : io
      // 1001   PIN_OUTPUT_REGISTERED_ENABLE 
      //     01 PIN_INPUT 
      SB_IO #(.PIN_TYPE(6'b1001_01)) _io (
        .PACKAGE_PIN(pins[i]),
        .CLOCK_ENABLE(we),
        .OUTPUT_CLK(clk),
        .D_OUT_0(wd[i]),
        .D_IN_0(rd[i]),
        .OUTPUT_ENABLE(dir[i]));
    end
  endgenerate

endmodule

module outpin(
  input clk,
  output pin,
  input we,
  input wd,
  output rd);

  SB_IO #(.PIN_TYPE(6'b0101_01)) _io (
        .PACKAGE_PIN(pin),
        .CLOCK_ENABLE(we),
        .OUTPUT_CLK(clk),
        .D_OUT_0(wd),
        .D_IN_0(rd));
endmodule

module inpin(
  input clk,
  input pin,
  output rd);

  SB_IO #(.PIN_TYPE(6'b0000_00)) _io (
        .PACKAGE_PIN(pin),
        .INPUT_CLK(clk),
        .D_IN_0(rd));
endmodule

module top(input pclk, 

           output D1, 
           output D2, 
           output D3, 
           output D4, 
           output D5,
           output D6,   // new on hx8kbb
           output D7,   // "
           output D8,   // "

           output TXD,        // UART TX
           input RXD,         // UART RX

           output PIOS_00,    // flash SCK
           input PIOS_01,     // flash MISO
           output PIOS_02,    // flash MOSI
           output PIOS_03,    // flash CS

           inout PIO1_02,    // PMOD 1 // FIXME: these will be assigned from right to left starting with top row of J2, (oriented to read the pin numbers) but only the first 24 of all those for now.
           inout PIO1_03,    // J2 5
           inout PIO1_04,    // J2 9
           inout PIO1_05,    
           inout PIO1_06,    
           inout PIO1_07,    
           inout PIO1_08,    
           inout PIO1_09,    // FIXME: ADD IN ALL THE OTHER PINS, EXTEND PORTS.
           

           inout PIO0_02,    // HDR1 1
           inout PIO0_03,    // HDR1 2
           inout PIO0_04,    // HDR1 3
           inout PIO0_05,    // HDR1 4
           inout PIO0_06,    // HDR1 5
           inout PIO0_07,    // HDR1 6
           inout PIO0_08,    // HDR1 7
           inout PIO0_09,    // HDR1 8

           

           inout PIO2_10,    // HDR2 1
           inout PIO2_11,    // HDR2 2
           inout PIO2_12,    // HDR2 3
           inout PIO2_13,    // HDR2 4
           inout PIO2_14,    // HDR2 5
           inout PIO2_15,    // HDR2 6
           inout PIO2_16,    // HDR2 7
           inout PIO2_17,    // HDR2 8

           input reset,
);
  localparam MHZ = 12;

/*
  wire clk, pll_lock;
  
  wire pll_reset;
  assign pll_reset = !reset;
  wire resetq;  // note port changed, .pcf needs update too.
  assign resetq = reset & !pll_lock;
  
  SB_PLL40_CORE #(.FEEDBACK_PATH("PHASE_AND_DELAY"),
                  .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
                  .DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
                  .PLLOUT_SELECT("SHIFTREG_0deg"),
                  .SHIFTREG_DIV_MODE(1'b0),
                  .FDA_FEEDBACK(4'b0000),
                  .FDA_RELATIVE(4'b0000),
                  .DIVR(4'b1111),
                  .DIVF(7'b0110001), 
                  .DIVQ(3'b011), //  1..6
                  .FILTER_RANGE(3'b001),
                 ) uut (
                         .REFERENCECLK(pclk),
                         //.PLLOUTCORE(clk),
                         .PLLOUTGLOBAL(clk),
                         .LOCK(pll_lock),
                         .RESETB(pll_reset),
                         .BYPASS(1'b0)
                        ); // 37.5 MHz, fout = [ fin * (DIVF+1) ] / [ DIVR+1 ], fout must be 16 ..275MHz, fVCO from 533..1066 MHz (!! we're 600 here I think), and phase detector / input clock from 10 .. 133 MH (ok, we're 75 because DIVQ divides by 2^DIVQ, but doesn't affect output otherwise, and input is 12 MHz)
                        // for some reason this crashes arachne-pnr now. 

  */
  wire clk;
  wire resetq;
  assign resetq = reset;
  
  SB_PLL40_CORE #(.FEEDBACK_PATH("SIMPLE"),
                  .PLLOUT_SELECT("GENCLK"),
                  .DIVR(4'b0000),
                  .DIVF(7'd3),
                  .DIVQ(3'b000),
                  .FILTER_RANGE(3'b001),
                 ) uut (
                         .REFERENCECLK(pclk),
                         .PLLOUTCORE(clk),
                         //.PLLOUTGLOBAL(clk),
                         // .LOCK(D5),
                         .RESETB(1'b1),
                         .BYPASS(1'b0)
                        );

  
  wire io_rd, io_wr;
  wire [15:0] mem_addr;
  wire mem_wr;
  wire [15:0] dout;
  wire [15:0] io_din;
  wire [12:0] code_addr;
  wire [1:0] io_thread;
  reg unlocked = 0;
  
  wire [15:0] return_top;
  
  wire [3:0] kill_slot_rq;

`include "../build/ram.v"

  j4 _j4(
    .clk(clk),
    .resetq(resetq),
    .io_rd(io_rd),
    .io_wr(io_wr),
    .mem_wr(mem_wr),
    .dout(dout),
    .io_din(io_din),
    .mem_addr(mem_addr),
    .code_addr(code_addr),
    .insn(insn),
    .io_slot(io_thread),
    .return_top(return_top),
    .kill_slot_rq(kill_slot_rq));

  /*
  // ######   TICKS   #########################################

  reg [15:0] ticks;
  always @(posedge clk)
    ticks <= ticks + 16'd1;
  */

  // ######   IO SIGNALS   ####################################

`define EASE_IO_TIMING
`ifdef EASE_IO_TIMING
  reg io_wr_, io_rd_;
  reg [15:0] dout_;
  reg [15:0] io_addr_;

  always @(posedge clk) begin
    {io_rd_, io_wr_, dout_} <= {io_rd, io_wr, dout};
    if (io_rd | io_wr)
      io_addr_ <= mem_addr;
  end
`else
  wire io_wr_ = io_wr, io_rd_ = io_rd;
  wire [15:0] dout_ = dout;
  wire [15:0] io_addr_ = mem_addr;
`endif

  // ######   PMOD   ##########################################

  reg [7:0] pmod_dir;   // 1:output, 0:input
  wire [7:0] pmod_in;

  ioport _mod (.clk(clk),
               .pins({PIO1_09, PIO1_08, PIO1_07, PIO1_06, PIO1_05, PIO1_04, PIO1_03, PIO1_02}),
               .we(io_wr_ & io_addr_[0]),
               .wd(dout_),
               .rd(pmod_in),
               .dir(pmod_dir));

  // ######   HDR1   ##########################################

  reg [7:0] hdr1_dir;   // 1:output, 0:input
  wire [7:0] hdr1_in;

  ioport _hdr1 (.clk(clk),
               .pins({PIO0_09, PIO0_08, PIO0_07, PIO0_06, PIO0_05, PIO0_04, PIO0_03, PIO0_02}),
               .we(io_wr_ & io_addr_[4]),
               .wd(dout_[7:0]),
               .rd(hdr1_in),
               .dir(hdr1_dir));

  // ######   HDR2   ##########################################

  reg [7:0] hdr2_dir;   // 1:output, 0:input
  wire [7:0] hdr2_in;

  ioport _hdr2 (.clk(clk),
               .pins({PIO2_17, PIO2_16, PIO2_15, PIO2_14, PIO2_13, PIO2_12, PIO2_11, PIO2_10}),
               .we(io_wr_ & io_addr_[6]),
               .wd(dout_[7:0]),
               .rd(hdr2_in),
               .dir(hdr2_dir));

  // ######   UART   ##########################################

  wire uart0_valid, uart0_busy;
  wire [7:0] uart0_data;
  wire uart0_wr = io_wr_ & io_addr_[12];
  wire uart0_rd = io_rd_ & io_addr_[12];
  wire uart_RXD;
  inpin _rcxd(.clk(clk), .pin(RXD), .rd(uart_RXD));
  buart _uart0 (
     .clk(clk),
     .resetq(1'b1),
     .rx(uart_RXD),
     .tx(TXD),
     .rd(uart0_rd),
     .wr(uart0_wr),
     .valid(uart0_valid),
     .busy(uart0_busy),
     .tx_data(dout_[7:0]),
     .rx_data(uart0_data));

  wire [7:0] LEDS;
  wire w4 = io_wr_ & io_addr_[2];

  
  
  
  outpin led0 (.clk(clk), .we(w4), .pin(D1), .wd(dout_[0]), .rd(LEDS[0]));
  outpin led1 (.clk(clk), .we(w4), .pin(D2), .wd(dout_[1]), .rd(LEDS[1]));
  outpin led2 (.clk(clk), .we(w4), .pin(D3), .wd(dout_[2]), .rd(LEDS[2]));
  outpin led3 (.clk(clk), .we(w4), .pin(D4), .wd(dout_[3]), .rd(LEDS[3]));
  outpin led4 (.clk(clk), .we(w4), .pin(D5), .wd(dout_[4]), .rd(LEDS[4]));
  outpin led5 (.clk(clk), .we(w4), .pin(D6), .wd(dout_[5]), .rd(LEDS[5]));
  outpin led6 (.clk(clk), .we(w4), .pin(D7), .wd(dout_[6]), .rd(LEDS[6]));
  outpin led7 (.clk(clk), .we(w4), .pin(D8), .wd(dout_[7]), .rd(LEDS[7]));


  wire [2:0] PIOS;
  wire w8 = io_wr_ & io_addr_[3];

  outpin pio0 (.clk(clk), .we(w8), .pin(PIOS_03), .wd(dout_[0]), .rd(PIOS[0]));
  outpin pio1 (.clk(clk), .we(w8), .pin(PIOS_02), .wd(dout_[1]), .rd(PIOS[1]));
  outpin pio2 (.clk(clk), .we(w8), .pin(PIOS_00), .wd(dout_[2]), .rd(PIOS[2]));

  // ######   RING OSCILLATOR   ###############################

  wire [1:0] buffers_in, buffers_out;
  assign buffers_in = {buffers_out[0:0], ~buffers_out[1]};
  SB_LUT4 #(
          .LUT_INIT(16'd2)
  ) buffers [1:0] (
          .O(buffers_out),
          .I0(buffers_in),
          .I1(1'b0),
          .I2(1'b0),
          .I3(1'b0)
  );
  wire random = ~buffers_out[1];

  // ######   IO PORTS   ######################################

  /*        bit   mode    device
      0001  0     r/w     PMOD GPIO
      0002  1     r/w     PMOD direction
      0004  2     r/w     LEDS
      0008  3     r/w     misc.out
      0010  4     r/w     HDR1 GPIO
      0020  5     r/w     HDR1 direction
      0040  6     r/w     HDR2 GPIO
      0080  7     r/w     HDR2 direction 
      -FIXME: Rearrange the above to be word wide, in order to compact them, and then use the space to add separate set/clear interfaces for both pins and direction controls so independant threads can easily manage separate bits on the same port without stepping on each other's toes. 
      - reading the "set" port should read actual values, and reading the "clear" should read the inverse of actual values.
      - it would be nice to be able to write set and clear for both the ports and their directions in one write, although this reduces the width of each addressed port to just 4 bits, this is still reasonable as many PMOD's only use four. An additional 8+8 bit "force write port and direction" would be good on at least one port to handle the rarer pmod's which need the full byte in parallel, and where only one task will write to that port. Such an arrangement would allow for task switching to handle up to 6 half-width PMOD's at once, on as many threads. 
      
      - because it's not changed, this IO map only adds addresses to what the j1a has, so it's at least backwards compatible with j1a.
      
      0100  8     r/w*    slot 1 task exec ! / previous nonzero slot wallclock @          
      0200  9     r/w*    slot 2 task exec ! / current slot wallclock @
      0400  10    r/w*    slot 3 task exec ! / next nonzero slot wallclock @
      - any non zero slot reading should give a counter showing the number of thread cycles since the 
      associated thread last fetched its task with `$4000 io@`, which could be used with drop just to "pet the watchdog".
      FIXME: Implement the prev/cur/next thing, it's just 1/2/3 at present, and that means tasks are slot specific, which they shouldn't be.
      
      * only slot 0 has write access to these and should write the exec token of the task routine assigned to the associated slot, or zero if none.
      - additionally, when slot 0 reads these it gets the maximum count said task reached last time the thread fetched. This is needed to allow a slowly-cycling thread on slot0 to meaningfully sample the execution time of potentially very short fast task threads. It will be biased in favor of finding long/slow runs if said task isn't ending deterministically, and it will read 0s whilst the task hasn't completed once since the last poll.
        This can be used to implement per-task watchdog timing, running in slot 0.
        So at the moment all threads are reset at once on a CTRL-C from the shell, which also clears all tasks.
        
      
      0800  11      w     sb_warmboot
      1000  12    r/w     UART RX, UART TX
      2000  13    r       misc.in
      
      4000  14    r/w*       
      
      Thread task fetch (depends on which slot is running now) - all threads should access this to fetch a exec token instead of quit, assigned tasks should not be loops themselves, but should exit yielding to this mechanism. When accessed, the associated tasktime counter is reset, updating a register holding the counter's previous value, exposed via the exec set addresses, so the management task on slot0 can monitor each thread's cycle time.
      * Only slot 0 may write, which sets the kill_slot_rq inputs in order to request that one or several slots be rebooted, including itself.
      If any other slot attempts a write, only itself will be rebooted regardless of dout_
      
      8000  15    r       Thread ID (depends only on which slot accesses it) - slot ID zero should always run quit, all else should be coded to go into a loop running their assigned task by running something like `$4000 io@ execute`. 
      
      This IO should only be used right after boot, and swapforth must be modified so that only thread ID 0, which is slot 0, will continue to execute main and ultimately quit, which should be modified to initialise and run itself and others via execution tokens stored in a set of eight variables which should be included in swapforth. The inital slot 0 task should start the three initial tasks, then waiting for just long enough for all to have started, before setting the main tasks and exiting to the programmer's serial interface. It is not necessary to wait until a task has completed before assigning a new task, only to wait for the initially assigned task to begin.
      
      The practical upshot of all this is that the j1a will initially behave to the programmer like a (one eighth speed until pipelining optimisation is added - then possibly exactly as fast) j1a. When the programmer is happy with the operation of a task, (s)he manually writes the execution token for the compiled init and runtime words into the exec slots for concurrent task testing. 
      
      During concurrent testing/debug, task0 may continue to be used as if a j1a, except that memory changes made by running task will be visible. The timing of operation running this way for development from compiled code will be the same regardless of what other tasks are running, unless the operation depends upon some handshaking between tasks. In this way timing critical code can be developed and left running for the remainder of development and modification/debug without ever changing it's timing and operation, yet enabling the programmer to continue to modify the running system.
      
      When happy with the entire system including one to three concurrently running tasks, (s)he manually writes the init and exec tokens into those six variables, then tests reboot start up with a CTRL-C, which always reboots all threads. If all is well, (s)he does a `#flash build/nuc.hex`, exits, and rebuilds the system with `make -C icestorm j4a.bin`. When the rebuilt system is booted, it will run as per it's operation after the CTRL-C, but will still be able to be connected to and developed further or debugged, or left standalone for embedded application.
      
      It may be worth changing this to reserve slot 0 entirely for the developer, whilst allowing say slot 3 to start and kill the other two.
      So of those two time critical things could be done in one, and less-time-critical multitasking in the other. It would even be possible then to have the managing task implement a soft-realtime OS with or without preemption on the one slot, whilst handling the io hardware by running a hard-real time scheduler on the other.
  */

  reg [15:0] tasklap [1:3], tasktime [1:3], taskexec, taskexecn [1:3];
  
  always @* begin
    case (io_thread)
      2'b00: taskexec = 16'b0;// all tasks start with taskexec zeroed, and all tasks will try to run all code from zero. 
      2'b01: taskexec = taskexecn[1];
      2'b10: taskexec = taskexecn[2];
      2'b11: taskexec = taskexecn[3];
    endcase
  end  

  assign io_din =
    (io_addr_[ 0] ? {8'd0, pmod_in}                                     : 16'd0) |
    (io_addr_[ 1] ? {8'd0, pmod_dir}                                    : 16'd0) |
    (io_addr_[ 2] ? {8'd0, LEDS}                                        : 16'd0) |
    (io_addr_[ 3] ? {13'd0, PIOS}                                       : 16'd0) |
    (io_addr_[ 4] ? {8'd0, hdr1_in}                                     : 16'd0) |
    (io_addr_[ 5] ? {8'd0, hdr1_dir}                                    : 16'd0) |
    (io_addr_[ 6] ? {8'd0, hdr2_in}                                     : 16'd0) |
    (io_addr_[ 7] ? {8'd0, hdr2_dir}                                    : 16'd0) |
    (io_addr_[ 8] ? {|io_thread ? tasktime[1] : tasklap[1]}: 16'd0) |
    (io_addr_[ 9] ? {|io_thread ? tasktime[2] : tasklap[2]}: 16'd0) |
    (io_addr_[10] ? {|io_thread ? tasktime[3] : tasklap[3]}: 16'd0) |
    (io_addr_[12] ? {8'd0, uart0_data}                                  : 16'd0) |
    (io_addr_[13] ? {11'd0, random, 1'b0, PIOS_01, uart0_valid, !uart0_busy} : 16'd0) |
    (io_addr_[14] ? {taskexec}: 16'd0) |
    (io_addr_[15] ? {14'd0, io_thread}: 16'd0) ; // so init code can stop all but one thread, or alternatively, restart their task by reading taskexec then executing it, or else going into a reboot poll loop until given something to do.

  reg boot, s0, s1;

  SB_WARMBOOT _sb_warmboot (
    .BOOT(boot),
    .S0(s0),
    .S1(s1)
    );

  
  function [15:0] wrapproofdiff(input [15:0] old, new);
    reg [15:0] temp;
    begin
      temp = new - old;
      if (temp[15])
        wrapproofdiff = ~temp+1;
      else
        wrapproofdiff = temp;
    end
  endfunction
   
   
  always @(negedge resetq or posedge clk) begin
    if (!resetq) begin
    
        {tasktime[1],tasktime[2],tasktime[3]} <= 0;
        {taskexecn[1],taskexecn[2],taskexecn[3]} <= 0;

    end else begin    
      
      case (io_thread) // io_thread is a grey code counter.
        2'b00:  begin 
          if(!io_wr_) begin // cleared on thread 0's read, so busy/stalled threads easy to detect, 
            if (io_addr_[8]) tasklap[1] <= 'b0; 
            if (io_addr_[9]) tasklap[2] <= 'b0;
            if (io_addr_[10]) tasklap[3] <= 'b0;
         // end else begin // only thread 0 can write, so tasks can't terminate each other.
         //   if (io_addr_[8]) taskexecn[1] <= dout_;
         //   if (io_addr_[9]) taskexecn[2] <= dout_;
         //   if (io_addr_[10]) taskexecn[3] <= dout_;
          end
        end
        2'b01:  begin 
          tasktime[3] <= tasktime[3] + 1; // stagger is intentional, this task time may be needed next cycle.
          if(!io_wr_ & io_addr_[14]) begin
            tasklap[1] <= tasktime[1];
            tasktime[1] <= 'b0;        
          end
        end
        2'b11:  begin
          tasktime[2] <= tasktime[2] + 1;
          if(!io_wr_ & io_addr_[14]) begin
            tasklap[3] <= tasktime[3];
            tasktime[3] <= 'b0;
          end 
         
        end      
        2'b10:  begin
          tasklap[1] <= tasktime[1] + 1;
          if(!io_wr_ & io_addr_[14]) begin
            tasklap[2] <= tasktime[2];
            tasktime[2] <= 'b0;
          end
        end
      endcase
      
      
      if (io_wr_ ) begin // any slot can change any other's schedule, except none can mess with slot 0
        if (io_addr_[8]) taskexecn[1] <= dout_;
        if (io_addr_[9]) taskexecn[2] <= dout_;
        if (io_addr_[10]) taskexecn[3] <= dout_;
      end  // it is even possible to assign the same task to multiple threads, although this isn't recommended.
      // if you need to do it to meet performance requirements, instead consider adding your own custom coprocessor here or datapath to 
      // send the data someplace better suited to heavy lifting. Sheer Data crunching performance isn't what this thing is for.
        
    end // resetable registers done
  end
  
  always@( posedge clk) begin
    
    
    case ({io_wr_ , io_addr_[14], io_thread})
        4'b1100:   kill_slot_rq <= dout_[4:0];
        4'b1101:   kill_slot_rq <= 4'b0010;
        4'b1111:   kill_slot_rq <= 4'b1000;
        4'b1110:   kill_slot_rq <= 4'b0100;
        default:  kill_slot_rq <= 4'b0000;
    endcase
  
  
  
    if (io_wr_ & io_addr_[1])
      pmod_dir <= dout_[7:0];
      
    if (io_wr_ & io_addr_[5])
      hdr1_dir <= dout_[7:0];
      
    if (io_wr_ & io_addr_[7])
      hdr2_dir <= dout_[7:0];
      
    if (io_wr_ & io_addr_[11])
      {boot, s1, s0} <= dout_[2:0];
    
  end

  always @(negedge resetq or posedge clk)
    if (!resetq)
      unlocked <= 0; // ram write clock enable
    else
      unlocked <= unlocked | io_wr_;

endmodule // top
