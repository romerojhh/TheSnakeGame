module LFSR9 #(parameter WIDTH = 9)
	(output logic [WIDTH-1:0] ps = 9'b110110110 // present state
	 ,input logic clk // clock input
	);
	
	always_ff @(posedge clk) begin
		ps <= {ps[WIDTH-2:0], ~(ps[WIDTH-1] ^ ps[WIDTH-5])};
	end
endmodule

module LFSR9_tb();
	logic [8:0] ps;
	logic CLOCK_50;
	
	LFSR9 #(.WIDTH(9)) dut (.*, .clk(CLOCK_50));
	
	// Set up the clock
  parameter CLOCK_PERIOD = 100;
  initial begin
    CLOCK_50 <= 0;
    forever #(CLOCK_PERIOD/2) CLOCK_50 <= ~CLOCK_50;
  end
	
	// Set up the inputs to the design. Each line is a clock cycle.
  initial begin
		#12000
		$stop; // End the simulation
  end
	
endmodule