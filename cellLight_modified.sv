// Every time the head of the snake pass through the cell, we need to kepp holding it on
// Check the status of current cell at every posedge clock -> if the cell are green (head), 
// then we will turn on the next clock cycle for "initialTime" where the unit of time is 1 clock cycle
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

module cellLight_modified #(parameter initialTime = 0)
  (
  input logic clk, reset, isStart, isApple
  ,input logic [1:0] leftCell, rightCell, topCell, bottomCell, currCell
  ,input logic [1:0] direction
  ,input int score
  ,output logic out_red, out_green
  ,output logic isEatApple_out
  );
  
  // TYPEDEFS ------------------------------------
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

  //==============LOCAL VARIABLES===================

  cellStateColor colorPresent_s, colorNext_s;

  collisionState collisionPresent_s, collisionNext_s;

  startState startPresent_s, startNext_s;

  int timer_curr, timer_next;

  logic isEatApple, isGameOver;

  //========Managing collision====================

  always_comb begin
    // If present state is normal
    // check for abnormalities
    // the only time we can get abnormalities is when the current cell color is green
    // if (currCell == green) begin
    if (colorPresent_s == green) begin
      case (direction)
        // if going right and the right cell is orange -> dead
        // if red -> eat apple, increment score
        right: begin
          if (rightCell == orange)
            collisionNext_s = gameOver;
          else if (rightCell == red) 
            collisionNext_s = eatApple;
          else 
            collisionNext_s = normal;
        end

        left: begin
          if (leftCell == orange) 
            collisionNext_s = gameOver;
          else if (leftCell == red)
            collisionNext_s = eatApple;
          else 
            collisionNext_s = normal;
        end

        down: begin
          if (bottomCell == orange) 
            collisionNext_s = gameOver;
          else if (bottomCell == red) 
            collisionNext_s = eatApple;
          else 
            collisionNext_s = normal;
        end

        up: begin
          if (topCell == orange) 
            collisionNext_s = gameOver;
          else if (topCell == red) 
            collisionNext_s = eatApple;
          else 
            collisionNext_s = normal;            
        end

        default: begin
          collisionNext_s = normal;
        end
      endcase
    end 
    else begin
      collisionNext_s = normal;
    end

    //$display("isEatApple: %b", isEatApple);
    {isEatApple, isGameOver} = collisionPresent_s;
    isEatApple_out = isEatApple;
  end

  always_ff @(posedge clk) begin
    if (reset) 
      collisionPresent_s <= normal;
    else 
      collisionPresent_s <= collisionNext_s;
  end

  //========Managing the start state===============
  always_comb begin
    if (startPresent_s == startOn) 
      startNext_s = startOff;
    startNext_s = startOff;
  end

  always_ff @(posedge clk) begin
    if (reset)
      startPresent_s <= startState'(isStart);
    else
      startPresent_s <= startNext_s;
  end
  //===============================

  // if the cell is red (apple) or off
  // we can overwrite that color with green
  always_comb begin
    if (colorPresent_s == off | colorPresent_s == red) begin
      // We don't want to keep the start state to stay green
      if (startPresent_s) begin
        colorNext_s = green;
        timer_next = initialTime + score - 1;
      end
      // we have to know the score!!!
      else begin
        case (direction)
          right: begin
            if (leftCell == green) begin
              colorNext_s = green;
              timer_next = initialTime + score - 1;
            end
            else begin
              if (isApple) begin
                colorNext_s = red;
                timer_next = timer_curr;
              end else begin
                colorNext_s = colorPresent_s;
                timer_next = timer_curr;
              end
            end
          end

          left: begin
            if (rightCell == green) begin
              colorNext_s = green;
              timer_next = initialTime + score - 1;
            end 
            else begin
              if (isApple) begin
                colorNext_s = red;
                timer_next = timer_curr;
              end else begin
                colorNext_s = colorPresent_s;
                timer_next = timer_curr;
              end
            end              
          end

          down: begin
            if (topCell == green) begin
              colorNext_s = green;
              timer_next = initialTime + score - 1;
            end 
            else begin
              if (isApple) begin
                colorNext_s = red;
                timer_next = timer_curr;
              end else begin
                colorNext_s = colorPresent_s;
                timer_next = timer_curr;
              end
            end              
          end

          up: begin
            if (bottomCell == green) begin
              colorNext_s = green;
              timer_next = initialTime + score - 1;
            end 
            else begin
              if (isApple) begin
                colorNext_s = red;
                timer_next = timer_curr;
              end else begin
                colorNext_s = colorPresent_s;
                timer_next = timer_curr;
              end
            end
          end

          default: begin
            if (isApple) begin
              colorNext_s = red;
              timer_next = timer_curr;
            end else begin
              colorNext_s = colorPresent_s;
              timer_next = timer_curr;
            end
          end
        endcase
      end
    end

    // When the cell is orange we only want to keep it turn on
    // for "initialTime - 1" amount of time since it already turned on
    // on "green"
    else begin
      if (timer_curr <= 0) 
        colorNext_s = off;
      else
        colorNext_s = orange;

      // if (isEatApple) 
      //  timer_next = timer_curr;
      // else
      timer_next = timer_curr - 1;
    end

    {out_red, out_green} = colorPresent_s;
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      if (startPresent_s) begin
        colorPresent_s <= off;
        timer_curr <= initialTime;
      end
      else if (isApple) begin
        colorPresent_s <= red;
        timer_curr <= initialTime;
      end
      else begin
        colorPresent_s <= off;
        timer_curr <= 0;
      end
    end
    else begin
      colorPresent_s <= colorNext_s;
      timer_curr <= timer_next;
    end
  end
endmodule

// ====================== TESTBENCH =================

module cellLight_modified_tb();
  logic clk, reset, isStart, isApple;
  logic [1:0] leftCell, rightCell, topCell, bottomCell, currCell;
  logic [1:0] direction;
  logic out_red, out_green;
  logic isEatApple_out;
  int score;

  cellLight_modified #(.initialTime(3)) dut (.*);

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
    @(posedge clk); reset <= 1; isStart <= 1;
    @(posedge clk); reset <= 0;
    // test leftCell & rightDir
    @(posedge clk); currCell <= green; rightCell <= red; direction <= right;
    @(posedge clk); currCell <= orange; rightCell <= green;
    @(posedge clk);

    // if we eat an apple, the time is extended by 1
    for (int i = 0; i < 3 + 1; i++)
      @(posedge clk);

    @(posedge clk);
    $stop; // End the simulation
  end
  
endmodule