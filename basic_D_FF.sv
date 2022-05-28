module basic_D_FF (q, d, clk);
	output logic q; // q is state-holding
	input logic d, clk;
	always_ff @(posedge clk)
	q <= d; // use <= for clocked elements
endmodule