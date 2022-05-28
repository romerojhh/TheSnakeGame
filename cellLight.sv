// Every time the head of the snake pass through the cell, we need to kepp holding it on
// Check the status of current cell at every posedge clock -> if the cell are green (head), 
// then we will turn on the next clock cycle for "holdTime" where the unit of time is 1 clock cycle
// in this module we used modified clk speed!

// APPLE -> red!
// BODY & BORDER -> orange!
// HEAD -> green!

// if left || right || top || bottom is green
// and the direction is leading to us, then this current cell will be green in the next clock cycle

// Direction
// right = +1
// left = -1
// up = +1
// down = -1

// TODO: Create a module for initializing the snake when a reset button is pressed
// the specs wants the snake to start with 2 trailing body segments

module cellLight (
  input logic clk, reset
  ,input int holdTime
  ,input logic [1:0] leftCell, rightCell, topCell, bottomCell
  ,input logic [1:0] direction
  ,input logic isEatApple
  ,output logic out_red, out_green
  );
  
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

  cellStateColor present_s, next_s;

  int timer_curr, timer_next;

  // if the cell is red (apple) or off
  // we can overwrite that color with green
  always_comb begin
    if (present_s == off || present_s == red) begin
      case (direction)
        right: begin
          if (leftCell == green)
            next_s = green;
            timer_next = holdTime - 1;
        end

        left: begin
          if (rightCell == green)
            next_s = green;
            timer_next = holdTime - 1;
        end

        down: begin
          if (topCell == green)
            next_s = green;
            timer_next = holdTime - 1;
        end

        up: begin
          if (bottomCell == green)
            next_s = green;
            timer_next = holdTime - 1;
        end

        default: next_s = off;
      endcase  
    end

    // When the cell is already "on" we only want to keep it turn on
    // for "holdTime - 1" amount of time since it already turned on
    // on "green"
    else begin
      if (timer_curr <= 0) 
        next_s = off;
      else
        next_s = orange;

      if (isEatApple)
        timer_next = timer_curr;
      else
        timer_next = timer_curr - 1;
    end

    {out_red, out_green} = present_s;

  end

  always_ff @(posedge clk) begin
    if (reset) begin
      present_s <= off;
      timer_curr <= 0;
    end
    else begin
      present_s <= next_s;
      timer_curr <= timer_next;
    end
  end
endmodule

module cellLight_tb();
  logic clk, reset;
  int holdTime;
  logic [1:0] leftCell, rightCell, topCell, bottomCell;
  logic [1:0] direction;
  logic isEatApple;
  logic out_red, out_green;

  cellLight dut (.*);

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

  // Set up the clock
  parameter CLOCK_PERIOD = 100;
  initial begin
    clk <= 0;
    forever #(CLOCK_PERIOD/2) clk <= ~clk;
  end

  // Set up the inputs to the design. Each line is a clock cycle.
  initial begin
    @(posedge clk); reset <= 1; isEatApple <= 0;
    @(posedge clk); reset <= 0;
    // test leftCell & rightDir
    @(posedge clk); leftCell <= green; direction <= right; holdTime <= 5;
    @(posedge clk); leftCell <= orange;
    @(posedge clk); isEatApple <= 1;
    @(posedge clk); isEatApple <= 0;

    // if we eat an apple, the time is extended by 1
    for (int i = 0; i < holdTime + 1; i++)
      @(posedge clk);

    @(posedge clk);
    $stop; // End the simulation
  end
  
endmodule