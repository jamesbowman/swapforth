`default_nettype none

module bram_tdp #(
    parameter DATA = 72,
    parameter ADDR = 10
) (
    // Port A
    input   wire                a_clk,
    input   wire                a_wr,
    input   wire    [ADDR-1:0]  a_addr,
    input   wire    [DATA-1:0]  a_din,
    output  reg     [DATA-1:0]  a_dout,
     
    // Port B
    input   wire                b_clk,
    input   wire                b_wr,
    input   wire    [ADDR-1:0]  b_addr,
    input   wire    [DATA-1:0]  b_din,
    output  reg     [DATA-1:0]  b_dout
);
 
// Shared memory
reg [DATA-1:0] mem [(2**ADDR)-1:0];
  initial begin
    $readmemh("../build/nuc.hex", mem);
    // $readmemh("../ans.hex", mem);
  end
 
// Port A
always @(posedge a_clk) begin
    a_dout      <= mem[a_addr];
    if(a_wr) begin
        a_dout      <= a_din;
        mem[a_addr] <= a_din;
    end
end
 
// Port B
always @(posedge b_clk) begin
    b_dout      <= mem[b_addr];
    if(b_wr) begin
        b_dout      <= b_din;
        mem[b_addr] <= b_din;
    end
end
 
endmodule

// A 32Kbyte RAM (8192x32) with two ports:
//   port a, 32 bits read/write 
//   port b, 16 bits read-only, lower 16K only

module ram16k(
  input wire        clk,

  input  wire[15:0] a_addr,
  output wire[31:0] a_q,
  input  wire[31:0] a_d,
  input  wire       a_wr,

  input  wire[12:0] b_addr,
  output wire[15:0] b_q);

  wire [31:0] insn32;

  bram_tdp #(.DATA(32), .ADDR(13)) nram (
    .a_clk(clk),
    .a_wr(a_wr),
    .a_addr(a_addr[14:2]),
    .a_din(a_d),
    .a_dout(a_q),

    .b_clk(clk),
    .b_wr(1'b0),
    .b_addr({1'b0, b_addr[12:1]}),
    .b_din(32'd0),
    .b_dout(insn32));

  reg ba_;
  always @(posedge clk)
    ba_ <= b_addr[0];
  assign b_q = ba_ ? insn32[31:16] : insn32[15:0];

endmodule


module top(
  input wire CLK,
  input  wire DUO_SW1,
  input  wire RXD,
  output wire TXD,
  input  wire DTR,

  output wire [20:0] sram_addr,
  inout wire [7:0] sram_data,
  output wire sram_ce,
  output wire sram_oe,
  output wire sram_we,

  inout wire Arduino_0,
  inout wire Arduino_1,
  inout wire Arduino_2,
  inout wire Arduino_3,
  inout wire Arduino_4,
  inout wire Arduino_5,
  inout wire Arduino_6,
  inout wire Arduino_7,
  inout wire Arduino_8,
  inout wire Arduino_9,
  inout wire Arduino_10,
  inout wire Arduino_11,
  inout wire Arduino_12,
  inout wire Arduino_13,
  inout wire Arduino_14,
  inout wire Arduino_15,
  inout wire Arduino_16,
  inout wire Arduino_17,
  inout wire Arduino_18,
  inout wire Arduino_19,
  inout wire Arduino_20,
  inout wire Arduino_21,
  inout wire Arduino_22,
  inout wire Arduino_23,
  inout wire Arduino_24,
  inout wire Arduino_25,
  inout wire Arduino_26,
  inout wire Arduino_27,
  inout wire Arduino_28,
  inout wire Arduino_29,
  inout wire Arduino_30,
  inout wire Arduino_31,
  inout wire Arduino_32,
  inout wire Arduino_33,
  inout wire Arduino_34,
  inout wire Arduino_35,
  inout wire Arduino_36,
  inout wire Arduino_37,
  inout wire Arduino_38,
  inout wire Arduino_39,
  inout wire Arduino_40,
  inout wire Arduino_41,
  inout wire Arduino_42,
  inout wire Arduino_43,
  inout wire Arduino_44,
  inout wire Arduino_45,
  inout wire Arduino_46,
  inout wire Arduino_47,
  inout wire Arduino_48,
  inout wire Arduino_49,
  inout wire Arduino_50,
  inout wire Arduino_51,
  inout wire Arduino_52,
  inout wire Arduino_53

  );
  localparam MHZ = 125;

  reg  DUO_LED;
  wire fclk;

  DCM_CLKGEN #(
  .CLKFX_MD_MAX(0.0),     // Specify maximum M/D ratio for timing anlysis
  // .CLKFX_DIVIDE(32),      // Divide value - D - (1-256)
  // .CLKFX_MULTIPLY(MHZ),   // Multiply value - M - (2-256)

  .CLKFX_DIVIDE(15),      // Divide value - D - (1-256)
  .CLKFX_MULTIPLY(59),   // Multiply value - M - (2-256)

  .CLKIN_PERIOD(31.25),   // Input clock period specified in nS
  .STARTUP_WAIT("FALSE")  // Delay config DONE until DCM_CLKGEN LOCKED (TRUE/FALSE)
  )
  DCM_CLKGEN_inst (
  .CLKFX(fclk),           // 1-bit output: Generated clock output
  .CLKIN(CLK),            // 1-bit input: Input clock
  .FREEZEDCM(0),          // 1-bit input: Prevents frequency adjustments to input clock
  .PROGCLK(0),            // 1-bit input: Clock input for M/D reconfiguration
  .PROGDATA(0),           // 1-bit input: Serial data input for M/D reconfiguration
  .PROGEN(0),             // 1-bit input: Active high program enable
  .RST(0)                 // 1-bit input: Reset input pin
  );

  reg [63:0] counter;
  always @(posedge fclk)
    counter <= counter + 64'd1;

  // ------------------------------------------------------------------------

  wire uart0_valid, uart0_busy;
  wire [7:0] uart0_data;
  wire uart0_rd, uart0_wr;
  reg [31:0] uart_baud = 32'd921600;
  wire UART0_RX;
  buart #(.CLKFREQ(MHZ * 1000000)) _uart0 (
     .clk(fclk),
     .resetq(resetq),
     .baud(uart_baud),
     .rx(RXD),
     .tx(TXD),
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

  wire resetq = DTR;

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
    00xx  GPIO rd         GPIO wr
    01xx                  GPIO direction

    1008  baudrate        baudrate
    1000  UART RX         UART TX
    2000  UART status 

    1010  master freq     snapshot clock
    1014  clock[31:0]
    1018  clock[63:32]

  */

  reg [63:0] counter_;
  reg [127:0] gpo;
  wire [127:0] gpi;
  reg [127:0] gpio_dir;   // 1:output, 0:input

  reg [20:0] sram_addr_o;
  reg [7:0] sram_data_o;

  always @(posedge fclk) begin
    casez (mem_addr)
    16'h00??: din <= gpi[mem_addr[6:0]];
    16'h01??: din <= gpio_dir[mem_addr[6:0]];

    16'h1008: din <= uart_baud;
    16'h1000: din <= {24'd0, uart0_data};
    16'h2000: din <= {30'd0, uart0_valid, !uart0_busy};

    16'h1010: din <= MHZ * 1000000;
    16'h1014: din <= counter_[31:0];
    16'h1018: din <= counter_[63:32];

    default:  din <= 32'bx;
    endcase

    if (io_wr_) begin
      casez (mem_addr_)
        16'h00??: gpo[mem_addr_[6:0]] <= dout_[0];
        16'h01??: gpio_dir[mem_addr_[6:0]] <= dout_[0];

        // 16'h1008: uart_baud <= dout_;

        16'h1010: counter_ <= counter;

        16'h4000: {sram_addr_o, sram_data_o} <= dout_[20 + 8:0];

      endcase
    end
  end

  assign uart0_wr = io_wr_ & (mem_addr_ == 16'h1000);
  assign uart0_rd = io_rd_ & (mem_addr_ == 16'h1000);

  assign Arduino_0 = gpio_dir[0] ? gpo[0] : 1'bz;
  assign Arduino_1 = gpio_dir[1] ? gpo[1] : 1'bz;
  assign Arduino_2 = gpio_dir[2] ? gpo[2] : 1'bz;
  assign Arduino_3 = gpio_dir[3] ? gpo[3] : 1'bz;
  assign Arduino_4 = gpio_dir[4] ? gpo[4] : 1'bz;
  assign Arduino_5 = gpio_dir[5] ? gpo[5] : 1'bz;
  assign Arduino_6 = gpio_dir[6] ? gpo[6] : 1'bz;
  assign Arduino_7 = gpio_dir[7] ? gpo[7] : 1'bz;
  assign Arduino_8 = gpio_dir[8] ? gpo[8] : 1'bz;
  assign Arduino_9 = gpio_dir[9] ? gpo[9] : 1'bz;
  assign Arduino_10 = gpio_dir[10] ? gpo[10] : 1'bz;
  assign Arduino_11 = gpio_dir[11] ? gpo[11] : 1'bz;
  assign Arduino_12 = gpio_dir[12] ? gpo[12] : 1'bz;
  assign Arduino_13 = gpio_dir[13] ? gpo[13] : 1'bz;
  assign Arduino_14 = gpio_dir[14] ? gpo[14] : 1'bz;
  assign Arduino_15 = gpio_dir[15] ? gpo[15] : 1'bz;
  assign Arduino_16 = gpio_dir[16] ? gpo[16] : 1'bz;
  assign Arduino_17 = gpio_dir[17] ? gpo[17] : 1'bz;
  assign Arduino_18 = gpio_dir[18] ? gpo[18] : 1'bz;
  assign Arduino_19 = gpio_dir[19] ? gpo[19] : 1'bz;
  assign Arduino_20 = gpio_dir[20] ? gpo[20] : 1'bz;
  assign Arduino_21 = gpio_dir[21] ? gpo[21] : 1'bz;
  // assign Arduino_22 = gpio_dir[22] ? gpo[22] : 1'bz;
  assign Arduino_23 = gpio_dir[23] ? gpo[23] : 1'bz;
  // assign Arduino_24 = gpio_dir[24] ? gpo[24] : 1'bz;
  assign Arduino_25 = gpio_dir[25] ? gpo[25] : 1'bz;
  // assign Arduino_26 = gpio_dir[26] ? gpo[26] : 1'bz;
  assign Arduino_27 = gpio_dir[27] ? gpo[27] : 1'bz;
  assign Arduino_28 = gpio_dir[28] ? gpo[28] : 1'bz;
  assign Arduino_29 = gpio_dir[29] ? gpo[29] : 1'bz;
  assign Arduino_30 = gpio_dir[30] ? gpo[30] : 1'bz;
  assign Arduino_31 = gpio_dir[31] ? gpo[31] : 1'bz;
  // assign Arduino_32 = gpio_dir[32] ? gpo[32] : 1'bz;
  assign Arduino_33 = gpio_dir[33] ? gpo[33] : 1'bz;
  // assign Arduino_34 = gpio_dir[34] ? gpo[34] : 1'bz;
  assign Arduino_35 = gpio_dir[35] ? gpo[35] : 1'bz;
  // assign Arduino_36 = gpio_dir[36] ? gpo[36] : 1'bz;
  assign Arduino_37 = gpio_dir[37] ? gpo[37] : 1'bz;
  // assign Arduino_38 = gpio_dir[38] ? gpo[38] : 1'bz;
  assign Arduino_39 = gpio_dir[39] ? gpo[39] : 1'bz;
  // assign Arduino_40 = gpio_dir[40] ? gpo[40] : 1'bz;
  assign Arduino_41 = gpio_dir[41] ? gpo[41] : 1'bz;
  // assign Arduino_42 = gpio_dir[42] ? gpo[42] : 1'bz;
  assign Arduino_43 = gpio_dir[43] ? gpo[43] : 1'bz;
  // assign Arduino_44 = gpio_dir[44] ? gpo[44] : 1'bz;
  assign Arduino_45 = gpio_dir[45] ? gpo[45] : 1'bz;
  // assign Arduino_46 = gpio_dir[46] ? gpo[46] : 1'bz;
//  assign Arduino_47 = gpio_dir[47] ? gpo[47] : 1'bz;
  // assign Arduino_48 = gpio_dir[48] ? gpo[48] : 1'bz;
//  assign Arduino_49 = gpio_dir[49] ? gpo[49] : 1'bz;
  // assign Arduino_50 = gpio_dir[50] ? gpo[50] : 1'bz;
  assign Arduino_51 = gpio_dir[51] ? gpo[51] : 1'bz;
  // assign Arduino_52 = gpio_dir[52] ? gpo[52] : 1'bz;
  assign Arduino_53 = gpio_dir[53] ? gpo[53] : 1'bz;

  reg [31:0] blinker;
  always @(posedge fclk)
    blinker <= blinker + 1;
  assign Arduino_47 = blinker[24];
  assign Arduino_49 = ~blinker[24];


  assign gpi[0] = Arduino_0;
  assign gpi[1] = Arduino_1;
  assign gpi[2] = Arduino_2;
  assign gpi[3] = Arduino_3;
  assign gpi[4] = Arduino_4;
  assign gpi[5] = Arduino_5;
  assign gpi[6] = Arduino_6;
  assign gpi[7] = Arduino_7;
  assign gpi[8] = Arduino_8;
  assign gpi[9] = Arduino_9;
  assign gpi[10] = Arduino_10;
  assign gpi[11] = Arduino_11;
  assign gpi[12] = Arduino_12;
  assign gpi[13] = Arduino_13;
  assign gpi[14] = Arduino_14;
  assign gpi[15] = Arduino_15;
  assign gpi[16] = Arduino_16;
  assign gpi[17] = Arduino_17;
  assign gpi[18] = Arduino_18;
  assign gpi[19] = Arduino_19;
  assign gpi[20] = Arduino_20;
  assign gpi[21] = Arduino_21;
  // assign gpi[22] = Arduino_22;
  assign gpi[23] = Arduino_23;
  // assign gpi[24] = Arduino_24;
  assign gpi[25] = Arduino_25;
  // assign gpi[26] = Arduino_26;
  assign gpi[27] = Arduino_27;
  assign gpi[28] = Arduino_28;
  assign gpi[29] = Arduino_29;
  assign gpi[30] = Arduino_30;
  assign gpi[31] = Arduino_31;
  // assign gpi[32] = Arduino_32;
  assign gpi[33] = Arduino_33;
  // assign gpi[34] = Arduino_34;
  assign gpi[35] = Arduino_35;
  // assign gpi[36] = Arduino_36;
  assign gpi[37] = Arduino_37;
  // assign gpi[38] = Arduino_38;
  assign gpi[39] = Arduino_39;
  // assign gpi[40] = Arduino_40;
  assign gpi[41] = Arduino_41;
  // assign gpi[42] = Arduino_42;
  assign gpi[43] = Arduino_43;
  // assign gpi[44] = Arduino_44;
  assign gpi[45] = Arduino_45;
  // assign gpi[46] = Arduino_46;
  assign gpi[47] = Arduino_47;
  // assign gpi[48] = Arduino_48;
  assign gpi[49] = Arduino_49;
  // assign gpi[50] = Arduino_50;
  assign gpi[51] = Arduino_51;
  // assign gpi[52] = Arduino_52;
  assign gpi[53] = Arduino_53;

  wire [20:0] vga_addr;
  wire [7:0] vga_rd;
  wire [3:0] vga_red;
  wire [3:0] vga_green;
  wire [3:0] vga_blue;
  wire vga_hsync;
  wire vga_vsync;
  wire vga_idle;

  wire vga_write;

  vga _vga (
    .clk(fclk),
    .resetq(resetq),
    .hack(gpo[101:100]),
    .idle(vga_idle),
    .addr(vga_addr),
    .rd(sram_we ? sram_data : 8'h80),
    .vga_red(vga_red),
    .vga_green(vga_green),
    .vga_blue(vga_blue),
    .vga_hsync_n(vga_hsync),
    .vga_vsync_n(vga_vsync));

  assign Arduino_52 = vga_red[0];   // Red1
  assign Arduino_50 = vga_red[1];   // Red2
  assign Arduino_48 = vga_red[2];   // Red3
  assign Arduino_46 = vga_red[3];   // Red4
  assign Arduino_38 = vga_green[0]; // Green1
  assign Arduino_40 = vga_green[1]; // Green2
  assign Arduino_42 = vga_green[2]; // Green3
  assign Arduino_44 = vga_green[3]; // Green4
  assign Arduino_26 = vga_blue[0];  // Blue1
  assign Arduino_32 = vga_blue[1];  // Blue2
  assign Arduino_34 = vga_blue[2];  // Blue3
  assign Arduino_36 = vga_blue[3];  // Blue4

  // assign Arduino_52 = vga_blue[0];   // Red1
  // assign Arduino_50 = vga_blue[1];   // Red2
  // assign Arduino_48 = vga_blue[2];   // Red3
  // assign Arduino_46 = vga_blue[3];   // Red4
  // assign Arduino_38 = vga_red[0]; // Green1
  // assign Arduino_40 = vga_red[1]; // Green2
  // assign Arduino_42 = vga_red[2]; // Green3
  // assign Arduino_44 = vga_red[3]; // Green4
  // assign Arduino_26 = vga_green[0];  // Blue1
  // assign Arduino_32 = vga_green[1];  // Blue2
  // assign Arduino_34 = vga_green[2];  // Blue3
  // assign Arduino_36 = vga_green[3];  // Blue4

  assign Arduino_24 = vga_vsync;    // VSync
  assign Arduino_22 = vga_hsync;    // HSync

  assign {sram_ce, sram_oe, sram_we} = gpo[87:85];
  assign sram_addr = sram_we ? vga_addr : sram_addr_o;
  assign sram_data = sram_we ? 8'bzzzzzzzz : sram_data_o;

endmodule
