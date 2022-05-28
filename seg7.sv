module seg7 (
	input logic [3:0] bcd
	,output logic [6:0] leds
	);
	
	always_comb begin
		case (bcd)
			// 			 Light:     6543210
			4'b0000: leds = ~7'b0111111; // 0
			4'b0001: leds = ~7'b0000110; // 1
			4'b0010: leds = ~7'b1011011; // 2
			4'b0011: leds = ~7'b1001111; // 3
			4'b0100: leds = ~7'b1100110; // 4
			4'b0101: leds = ~7'b1101101; // 5
			4'b0110: leds = ~7'b1111101; // 6
			4'b0111: leds = ~7'b0000111; // 7
			4'b1000: leds = ~7'b1111111; // 8
			4'b1001: leds = ~7'b1101111; // 9
			default: leds = 7'bX; // Invalid
		endcase
	end
endmodule

module seg7_tb();
	logic [3:0] bcd;
	logic [6:0] leds;

	// instantiate device under test
	seg7 dut (.bcd, .leds);

	// test input sequence - try all combinations of inputs
	integer i;
	initial begin
		bcd[0] = 1'b0;
		bcd[1] = 1'b0;
		bcd[2] = 1'b0;
		bcd[3] = 1'b0;
		for(i = 0; i < 16; i++) begin
			bcd[3:0] = i; #10;
		end
	end
endmodule  // seg7_testbench
