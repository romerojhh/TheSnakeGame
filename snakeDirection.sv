/*
  This module manage the direction of the snake
  it will use 4 inputs that represent the "pressed" direction
  output the direction depending on the current KEY value

  Use regular clock in this module

  The default direction for snake is right
*/

module snakeDirection (
  input logic in_right, in_down, in_left, in_up
  ,input logic clk, reset
  ,output logic [1:0] direction
  );

  // we can only handle 1 input at a time
  // i.e., in_right can't be happening the same time as in_down
  // AND
  // if there is no input
  // keep holding the previous value
  
  typedef enum logic [1:0] {
    right = 2'b00
    ,down = 2'b01
    ,left = 2'b10
    ,up = 2'b11
  } outputDirection;

  outputDirection present_s, next_s;

  always_comb begin
    if (in_right & ~in_down & ~in_left & ~in_up & present_s != left)
      next_s = right;
    else if (in_left & ~in_down & ~in_right & ~in_up & present_s != right)
      next_s = left;
    else if (in_up & ~in_down & ~in_right & ~in_left & present_s != down)
      next_s = up;
    else if (in_down & ~in_up & ~in_right & ~in_left & present_s != up)
      next_s = down;
    else
      next_s = present_s;
    
    direction = present_s;
  end

  // Default direction of the snake is to the right
  always_ff @(posedge clk) begin
    if (reset)
      present_s <= right;
    else
      present_s <= next_s;
  end

endmodule

module snakeDirection_tb();
  logic in_right, in_down, in_left, in_up;
  logic clk, reset;
  logic [1:0] direction;

  snakeDirection snake (.*);

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

  logic [3:0] dir;
  // Set up the inputs to the design. Each line is a clock cycle.
  initial begin
    @(posedge clk); reset <= 1;
    @(posedge clk); reset <= 0;

    // all direction
    for (int i = 0; i <= 16; i++) begin
      dir[3:0] <= i;
      {in_right, in_down, in_left, in_up} <= dir;
      @(posedge clk); 
      @(posedge clk);
    end
    @(posedge clk);
    $stop; // End the simulation
  end
endmodule
