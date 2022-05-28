module fulladd (
  output logic cout, s
  ,input logic cin, a, b
  );

  always_comb begin
    {cout, s} = cin + a + b;
  end
endmodule

module fulladd_tb();
  logic cin, a, b;
	logic cout, s;
	
	fulladd dut (.*);
	
	integer i;
	logic [2:0] in;
	initial begin
		for(i = 0; i < 8; i++) begin
			in[2:0] = i; #10;
			cin = in[2];
			a = in[1];
			b = in[0];
		end
	end
endmodule