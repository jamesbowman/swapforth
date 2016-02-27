`timescale 1 ns / 1 ps

`default_nettype none
`define WIDTH 16

module j4a(input wire clk,
           input wire resetq,
           output wire uart0_wr,
           output wire uart0_rd,
           output wire [7:0] uart_w,
           input wire uart0_valid,
           input wire [7:0] uart0_data
);
  wire io_rd, io_wr;
  wire [15:0] mem_addr;
  wire mem_wr;
  wire [15:0] dout;
  wire [15:0] io_din;
/* verilator lint_off UNUSED */
  wire [12:0] code_addr;
  wire [15:0] return_top;
/* verilator lint_on UNUSED */  
  wire [1:0] io_thread;
  wire [3:0] kill_slot_rq;


  wire [15:0] insn;
   
  assign kill_slot_rq = 4'b0;
  
  reg [15:0] ram_prog[0:4095] /* verilator public_flat */;
  always @(posedge clk) begin
    //$display("pc=%x", code_addr * 2);
    insn <= ram_prog[code_addr[11:0]];
    if (mem_wr)
      ram_prog[mem_addr[12:1]] <= dout;
  end

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

  // ######   IO SIGNALS   ####################################

  // note that io_din has to be delayed one instruction, but it depends upon io_addr_, which is, so it does.
  // it doesn't hurt to run dout_ delayed too.
  reg io_wr_, io_rd_;
  reg [15:0] dout_;
  /* verilator lint_off UNUSED */
  reg [15:0] io_addr_;
  /* verilator lint_on UNUSED */
  reg [1:0] io_thread_;

  always @(posedge clk) begin
    {io_rd_, io_wr_, dout_} <= {io_rd, io_wr, dout};
    io_thread_ <= io_thread;
    if (io_rd | io_wr)
      io_addr_ <= mem_addr;
    else
      io_addr_ <= 0; // because we don't want to actuate things unless there really is a read or write.
  end

  // ######   UART   ##########################################

  wire uart0_wr = io_wr_ & io_addr_[12];
  wire uart0_rd = io_rd_ & io_addr_[12];
  assign uart_w = dout_[7:0];

  // always @(posedge clk) begin
  //   if (uart0_wr)
  //     $display("--- out %x %c", uart_w, uart_w);
  //   if (uart0_rd)
  //     $display("--- in %x %c", uart0_data, uart0_data);
  // end

  // ######   IO PORTS   ######################################

  /*        bit READ            WRITE
      1000  12  UART RX         UART TX
      2000  13  misc.in
  */
  
  reg [15:0] taskexec;
  reg [47:0] taskexecn;
  
  always @* begin
    case (io_thread_)
      2'b00: taskexec = 16'b0;// all tasks start with taskexec zeroed, and all tasks will try to run all code from zero. 
      2'b01: taskexec = taskexecn[15:0];
      2'b10: taskexec = taskexecn[31:16];
      2'b11: taskexec = taskexecn[47:32];
    endcase
  end  


  assign io_din =
    (io_addr_[12] ? {8'd0, uart0_data}                                  : 16'd0) |
    (io_addr_[13] ? {12'd0, 1'b0, 1'b0, uart0_valid, 1'b1} : 16'd0) |
    (io_addr_[14] ? {taskexec}: 16'd0)|
    (io_addr_[15] ? {14'd0, io_thread_}: 16'd0);

  always@( posedge clk) begin
  
    if (io_wr_ ) begin // any slot can change any other's schedule, except none can mess with slot 0
      if (io_addr_[8]) taskexecn[15:0] <= dout_;
      if (io_addr_[9]) taskexecn[31:16] <= dout_;
      if (io_addr_[10]) taskexecn[47:32] <= dout_;
    end  // it is even possible to assign the same task to multiple threads, although this isn't recommended.
   
    if (io_addr_[15]==1'b1) $display("io_thread_ = %d, io_din = %d", io_thread_, io_din);
    
    case ({io_wr_ , io_addr_[14], io_thread_})
        4'b1100:   kill_slot_rq <= dout_[3:0];
        4'b1101:   kill_slot_rq <= 4'b0010;
        4'b1111:   kill_slot_rq <= 4'b1000;
        4'b1110:   kill_slot_rq <= 4'b0100;
        default:  kill_slot_rq <= 4'b0000;
    endcase
  end

endmodule
