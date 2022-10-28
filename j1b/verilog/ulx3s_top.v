`default_nettype none

module ulx3s_top(
           input wire        clk_25mhz,

           input wire [6:0]  btn,
           output wire [7:0] led,

           input wire        ftdi_txd,
           output wire       ftdi_rxd,

           output wire       wifi_gpio0
           );

  // Tie GPIO0, keep board from rebooting
  assign wifi_gpio0 = 1'b1;

  wire resetq = btn[0];

  localparam MHZ = 25;
  wire fclk = clk_25mhz;

  reg [63:0] counter;
  always @(posedge fclk)
    counter <= counter + 64'd1;

  reg [31:0] ms;
  reg [17:0] subms;
  localparam [17:0] lim = (MHZ * 1000) - 1;
  always @(posedge fclk) begin
    subms <= (subms == lim) ? 18'd0 : (subms + 18'd1);
    if (subms == lim)
      ms <= ms + 32'd1;
  end

  // ------------------------------------------------------------------------

  wire uart0_valid, uart0_busy;
  wire [7:0] uart0_data;
  wire uart0_rd, uart0_wr;
  reg [31:0] uart_baud = 32'd115200;
  wire UART0_RX;
  buart #(.CLKFREQ(MHZ * 1000000)) _uart0 (
     .clk(fclk),
     .resetq(resetq),
     .baud(uart_baud),
     .rx(ftdi_txd),
     .tx(ftdi_rxd),
     .rd(uart0_rd),
     .wr(uart0_wr),
     .valid(uart0_valid),
     .busy(uart0_busy),
     .tx_data(dout_[7:0]),
     .rx_data(uart0_data));

  wire [15:0] mem_addr;
  wire [31:0] mem_din;
  wire mem_wr;
  wire [31:0] dout;
  reg  [31:0] din;

  wire [12:0] code_addr;
  wire [15:0] insn;

  wire io_rd, io_wr;

  j1 _j1 (
     .clk(fclk),
     .resetq(resetq),

     .io_rd(io_rd),
     .io_wr(io_wr),
     .mem_addr(mem_addr),
     .mem_wr(mem_wr),
     .mem_din(mem_din),
     .dout(dout),
     .io_din(din),

     .code_addr(code_addr),
     .insn(insn)
     );

  ram16k ram(.clk(fclk),
             .a_addr(mem_addr),
             .a_q(mem_din),
             .a_wr(mem_wr),
             .a_d(dout),
             .b_addr(code_addr),
             .b_q(insn));

  reg io_wr_, io_rd_;
  reg [15:0] mem_addr_;
  reg [31:0] dout_;
  always @(posedge fclk)
    {io_wr_, io_rd_, mem_addr_, dout_} <= {io_wr, io_rd, mem_addr, dout};

  /*      READ            WRITE
    0400  buttons rd
    0404                  LEDs wr

    1000  UART RX         UART TX
    1008  baudrate        baudrate

    1010  master freq     snapshot clock
    1014  clock[31:0]
    1018  clock[63:32]
    101c  millisecond uptime

    2000  UART status
  */

  reg [63:0] counter_;

  always @(posedge fclk) begin
    casez (mem_addr)
    16'h0400: din <= {27'd0, btn[6:1]};

    16'h1000: din <= {24'd0, uart0_data};
    16'h1008: din <= uart_baud;
    16'h2000: din <= {30'd0, uart0_valid, !uart0_busy};

    16'h1010: din <= MHZ * 1000000;
    16'h1014: din <= counter_[31:0];
    16'h1018: din <= counter_[63:32];
    16'h101c: din <= ms;

    default:  din <= 32'bx;
    endcase

    if (io_wr_) begin
      casez (mem_addr_)
        16'h0404: led <= dout_;
        16'h1008: uart_baud <= dout_;
        16'h1010: counter_ <= counter;
      endcase
    end
  end

  assign uart0_wr = io_wr_ & (mem_addr_ == 16'h1000);
  assign uart0_rd = io_rd_ & (mem_addr_ == 16'h1000);

endmodule
