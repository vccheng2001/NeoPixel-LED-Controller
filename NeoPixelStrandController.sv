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
 generate
 for (i = 0; i < 5; i++) begin: LED_Commands
    assign LED_Command[i] = {G[i],R[i],B[i]};
 end
 endgenerate


  // Counter for sending 5 display commands
  // 5 LEDs * 24 bits/command = 120 bits to send 
  logic [6:0] send_count;
  logic send_en, send_clear;

  counter #(7) send (.en(send_en), .clear(send_clear), .q(send_count),
                              .d(7'd0), .clock(clock), .reset(reset));

  // States
  enum logic [1:0] {IDLE, SENDING} currstate, nextstate;

  // Next state logic 
  always_ff @(posedge clock, posedge reset)
    if (reset) currstate <= IDLE;  
    else currstate <= nextstate;   

  // FSM logic for states/output values
  always_comb begin
    send_en = 0; send_clear = 0;
    case (currstate)
      IDLE: begin
        // Upon reset, ready to load/send 
        ready_to_load = 1; ready_to_send = 1;
        nextstate = (send_it)? SENDING: IDLE; 
        // Load a specified color value into R, G, or B for one LED
        if (load_color) begin 
           case(color_index) 
               2'b00: R[pixel_index] = color_level; // Red
               2'b01: B[pixel_index] = color_level; // Blue
               2'b10: G[pixel_index] = color_level; // Green 
           endcase
        end
      end

      // Sending Serial bit stream 
      SENDING: begin 
          ready_to_load = 0; ready_to_send = 0; 
          send_en = 1; send_clear = 0; // Begin counting 
          nextstate = (send_count == 7'd120)? IDLE: SENDING; 
      end
      
    endcase
  end
endmodule:NeoPixelStrandController

