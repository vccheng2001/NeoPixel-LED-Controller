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


  // Count cycles 
  logic [6:0] cycle_count;
  logic cycle_en, cycle_clear;

  counter #(7) cycle (.en(cycle_en), .clear(cycle_clear), .q(cycle_count),
                              .d(7'd0), .clock(clock), .reset(reset));

 // Number of cycles for sending 1-Bit
 localparam BIT_1_HIGH = 7'd35;
 localparam BIT_1_LOW  = 7'd30; 

 // Number of cycles for sending 0-Bit
 localparam BIT_0_HIGH  = 7'd18;
 localparam BIT_0_LOW  = 7'd40; 

 // Display packet length 
 localparam NUM_BITS = 7'd120;
 

  // Wait 50 microseconds between each display packet
  logic [11:0] wait50_count;
  logic wait50_en, wait50_clear;

  counter #(12) wait50 (.en(wait50_en), .clear(wait50_clear), .q(wait50_count),
                              .d(12'd0), .clock(clock), .reset(reset));



  // done_high when done waiting for cycles where asserted high 
  // done_low when done waiting for cycles where asserted low 
  logic done_high, done_low; 

  // States
  enum logic [2:0] {RESET, LOAD, SEND, SEND1, SEND0, WAIT} currstate, nextstate;

  // Next state logic 
  always_ff @(posedge clock, posedge reset)
    if (reset) currstate <= RESET; 
    else currstate <= nextstate;   

  // FSM logic for states/output values
  always_comb begin
    wait50_en = 0; wait50_clear = 1;
    cycle_en = 0; cycle_clear = 1;
    case (currstate)

      // Upon reset, ready to load/send. 
      // No bits have been sent yet (send_clear=1), RGB all set to 0
      RESET: begin

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
        end
        // Send  
        else if (send_it) nextstate = SEND;
        // Stay in IDLE
        else nextstate = RESET;
      end


      // Available to load 
      LOAD: begin
        send_en = 0; send_clear = 1;
        ready_to_load = 1; ready_to_send = 1;

        // Send 
        if (send_it) nextstate = SEND;
        // Load 
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

      // Send display packet of 120 bits 
      SEND: begin 
        // Every time send a new bit, reset done_high and done_low to 0
        done_high = 0; done_low = 0;

        // Iterated through all 120 pixels in display packet 
        if (send_count == NUM_BITS) begin 
            neo_data = 1'bx;  // Don't send any more neo_data
            nextstate = WAIT; // wait 50 microseconds 
            send_en = 0; send_clear = 1;  // clear 
            ready_to_load = 1; ready_to_send = 0; // can load while waiting 
            cycle_en = 0; cycle_clear = 1; // clear cycle counts 

        end else begin

            nextstate = SEND; 
            send_en = 1; send_clear = 0;
            // Deassert while sending 
            ready_to_load = 0; ready_to_send = 0; 
            
            // Send 1-bit
            if (display_packet[send_count] == 1) begin 
              nextstate = SEND1; 
              neo_data = 1; 
              cycle_en = 1; cycle_clear = 0;
            end 

            // Send 0-bit
            else if (display_packet[send_count] == 0) begin 
              nextstate = SEND0;
              neo_data = 1;
              cycle_en = 1; cycle_clear = 0; 
            end 
        end
      end


    /******************************************************************/
    /*       SEND A ONE-BIT: 35 cycles high, 30 cycles low            */
    /******************************************************************/
        
      // One-bit: 35 cycles high, 30 cycles low 
      SEND1: begin 
        send_en = 0; send_clear = 0; 

        // Sending high bits 
        if (!done_high & !done_low) begin
          nextstate = SEND1;  
          // Finished 35 high 
          if (cycle_count == BIT_1_HIGH) begin 
            neo_data = 0;  // send first low bit, keep counting 
            done_high = 1; cycle_en = 1; cycle_clear = 0; 
          // Not finished 35 high 
          end else begin 
            neo_data = 1; // send high bits, keep counting 
            done_high = 0; cycle_en = 1; cycle_clear = 0;  
          end 
        end 

        // Finished 35 high
        else if (done_high & !done_low) begin 
          // Finished 30 low
          if (cycle_count == (BIT_1_HIGH + BIT_1_LOW - 1)) begin  // 35 + 30 - 1
            nextstate = SEND;
            neo_data = 0; // send last low bit, stop counting 
            done_low = 1; cycle_en = 0; cycle_clear = 1;  
          // Not finished 30 low
          end else begin 
            nextstate = SEND1; 
            neo_data = 0; // send low bits, keep counting 
            done_low = 0; cycle_en = 1; cycle_clear = 0;
          end 
        end 

      end
    /******************************************************************/
    /*       SEND A ZERO-BIT: 18 cycles high, 40 cycles low            */
    /******************************************************************/
      
      // Zero-bit: 18 cycles high, 40 cycles low 
      SEND0: begin 
        send_en = 0; send_clear = 0;

        // Sending high bits 
        if (!done_high & !done_low) begin
          nextstate = SEND0;  
          // Finished 18 high 
          if (cycle_count == BIT_0_HIGH) begin 
            neo_data = 0;  // send first low bit, keep counting 
            done_high = 1; cycle_en = 1; cycle_clear = 0;
          // Not finished 18 high 
          end else begin 
            neo_data = 1; // send high bits, keep counting 
            done_high = 0; cycle_en = 1; cycle_clear = 0;  
          end 
        end 

        // Sending low bits 
        else if (done_high & !done_low) begin 
          // Finished 40 low
          if (cycle_count == (BIT_0_HIGH + BIT_0_LOW - 1)) begin  // 18 + 40 - 1
            nextstate = SEND;
            neo_data = 0; // send last low bit, stop counting 
            done_low = 1; cycle_en = 0; cycle_clear = 1;
          // Not finished 40 low
          end else begin 
            nextstate = SEND0; 
            neo_data = 0; // send low bits, keep counting  
            done_low = 0; cycle_en = 1; cycle_clear = 0;
          end 
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

