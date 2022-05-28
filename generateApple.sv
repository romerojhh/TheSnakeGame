/*
  This module handles how to generate an apple in the playfield
  this module will call randomCoordinate to generate random coordinate for the apple.
  If the cell light is already "on" (orange, red, green), 
  we then shift the apple location by either 1 to the left, right, down, or up.
*/

// There is a chance of bug in this module implementation --> FIXED

// should I send the coordinate or directly lights the led from here?
module generateApple (
  input logic clk, reset
  ,input logic [15:0][15:0] RedPixels // 16x16 array of red LEDs
  ,input logic [15:0][15:0] GrnPixels // 16x16 array of green LEDs
  ,output logic [3:0] x, y
  );

  typedef enum logic [1:0] { 
    red = 2'b10
    ,green = 2'b01
    ,orange = 2'b11
    ,off = 2'b00
  } cellStateColor;

  typedef struct packed {
   int xCoordinate;
   int yCoordinate;
  } state;

  state present_s, next_s;
  state modified;

  randomCoordinate getRandom(.clk, .x(next_s.xCoordinate), .y(next_s.yCoordinate));

  logic isFound;

  // algorithm to verify the present_s whether it's valid or not
  // TODO: maybe change it to verify next_s instead?
  always_comb begin
    isFound = 1'b0;
    modified = present_s;
    // [row][col]
    if (RedPixels[present_s.xCoordinate][present_s.yCoordinate] |
        GrnPixels[present_s.xCoordinate][present_s.yCoordinate]) begin

      // Check right side if it's off
      if (~RedPixels[present_s.xCoordinate][present_s.yCoordinate + 1] &
        ~GrnPixels[present_s.xCoordinate][present_s.yCoordinate + 1]) begin
          
        modified.yCoordinate += 1;
      end
      // check left side if it's off
      else if (~RedPixels[present_s.xCoordinate][present_s.yCoordinate - 1] & 
        ~GrnPixels[present_s.xCoordinate][present_s.yCoordinate - 1]) begin

        modified.yCoordinate -= 1;
      end
      // check top side if it's off
      else if (~RedPixels[present_s.xCoordinate - 1][present_s.yCoordinate] & 
        ~GrnPixels[present_s.xCoordinate - 1][present_s.yCoordinate]) begin

        modified.xCoordinate -= 1;
      end
      // check if bottom cell is off
      else if (~RedPixels[present_s.xCoordinate + 1][present_s.yCoordinate] & 
        ~GrnPixels[present_s.xCoordinate + 1][present_s.yCoordinate]) begin

        modified.xCoordinate += 1;
      end
      // if all on -> find it iteratively
      else begin
        // traverse all possible row col in the 2d matrix
        for (int row = 0; row < 16 & ~isFound; row += 1) begin
          for (int col = 0; col < 16 & ~isFound; col += 1) begin
            if (~RedPixels[row][col] & ~GrnPixels[row][col]) begin
              modified.xCoordinate = row;
              modified.yCoordinate = col;
              isFound = 1'b1;
            end
            else
              isFound = 1'b0;
          end
        end
      end
    end
    else begin
      modified.xCoordinate = present_s.xCoordinate;
      modified.yCoordinate = present_s.yCoordinate;
    end

    x = modified.xCoordinate;
    y = modified.yCoordinate;
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      present_s.xCoordinate <= 12;
      present_s.yCoordinate <= 12;
    end 
    else 
      present_s.xCoordinate <= next_s.xCoordinate;
      present_s.yCoordinate <= next_s.yCoordinate;
  end
endmodule

module generateApple_tb();
  logic clk, reset;
  logic [15:0][15:0] RedPixels;
  logic [15:0][15:0] GrnPixels;
  logic [3:0] x, y;

  generateApple dut (.*);

  // Set up the clock
  parameter CLOCK_PERIOD = 100;
  initial begin
    clk <= 0;
    forever #(CLOCK_PERIOD/2) clk <= ~clk;
  end

  // Set up the inputs to the design. Each line is a clock cycle.
  initial begin
    @(posedge clk); RedPixels <= '0; GrnPixels <= '0;
    //@(posedge clk); RedPixels[5][6] <= 1;
    @(posedge clk); RedPixels[12][12] <= 1; RedPixels[11][12] <= 1; RedPixels[13][12] <= 1; RedPixels[12][11] <= 1; RedPixels[12][13] <= 1;
    RedPixels[0][0] <= 1;
    @(posedge clk); reset <= 1;
    @(posedge clk); reset <= 0;
    for (int i = 0; i < 10; i++) begin
      @(posedge clk);
    end
    $stop; // End the simulation
  end

endmodule
