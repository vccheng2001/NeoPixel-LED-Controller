`default_nettype none

// NeoPixel LED Controller 
module NeoPixelStrandController
 #(parameter NUM_PIXELS = 5)
 (input logic [7:0] color_level,
 input logic [1:0] color_index,
 input logic [2:0] pixel_index,
 input logic clock, reset, // clock must be 50MHz
 input logic load_color, send_it,
 output logic neo_data, ready_to_load, ready_to_send);

 // Define color logic 
 logic [2:0][7:0] G, R, B;
 logic [2:0][23:0] LED_Command;

 // Assign LED Commands to create display packet
 genvar i; 
 generate;
 for (i = 0; i < 5; i++) begin: LED_Commands
    assign LED_Command[i] = {G[i],R[i],B[i]};
 end
 endgenerate

  // States
  enum logic [1:0] {IDLE, LOADING, SENDING} currstate, nextstate;

  // Next state logic 
  always_ff @(posedge clock, posedge reset)
    if (reset) currstate <= IDLE;  
    else currstate <= nextstate;   

  // FSM logic for states/output values
  always_comb begin
    case (currstate)
      IDLE: begin
        // Upon reset, ready to load/send 
        ready_to_load = 1; ready_to_send = 1;

        // Load a specified color value into R, G, or B for one LED
        if (load_color) begin 
           case(color_index) 
               2'b00: R[pixel_index] = color_level; // Red
               2'b01: B[pixel_index] = color_level; // Blue
               2'b10: G[pixel_index] = color_level; // Green 
           endcase
        end 

        if (send_it) begin 
            // gen serial output
        end 

      end
      
    endcase
  end
endmodule:hw0

