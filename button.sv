/*
  When the user hold the direction button 
  it will only take 1 output value out of it
*/

// Simple FSM to recognize sequences of 0-1 on input key_in.
module button (
  input   logic clock, reset, key_in
  ,output logic key_out
  );

  // State encoding
  // an enum is a straightforward way to assign clear names to our FSM states
  // while also being able to specify the bit representation of each state.
  typedef enum logic [1:0]
  {
    e_ready = 2'b00    // ready and waiting for a 1 on key_in
    ,e_first = 2'b01   // saw a 1 last cycle on key_in
    ,e_second = 2'b10  // saw 1-1 over last two cycles on key_in
  } state_e;

  state_e present_s, next_s;

  // Combinational Logic
  always_comb begin
    // stay in current state
    next_s = present_s;
    // FSM Next State Logic
    case (present_s)
      e_ready: begin
        if (key_in) next_s = e_first; // saw first 1 on key_in
        else   next_s = e_ready;
      end
      e_first: begin
        if (key_in) next_s = e_second; // saw second 1 on key_in
        else   next_s = e_ready;
      end
      e_second: begin
        if (key_in) next_s = e_second; // stay here if 1 on key_in
        else   next_s = e_ready;
      end
      default: begin
        next_s = state_e'('x);
      end
    endcase
		
    key_out = (present_s == e_first); // ->>>> this is the only part that is different
  end

  // Sequential Logic
  always_ff @(posedge clock) begin
    if (reset) begin
      present_s <= e_ready;
    end else begin
      present_s <= next_s;
    end
  end

endmodule

module button_tb();
	logic clock, reset, key_in;
	logic key_out;
	
	button dut (.*);
	
	// Set up the clock
  parameter CLOCK_PERIOD = 100;
  initial begin
    clock <= 0;
    forever #(CLOCK_PERIOD/2) clock <= ~clock;
  end
	
	// Set up the inputs to the design. Each line is a clock cycle.
  initial begin
    @(posedge clock); reset <= 1; 
    @(posedge clock);	reset <= 0; key_in <= 1;
		@(posedge clock);	key_in <= 0;
		@(posedge clock); 
		@(posedge clock); key_in <= 1;
		@(posedge clock); 
		@(posedge clock); 
		@(posedge clock); key_in <= 0;
    $stop; // End the simulation
  end
endmodule

