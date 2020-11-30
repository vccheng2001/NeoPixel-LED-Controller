`default_nettype none

// Counter, adapted from 18-240 library.sv 
module counter
  #(parameter WIDTH = 16) (
  input  logic clock, reset,
  input  logic clear, en,
  input  logic [WIDTH-1:0] d,
  output logic [WIDTH-1:0] q);

  always_ff @(posedge clock, posedge reset)
  if (reset) q <= 0;
  else if (en) q <= q + 1;
  else if (clear) q <= 0;

endmodule: counter