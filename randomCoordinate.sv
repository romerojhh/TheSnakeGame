/*
  This module handle the random coordinate for generating apple
  it will output coordinate x[1,14] and y[1,14]
  since we are considering the border
*/

module randomCoordinate(
    input logic clk
    ,output logic [3:0] x
    ,output logic [3:0] y
  );

  logic [8:0] random;

  LFSR9 #(.WIDTH(9)) xRandGen (.ps(random), .clk);

  logic [3:0] ps_x, ns_x;
  logic [3:0] ps_y, ns_y;

  always_comb begin
    ns_x = {random[0], random[4], random[2], random[1]};
    ns_y = {random[3], random[8], random[5], random[6]};

    // TODO: Handle the case when the number is 15
    // -- Already handled! changed the LSB binary to 1'b1

    if (ns_y == ps_y | ns_y == 4'b0000 | ns_y == 4'b1111) begin
      ns_y = {ns_y[2] ^ ps_x[1], ns_y[1] ^ ps_x[3], 1'b1};
    end

    if (ns_x == ps_x | ns_x == 4'b0000 | ns_x == 4'b1111) begin
      ns_x = {ns_x[3] ^ ps_y[0], ns_x[1] ^ ps_y[2], 1'b1};
    end

    x = ps_x;
    y = ps_y;
  end

  always_ff @(posedge clk) begin
    // TODO: should I add reset here?
    ps_x <= ns_x;
    ps_y <= ns_y;
  end
  
endmodule

module randomCoordinate_tb();
  logic clk;
  logic [3:0] x, y;

  randomCoordinate dut (.*);

  // Set up the clock
  parameter CLOCK_PERIOD = 100;
  initial begin
    clk <= 0;
    forever #(CLOCK_PERIOD/2) clk <= ~clk;
  end

  // Set up the inputs to the design. Each line is a clock cycle.
  initial begin
    for (int i = 0; i < 50; i++) begin
      @(posedge clk); 
    end
    $stop; // End the simulation
  end

endmodule