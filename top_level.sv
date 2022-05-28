module top_level (HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, KEY, SW, LEDR, GPIO_1, CLOCK_50);
  output logic [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
  output logic [9:0]  LEDR;
  input  logic [3:0]  KEY;
  input  logic [9:0]  SW;
  output logic [35:0] GPIO_1;
  input logic CLOCK_50;

  // Turn off HEX displays except hex0 and hex1
  // assign HEX0 = '1;
  // assign HEX1 = '1;
  assign HEX2 = '1; 
  assign HEX3 = '1;
  assign HEX4 = '1;
  assign HEX5 = '1;

  /* Set up system base clock to 1526 Hz (50 MHz / 2**(14+1))
    ===========================================================*/
  logic [31:0] clk;
  logic SYSTEM_CLOCK;
  clock_divider divider (.clock(CLOCK_50), .divided_clocks(clk));
  assign SYSTEM_CLOCK = clk[13];

  /* Set up the frequency of updating display to the led
    ===========================================================*/
  logic [31:0] snakeClk;
  logic SNAKE_CLOCK;
  clock_divider snakeDivider (.clock(CLOCK_50), .divided_clocks(snakeClk));
  assign SNAKE_CLOCK = snakeClk[22];

  /* Set up LED board driver
    ================================================================== */
  logic [15:0][15:0]RedPixels; // 16 x 16 array representing red LEDs
  logic [15:0][15:0]GrnPixels; // 16 x 16 array representing green LEDs
  logic RST;                   // reset - toggle this on startup
  logic disable_d;                // to freeze 

  assign RST = SW[0];

  /* Standard LED Driver instantiation */
  LEDDriver Driver (.CLK(SYSTEM_CLOCK), .RST, .EnableCount(1'b1), .RedPixels, .GrnPixels, .GPIO_1);

  // ============================ TYPEDEFS ============================
  typedef enum logic [1:0] { 
    red = 2'b10
    ,green = 2'b01
    ,orange = 2'b11
    ,off = 2'b00
  } cellStateColor;

  typedef enum logic [1:0] {
    right = 2'b00
    ,down = 2'b01
    ,left = 2'b10
    ,up = 2'b11
  } inputDirection;

  typedef enum logic [1:0] {
    eatApple = 2'b10
    ,gameOver = 2'b01
    ,normal = 2'b00
  } collisionState;

  typedef enum logic {
    startOn = 1'b1
    ,startOff = 1'b0
  } startState;

  //============= DFF to handle metastability =================

  logic left1_var, left2_var, left3_var;
  basic_D_FF left1 (.d(~KEY[1]), .q(left1_var), .clk(CLOCK_50));
  basic_D_FF left2 (.d(left1_var), .q(left2_var), .clk(CLOCK_50));

  logic up1_var, up2_var, up3_var;
  basic_D_FF up1 (.d(~KEY[3]), .q(up1_var), .clk(CLOCK_50));
  basic_D_FF up2 (.d(up1_var), .q(up2_var), .clk(CLOCK_50));

  logic down1_var, down2_var, down3_var;
  basic_D_FF down1 (.d(~KEY[2]), .q(down1_var), .clk(CLOCK_50));
  basic_D_FF down2 (.d(down1_var), .q(down2_var), .clk(CLOCK_50));

  logic right1_var, right2_var, right3_var;
  basic_D_FF right1 (.d(~KEY[0]), .q(right1_var), .clk(CLOCK_50));
  basic_D_FF right2 (.d(right1_var), .q(right2_var), .clk(CLOCK_50));

  //====================Initialize buttons ======================

  button leftBtn (.clock(CLOCK_50), .reset(RST), .key_in(left2_var), .key_out(left3_var));

  button upBtn (.clock(CLOCK_50), .reset(RST), .key_in(up2_var), .key_out(up3_var));

  button downBtn (.clock(CLOCK_50), .reset(RST), .key_in(down2_var), .key_out(down3_var));

  button rightBtn (.clock(CLOCK_50), .reset(RST), .key_in(right2_var), .key_out(right3_var));

  //===================Initialize directions====================

  inputDirection direction;

  snakeDirection sd (.in_right(right3_var), .in_down(down3_var), .in_left(left3_var), 
    .in_up(up3_var), .clk(CLOCK_50), .reset(RST), .direction(direction));

  //===================Initialize randomizer===================

  int intX, intY;
  randomCoordinate rd (.clk(SNAKE_CLOCK), .x(intX), .y(intY));
  
  // generateApple apple (.clk(CLOCK_50), .reset(RST), .RedPixels, .GrnPixels, .x(intX), .y(intY));
  logic [15:0][15:0] randomize;

  int present_x, present_y;
  int next_x, next_y;

  logic isDup_curr, isDup_next;

  always_comb begin
    // we only update the apple coordinate when we eat the apple
    isDup_next = 1'b0;
    if (RST) begin
      next_x = present_x;
      next_y = present_y;
      randomize = '0;
    end 
    else if (isDup_curr) begin
      next_x = intX;
      next_y = intY;
      if (randomize[next_x][next_y]) begin
        isDup_next = 1'b1;
      end
    end
    else if (eatApple_p) begin
      next_x = intX;
      next_y = intY;
      // if it's already on
      if (randomize[next_x][next_y]) begin
        isDup_next = 1'b1;
      end
      randomize[present_x][present_y] = 1'b0;
    end
    else begin
      next_x = present_x;
      next_y = present_y;
      randomize[present_x][present_y] = 1'b1;
    end
  end

  always_ff @(posedge SNAKE_CLOCK) begin
    if (RST) begin
      present_x <= 12;
      present_y <= 12;
      isDup_curr <= 1'b0;
    end
    else begin
      present_x <= next_x;
      present_y <= next_y;
      isDup_curr <= isDup_next;
    end
  end

  //===================Initialize score tracker================

  int score;

  logic [15:0][15:0] isEatApple_out;
  logic eatApple_p, eatApple_n;

  always_comb begin
    eatApple_n = 1'b0;
    for (int row = 0; row < 16; row++) begin
      for (int col = 0; col < 16; col++) begin
        if (isEatApple_out[row][col]) begin
          eatApple_n = 1'b1;
          break;
        end
      end
      if (eatApple_n) begin
        break;
      end
    end
  end

  always_ff @(posedge CLOCK_50) begin
    if (RST) begin
      eatApple_p <= 1'b0;
    end 
    else begin
      eatApple_p <= eatApple_n;
    end
  end

  scoreTracker scoreTrack (.clk(SNAKE_CLOCK), .reset(RST), .isEatApple(eatApple_p),
    .out_hex1(HEX1), .out_hex0(HEX0), .score(score));

  //===================Initialize each cell====================

  genvar x2, y2;
  generate
    for(x2 = 0; x2 < 16; x2 += 1) begin : row
      for (y2 = 0; y2 < 16; y2 += 1) begin : col
        // head (top-left)
        if (x2 == 0 & y2 == 15) begin
          cellLight_modified #(.initialTime(3)) snakeCell (.clk(SNAKE_CLOCK), .reset(RST),
          .score,
          .isStart(1'b1),
          .isApple(randomize[x2][y2]),
          .leftCell({RedPixels[0][0], GrnPixels[0][0]}),
          .rightCell({RedPixels[x2][y2 - 1], GrnPixels[x2][y2 - 1]}),
          .topCell({RedPixels[15][15], GrnPixels[15][15]}),
          .bottomCell({RedPixels[x2 + 1][y2], GrnPixels[x2 + 1][y2]}),
          .currCell({RedPixels[x2][y2], GrnPixels[x2][y2]}),
          .direction(direction),
          .out_red(RedPixels[x2][y2]),
          .out_green(GrnPixels[x2][y2]),
          .isEatApple_out(isEatApple_out[x2][y2])
          );
        end
        // top right
        else if (x2 == 0 & y2 == 0) begin
          cellLight_modified #(.initialTime(3)) snakeCell (.clk(SNAKE_CLOCK), .reset(RST),
          .score,
          .isStart(1'b0),
          .isApple(randomize[x2][y2]),
          .leftCell({RedPixels[x2][y2 + 1], GrnPixels[x2][y2 + 1]}),
          .rightCell({RedPixels[0][15], GrnPixels[0][15]}),
          .topCell({RedPixels[15][0], GrnPixels[15][0]}),
          .bottomCell({RedPixels[x2 + 1][y2], GrnPixels[x2 + 1][y2]}),
          .currCell({RedPixels[x2][y2], GrnPixels[x2][y2]}),
          .direction(direction),
          .out_red(RedPixels[x2][y2]),
          .out_green(GrnPixels[x2][y2]),
          .isEatApple_out(isEatApple_out[x2][y2])
          );
        end
        // bottom left
        else if (x2 == 15 & y2 == 15) begin
          cellLight_modified #(.initialTime(3)) snakeCell (.clk(SNAKE_CLOCK), .reset(RST),
          .score,
          .isStart(1'b0),
          .isApple(randomize[x2][y2]),
          .leftCell({RedPixels[15][0], GrnPixels[15][0]}),
          .rightCell({RedPixels[x2][y2 - 1], GrnPixels[x2][y2 - 1]}),
          .topCell({RedPixels[x2 - 1][y2], GrnPixels[x2 - 1][y2]}),
          .bottomCell({RedPixels[0][15], GrnPixels[0][15]}),
          .currCell({RedPixels[x2][y2], GrnPixels[x2][y2]}),
          .direction(direction),
          .out_red(RedPixels[x2][y2]),
          .out_green(GrnPixels[x2][y2]),
          .isEatApple_out(isEatApple_out[x2][y2])
          );
        end
        // bottom right
        else if (x2 == 15 & y2 == 0) begin
          cellLight_modified #(.initialTime(3)) snakeCell (.clk(SNAKE_CLOCK), .reset(RST),
          .score,
          .isStart(1'b0),
          .isApple(randomize[x2][y2]),
          .leftCell({RedPixels[x2][y2 + 1], GrnPixels[x2][y2 + 1]}),
          .rightCell({RedPixels[15][15], GrnPixels[15][15]}),
          .topCell({RedPixels[x2 - 1][y2], GrnPixels[x2 - 1][y2]}),
          .bottomCell({RedPixels[0][0], GrnPixels[0][0]}),
          .currCell({RedPixels[x2][y2], GrnPixels[x2][y2]}),
          .direction(direction),
          .out_red(RedPixels[x2][y2]),
          .out_green(GrnPixels[x2][y2]),
          .isEatApple_out(isEatApple_out[x2][y2])
          );
        end
        // top border
        else if (x2 == 0) begin
          cellLight_modified #(.initialTime(3)) snakeCell (.clk(SNAKE_CLOCK), .reset(RST),
          .score,
          .isStart(1'b0),
          .isApple(randomize[x2][y2]),
          .leftCell({RedPixels[x2][y2 + 1], GrnPixels[x2][y2 + 1]}),
          .rightCell({RedPixels[x2][y2 - 1], GrnPixels[x2][y2 - 1]}),
          .topCell({RedPixels[15][y2], GrnPixels[15][y2]}),
          .bottomCell({RedPixels[x2 + 1][y2], GrnPixels[x2 + 1][y2]}),
          .currCell({RedPixels[x2][y2], GrnPixels[x2][y2]}),
          .direction(direction),
          .out_red(RedPixels[x2][y2]),
          .out_green(GrnPixels[x2][y2]),
          .isEatApple_out(isEatApple_out[x2][y2])
          );
        end
        // left border
        else if (y2 == 15) begin
          cellLight_modified #(.initialTime(3)) snakeCell (.clk(SNAKE_CLOCK), .reset(RST),
          .score,
          .isStart(1'b0),
          .isApple(randomize[x2][y2]),
          .leftCell({RedPixels[x2][0], GrnPixels[x2][0]}),
          .rightCell({RedPixels[x2][y2 - 1], GrnPixels[x2][y2 - 1]}),
          .topCell({RedPixels[x2 - 1][y2], GrnPixels[x2 - 1][y2]}),
          .bottomCell({RedPixels[x2 + 1][y2], GrnPixels[x2 + 1][y2]}),
          .currCell({RedPixels[x2][y2], GrnPixels[x2][y2]}),
          .direction(direction),
          .out_red(RedPixels[x2][y2]),
          .out_green(GrnPixels[x2][y2]),
          .isEatApple_out(isEatApple_out[x2][y2])
          );
        end
        // bottom border
        else if (x2 == 15) begin
          cellLight_modified #(.initialTime(3)) snakeCell (.clk(SNAKE_CLOCK), .reset(RST),
          .score,
          .isStart(1'b0),
          .isApple(randomize[x2][y2]),
          .leftCell({RedPixels[x2][y2 + 1], GrnPixels[x2][y2 + 1]}),
          .rightCell({RedPixels[x2][y2 - 1], GrnPixels[x2][y2 - 1]}),
          .topCell({RedPixels[x2 - 1][y2], GrnPixels[x2 - 1][y2]}),
          .bottomCell({RedPixels[0][y2], GrnPixels[0][y2]}),
          .currCell({RedPixels[x2][y2], GrnPixels[x2][y2]}),
          .direction(direction),
          .out_red(RedPixels[x2][y2]),
          .out_green(GrnPixels[x2][y2]),
          .isEatApple_out(isEatApple_out[x2][y2])
          );
        end
        // right border
        else if (y2 == 0) begin
          cellLight_modified #(.initialTime(3)) snakeCell (.clk(SNAKE_CLOCK), .reset(RST),
          .score,
          .isStart(1'b0),
          .isApple(randomize[x2][y2]),
          .leftCell({RedPixels[x2][y2 + 1], GrnPixels[x2][y2 + 1]}),
          .rightCell({RedPixels[x2][15], GrnPixels[x2][15]}),
          .topCell({RedPixels[x2 - 1][y2], GrnPixels[x2 - 1][y2]}),
          .bottomCell({RedPixels[x2 + 1][y2], GrnPixels[x2 + 1][y2]}),
          .currCell({RedPixels[x2][y2], GrnPixels[x2][y2]}),
          .direction(direction),
          .out_red(RedPixels[x2][y2]),
          .out_green(GrnPixels[x2][y2]),
          .isEatApple_out(isEatApple_out[x2][y2])
          );
        end
        // anything that is on the center
        else begin
          cellLight_modified #(.initialTime(3)) snakeCell (.clk(SNAKE_CLOCK), .reset(RST),
          .score,
          .isStart(1'b0),
          .isApple(randomize[x2][y2]),
          .leftCell({RedPixels[x2][y2 + 1], GrnPixels[x2][y2 + 1]}),
          .rightCell({RedPixels[x2][y2 - 1], GrnPixels[x2][y2 - 1]}),
          .topCell({RedPixels[x2 - 1][y2], GrnPixels[x2 - 1][y2]}),
          .bottomCell({RedPixels[x2 + 1][y2], GrnPixels[x2 + 1][y2]}),
          .currCell({RedPixels[x2][y2], GrnPixels[x2][y2]}),
          .direction(direction),
          .out_red(RedPixels[x2][y2]),
          .out_green(GrnPixels[x2][y2]),
          .isEatApple_out(isEatApple_out[x2][y2])
          );
        end
      end
    end
  endgenerate

endmodule