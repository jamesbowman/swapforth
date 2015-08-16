
module xorshift32(
  input wire clk,               // main clock
  input wire resetq,
  input wire gen,               // update signal
  output wire [31:0] r);

  reg [31:0] seed = 32'h7;
  wire [31:0] seed0 = seed ^ {seed[18:0], 13'd0};
  wire [31:0] seed1 = seed0 ^ {17'd0, seed0[31:17]};
  wire [31:0] seed2 = seed1 ^ {seed1[26:0], 5'd0};

  always @(posedge clk or negedge resetq)
    if (!resetq)
      seed <= 32'h7;
    else if (gen)
      seed <= seed2;
  assign r = seed;

endmodule

module dither(
  input wire [7:0] v,
  input wire [7:0] rnd,
  output wire [3:0] d);

  wire [8:0] s = {1'b0, v} + {5'b00000, rnd[3:0]};
  assign d = s[8] ? 4'd15 : s[7:4];

endmodule

module textmode(
  input wire clk,               // main clock
  input wire resetq,
  input wire [1:0] hack,
  input wire pix,               // pixel clock
  output wire eat,
  input wire [23:0] rgb,
  output reg [3:0] vga_red,     // VGA output signals
  output reg [3:0] vga_green,
  output reg [3:0] vga_blue,
  output reg vga_hsync_n,
  output reg vga_vsync_n);

  // These timing values come from
  // http://tinyvga.com/vga-timing/1024x768@60Hz

  // hcounter:
  //    0- 639   visible area
  //  640- 655   front porch
  //  656- 751   sync pulse
  //  752- 799   back porch

  reg [10:0] hcounter;
  wire [10:0] hcounterN = (hcounter == 11'd799) ? 11'd0 : (hcounter + 11'd1);

  // vcounter:
  //  0  -479     visible area
  //  480-489     front porch
  //  490-491     sync pulse
  //  492-524     back porch

  reg [9:0] vcounter;
  reg [9:0] vcounterN;
  always @*
    if (hcounterN != 11'd0)
      vcounterN = vcounter;
    else if (vcounter != 10'd524)
      vcounterN = vcounter + 10'd1;
    else
      vcounterN = 10'd0;

  wire visible = (hcounter < 640) & (vcounter < 480);

  reg [1:0] visible_;
  reg [1:0] hsync_;
  always @(negedge resetq or posedge clk)
    if (!resetq) begin
      visible_ <= 2'b11;
      hsync_ <= 2'b11;
    end else if (pix) begin
      visible_ <= {visible_[0], visible};
      hsync_ <= {hsync_[0], !((656 <= hcounter) & (hcounter < 752))};
    end
  assign eat = visible & pix;

  // wire [3:0] r = rgb[23:20];
  // wire [3:0] g = rgb[15:12];
  // wire [3:0] b = rgb[7:4];
  wire [31:0] rnd32;
  xorshift32 rng(.clk(clk), .resetq(resetq), .gen(1'b1), .r(rnd32));

  wire [3:0] r, g, b;
  dither _rd (.v(rgb[23:16]), .rnd(hack[0] ? 8'd0 : rnd32[23:16]), .d(r));
  dither _gd (.v(rgb[15:8]), .rnd(hack[0] ? 8'd0 : rnd32[15:8]), .d(g));
  dither _bd (.v(rgb[7:0]), .rnd(hack[0] ? 8'd0 : rnd32[7:0]), .d(b));

  always @(negedge resetq or posedge clk)
    if (!resetq) begin
      hcounter <= 0;
      vcounter <= 0;
      vga_hsync_n <= 0;
      vga_vsync_n <= 0;
      vga_red   <= 0;
      vga_green <= 0;
      vga_blue  <= 0;
    end else if (pix) begin
      hcounter <= hcounterN;
      vcounter <= vcounterN;
      vga_hsync_n <= hsync_[1];
      vga_vsync_n <= !((490 <= vcounter) & (vcounter < 492));
      vga_red   <= visible_[1] ? r : 4'b0000;
      vga_green <= visible_[1] ? g : 4'b0000;
      vga_blue  <= visible_[1] ? b : 4'b0000;
    end

endmodule
module vga(
  input wire clk,               // main clock
  input wire resetq,

  input wire [1:0] hack,
  output reg [20:0] addr,
  input  wire [7:0] rd,

  output reg idle,

  output wire [3:0] vga_red,     // VGA output signals
  output wire [3:0] vga_green,
  output wire [3:0] vga_blue,
  output wire vga_hsync_n,
  output wire vga_vsync_n);

  wire pix;               // pixel clock
  wire eat;
  reg [23:0] rgb;

  textmode tm (
    .clk(clk),               // main clock
    .resetq(resetq),
    .hack(hack),
    .pix(pix),               // pixel clock
    .eat(eat),
    .rgb(rgb),
    .vga_red(vga_red),     // VGA output signals
    .vga_green(vga_green),
    .vga_blue(vga_blue),
    .vga_hsync_n(vga_hsync_n),
    .vga_vsync_n(vga_vsync_n));

  reg [2:0] phase;
  reg [2:0] phaseN;

  always @*
    case (phase)
    3'd0:       phaseN = 3'd1;
    3'd1:       phaseN = 3'd2;
    3'd2:       phaseN = 3'd3;
    3'd3:       phaseN = 3'd4;
    3'd4:       phaseN = 3'd0;
    default:    phaseN = 3'd0;
    endcase

  reg eating;
  always @(negedge resetq or posedge clk)
    if (!resetq)
      {eating, rgb} <= 0;
    else
      case (phase)
      3'd0:       begin eating <= eat;  rgb[23:16] <= rd; end
      3'd1:       begin                                   end
      3'd2:       begin eating <= 1'b0; rgb[15:8] <= rd; end
      3'd3:       begin                 rgb[7:0] <= rd; idle <= 1'b1; end
      3'd4:       begin                                 idle <= 1'b0; end
      endcase   

  always @(posedge clk or negedge resetq)
    if (!resetq)
      phase <= 0;
    else
      phase <= phaseN;

  assign pix = (phase == 0);

  always @(posedge clk or negedge resetq)
    if (!resetq)
      addr <= 21'd1;
    else if (vga_vsync_n == 0)
      addr <= 19'd0 + 2'b00;
    else if (eat | eating)
      addr <= addr + 21'd1;

endmodule
