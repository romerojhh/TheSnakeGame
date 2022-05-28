/*
  This module handle the behaviour of the game when the snake hit
  either wall or its own body (orange), or apples (red)

  If the snake head (green) hits the apple -> score will be incremented by 1
  and the module will give signal that an apple is hit

  If the snake head (green) hits either wall or its own body (orange) -> the game over module is called
  The user have to reset in order to play again
*/

// The collision state detector requires that the cell has to be green! (head)
module collisionDetector (
  input logic clk, reset
  ,input logic [1:0] leftCell, rightCell, topCell, bottomCell
  ,input logic [1:0] direction
  ,input logic [1:0] currCell
  ,output logic isEatApple, isGameOver
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

  typedef enum logic [1:0] {
    eatApple = 2'b10
    ,gameOver = 2'b01
    ,normal = 2'b00
  } collisionState;

  collisionState present_s, next_s;

  always_comb begin
    // If present state is normal
    // check for abnormalities
    if (present_s == normal) begin

      // the only time we can get abnormalities is when the current cell color is green
      if (currCell == green) begin
        case (direction)
          // if going right and the right cell is orange -> dead
          // if red -> eat apple, increment score
          right: begin
            if (rightCell == orange)
              next_s = gameOver;
            else if (rightCell == red) 
              next_s = eatApple;
          end

          left: begin
            if (leftCell == orange) 
              next_s = gameOver;
            else if (leftCell == red)
              next_s = eatApple;
          end

          down: begin
            if (bottomCell == orange) 
              next_s = gameOver;
            else if (bottomCell == red) 
              next_s = eatApple;
          end

          up: begin
            if (topCell == orange) 
              next_s = gameOver;
            else if (topCell == red) 
              next_s = eatApple;
          end

          default: begin
            next_s = present_s;
          end
          // will top level reset the isGameOver?
          // assume yes.
        endcase
      end 
      else begin
        next_s = present_s;
      end

    end 
    else if (present_s == eatApple) begin
      // if the state is eat apple, turn it back to normal
      next_s = normal; 
    end 
    else begin
      // if the state is game over, stay game over
      next_s = present_s; 
    end

    {isEatApple, isGameOver} = present_s;
  end

  always_ff @(posedge clk) begin
    if (reset) 
      present_s <= normal;
    else 
      present_s <= next_s;
  end
endmodule

module collisionDetector_tb();
  logic clk, reset;
  logic [1:0] leftCell, rightCell, topCell, bottomCell;
  logic [1:0] direction;
  logic [1:0] currCell;
  logic isEatApple, isGameOver;

  collisionDetector dut (.*);

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

  // Set up the clock
  parameter CLOCK_PERIOD = 100;
  initial begin
    clk <= 0;
    forever #(CLOCK_PERIOD/2) clk <= ~clk;
  end

  // Set up the inputs to the design. Each line is a clock cycle.
  initial begin
    @(posedge clk); reset <= 1;
    @(posedge clk); reset <= 0;
    // test leftCell & rightDir
    @(posedge clk); rightCell <= red; direction <= right; currCell <= green;
    @(posedge clk);

    for (int i = 0; i < 2; i++)
      @(posedge clk);

    @(posedge clk);
    $stop; // End the simulation
  end

endmodule