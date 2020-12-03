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
 logic [4:0][7:0] G, R, B;
 logic [4:0][23:0] LED_Command;
 logic [119:0] display_packet;

 // Assign LED Commands to create display packet
 genvar i; 
 generate
 for (i = 0; i < 5; i++) begin: LED_Commands
    assign LED_Command[i] = {G[i],R[i],B[i]}; // 6*5 = 30 hex = 120 bits 
 end
 endgenerate

 assign display_packet = LED_Command;


  // Counter for SEND 5 display commands
  // 5 LEDs * 24 bits/command = 120 bits to send 
  logic [6:0] send_count;
  logic send_en, send_clear;

  counter #(7) send (.en(send_en), .clear(send_clear), .q(send_count),
                              .d(7'd0), .clock(clock), .reset(reset));

  // Wait 50 microseconds between each display packet
  logic [11:0] wait50_count;
  logic wait50_en, wait50_clear;

  counter #(12) wait50 (.en(wait50_en), .clear(wait50_clear), .q(wait50_count),
                              .d(12'd0), .clock(clock), .reset(reset));
  // States
  enum logic [2:0] {RESET, LOAD, SEND, WAIT} currstate, nextstate;

  // Next state logic 
  always_ff @(posedge clock, posedge reset)
    if (reset) currstate <= RESET; 
    else currstate <= nextstate;   

  // FSM logic for states/output values
  always_comb begin
    wait50_en = 0; wait50_clear = 1;
    case (currstate)
      RESET: begin
        // Upon reset, ready to load/send 
        send_en = 0; send_clear = 1;
        ready_to_load = 1; ready_to_send = 1;
        G = 40'd0; R = 40'd0; B = 40'd0;
        // Load a specified color value into R, G, or B for one LED 
        if (load_color) begin 
           nextstate = LOAD;
           case(color_index) 
              2'b00: R[pixel_index] = color_level; // Red
              2'b01: B[pixel_index] = color_level; // Blue
              2'b10: G[pixel_index] = color_level; // Green 
           endcase
        // Send 
        end else if (send_it) nextstate = SEND;
        // Stay in IDLE
        else nextstate = RESET;
      end
      LOAD: begin
        send_en = 0; send_clear = 1;
        ready_to_load = 1; ready_to_send = 1;
        // Load a specified color value into R, G, or B for one LED 
        if (send_it) nextstate = SEND;
        else begin
          nextstate = LOAD;
          if (load_color) begin 
            case(color_index) 
                2'b00: R[pixel_index] = color_level; // Red
                2'b01: B[pixel_index] = color_level; // Blue
                2'b10: G[pixel_index] = color_level; // Green 
            endcase
          end
        end
      end
      // SEND Serial bit stream 
      SEND: begin 
        if (send_count == 7'd120) begin 
            nextstate = WAIT;
            send_en = 0; send_clear = 1;
            ready_to_load = 1; ready_to_send = 0;
        end else begin
            nextstate = SEND; 
            neo_data = display_packet[send_count];
            send_en = 1; send_clear = 0;
            ready_to_load = 0; ready_to_send = 0;
        end
      end
      // Must wait 50 microseconds before SEND another display packet 

      WAIT: begin 
          send_en = 0; send_clear = 1;
          // If waited 50 microseconds 
          if (wait50_count == 12'd2500) begin 
              nextstate = RESET;
              // Clear wait 
              wait50_en = 0; wait50_clear = 1;
              ready_to_load = 1; ready_to_send = 1;
          end else begin 
              nextstate = WAIT;
              // Count
              wait50_en = 1; wait50_clear = 0;
              ready_to_load = 1; ready_to_send = 0;
          end 
      end 
      
    endcase
    
  end
endmodule:NeoPixelStrandController

