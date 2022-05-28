module addNgen #(parameter N=32) (
  output logic OF, CF        // overflow and carry flags
  ,output logic [N-1:0] S    // sum output bus
  ,input logic sub           // subtract signal
  ,input logic [N-1:0] A, B  // input busses
  );

  logic [N:0]  C;          // carry signals between modules
  genvar i;

  generate
    for(i=0; i<N; i=i+1) begin : adders
      fulladd fadd (C[i+1],S[i],C[i],A[i],sub^B[i]);
    end
  endgenerate

  assign C[0] = sub;
  assign CF   = C[N];
  assign OF   = C[N] ^ C[N-1];
endmodule

module addNgen_tb();
  logic OF, CF;
  logic [31:0] S;
  logic sub;
  logic [31:0] A, B;

  always_comb begin
    A = 'd12;
    B = 'd13;
    sub = 1'b0;
  end

  addNgen #(.N(32)) dut (.*);

endmodule