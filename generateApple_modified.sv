/*
  This module handles how to generate an apple in the playfield
  this module will call randomCoordinate to generate random coordinate for the apple.
  If the cell light is already "on" (orange, red, green), 
  we then shift the apple location by either 1 to the left, right, down, or up.
*/

// There is a chance of bug in this module implementation --> FIXED

// should I send the coordinate or directly lights the led from here?
module generateApple_modified (
  input logic clk, reset
  ,input logic [15:0][15:0] randomizer // 16x16 array of red LEDs
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

  randomCoordinate getRandom(.clk, .x(next_s.xCoordinate), .y(next_s.yCoordinate));

  int newY = -1;
  int newX = -1;
  logic isFound = 1'b0;

  // algorithm to verify the present_s whether it's valid or not
  // TODO: maybe change it to verify next_s instead?
  always_comb begin
    // [row][col]
    //$display("x: %d, y: %d", present_s.xCoordinate, present_s.yCoordinate);
    //$display("red: %b", RedPixels[present_s.xCoordinate][present_s.yCoordinate]);
    if (RedPixels[present_s.xCoordinate][present_s.yCoordinate] |
        GrnPixels[present_s.xCoordinate][present_s.yCoordinate]) begin
          
      //$display("in");

      // Check right side if it's off
      if (~RedPixels[present_s.xCoordinate][present_s.yCoordinate + 1] &
        ~GrnPixels[present_s.xCoordinate][present_s.yCoordinate + 1]) begin
        //$display("1");
        newX = present_s.xCoordinate;
        newY = present_s.yCoordinate + 1;
      end
      // check left side if it's off
      else if (~RedPixels[present_s.xCoordinate][present_s.yCoordinate - 1] & 
        ~GrnPixels[present_s.xCoordinate][present_s.yCoordinate - 1]) begin

        //$display("2");
        newX = present_s.xCoordinate;
        newY = present_s.yCoordinate - 1;
      end
      // check top side if it's off
      else if (~RedPixels[present_s.xCoordinate - 1][present_s.yCoordinate] & 
        ~GrnPixels[present_s.xCoordinate - 1][present_s.yCoordinate]) begin
        
        //$display("3");
        newX = present_s.xCoordinate - 1;
        newY = present_s.yCoordinate;
      end
      // check if bottom cell is off
      else if (~RedPixels[present_s.xCoordinate + 1][present_s.yCoordinate] & 
        ~GrnPixels[present_s.xCoordinate + 1][present_s.yCoordinate]) begin

        //$display("4");
        newX = present_s.xCoordinate + 1;
        newY = present_s.yCoordinate;
      end
      // if all on -> find it iteratively
      else begin
        // $display("5");
        // traverse all possible row col in the 2d matrix
        for (int row = 0; row < 16 & ~isFound; row += 1) begin
          for (int col = 0; col < 16 & ~isFound; col += 1) begin
            if (~RedPixels[row][col] & ~GrnPixels[row][col]) begin
              newX = row;
              newY = col;
              isFound = 1'b1;
            end
          end
        end

        isFound = 1'b0;

      end
    end

    if (newX != -1 | newY != - 1) begin
      x = newX;
      y = newY;
      newX = -1;
      newY = -1;
    end 
    else begin
      x = present_s.xCoordinate;
      y = present_s.yCoordinate;
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      present_s.xCoordinate <= 12;
      present_s.yCoordinate <= 12;
    end 
    else 
      present_s <= next_s;
  end
endmodule

module generateApple_modified_tb();
  logic clk, reset;
  logic [15:0][15:0] RedPixels;
  logic [15:0][15:0] GrnPixels;
  logic [3:0] x, y;

  generateApple_modified dut (.*);

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
