module playfieldManager (
  input logic reset, clk
  ,input logic [3:0] appleX, appleY
  ,output logic [15:0][15:0] RedPixels // 16x16 array of red LEDs
  ,output logic [15:0][15:0] GrnPixels // 16x16 array of green LEDs
  );

  logic [3:0] presentX_s, presentY_s, nextX_s, nextY_s;

  always_comb begin
    // maybe we don't need this module?
    // creates the border + snake initial state
    nextX_s = appleX;
    nextY_s = appleY;

    RedPixels[presentX_s][presentY_s] = 1'b0;
    RedPixels[nextX_s][nextY_s] = 1'b1;
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      // Reset - get snake initial state ?
      // Turn off all LEDs
      // snake body on [row][col] = [6][9], [6][10]
      // snake head on [row][col] = [6][8]
      // Display a pattern
      //                  FEDCBA9876543210
      RedPixels[00] = 16'b0000000000000000;
      RedPixels[01] = 16'b0000000000000000;
      RedPixels[02] = 16'b0000000000000000;
      RedPixels[03] = 16'b0000000000000000;
      RedPixels[04] = 16'b0000000000000000;
      RedPixels[05] = 16'b0000000000000000;
      RedPixels[06] = 16'b0000011000000000;
      RedPixels[07] = 16'b0000000000000000;
      RedPixels[08] = 16'b0000000000000000;
      RedPixels[09] = 16'b0000000000000000;
      RedPixels[10] = 16'b0000000000000000;
      RedPixels[11] = 16'b0000000000000000;
      RedPixels[12] = 16'b0000000000000000;
      RedPixels[13] = 16'b0000000000000000;
      RedPixels[14] = 16'b0000000000000000;
      RedPixels[15] = 16'b0000000000000000;
      
      //                  FEDCBA9876543210
      GrnPixels[00] = 16'b0000000000000000;
      GrnPixels[01] = 16'b0000000000000000;
      GrnPixels[02] = 16'b0000000000000000;
      GrnPixels[03] = 16'b0000000000000000;
      GrnPixels[04] = 16'b0000000000000000;
      GrnPixels[05] = 16'b0000000000000000;
      GrnPixels[06] = 16'b0000011100000000;
      GrnPixels[07] = 16'b0000000000000000;
      GrnPixels[08] = 16'b0000000000000000;
      GrnPixels[09] = 16'b0000000000000000;
      GrnPixels[10] = 16'b0000000000000000;
      GrnPixels[11] = 16'b0000000000000000;
      GrnPixels[12] = 16'b0000000000000000;
      GrnPixels[13] = 16'b0000000000000000;
      GrnPixels[14] = 16'b0000000000000000;
      GrnPixels[15] = 16'b0000000000000000;
		end
    else begin
      presentX_s <= nextX_s;
      presentY_s <= nextY_s;
    end
  end
endmodule