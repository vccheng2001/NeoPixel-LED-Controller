`default_nettype none

// NeoPixel LED Controller 
module NeoPixelStrandController
 #(parameter NUM_PIXELS = 5)
 (input logic [7:0] color_level,
 input logic [1:0] color_index,
 input logic [2:0] pixel_index,
 input logic clock, reset, // clock must be 50MHz
 input logic load_color, send_it,
 output logic begin_send, done_send, done_wait,
 output logic neo_data, ready_to_load, ready_to_send);

/******************************************************************/
/*                          Define RGB Color Logic                */
/*******************************************************************/
 logic [4:0][7:0] G, R, B;

 // Register variables for RGB  
 logic [4:0] G_en, R_en, B_en;
 logic [4:0] G_clear, R_clear, B_clear;
 logic [4:0][7:0] G_in, R_in, B_in;

 // Registers for storing R/G/B
 genvar j; 
 generate
 for (j = 0; j < 5; j++) begin: rgb
    register #(8) green (.q(G[j]), .d(G_in[j]), .en(G_en[j]),
           .clear(G_clear[j]), .clock(clock), .reset(reset));
    register #(8) red (.q(R[j]), .d(R_in[j]), .en(R_en[j]), 
          .clear(R_clear[j]), .clock(clock), .reset(reset));
    register #(8) blue (.q(B[j]), .d(B_in[j]), .en(B_en[j]),
           .clear(B_clear[j]), .clock(clock), .reset(reset));
 end
 endgenerate

/******************************************************************/
/*                        Display packet                          */
/*******************************************************************/
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


/******************************************************************/
/*   Send display packet: 5 LEDs * 40 bits/LED = 120 bits         */
/*******************************************************************/
  logic [6:0] send_count;
  logic send_en, send_clear;
  counter #(7) send (.en(send_en), .clear(send_clear), .q(send_count),
                              .d(7'd0), .clock(clock), .reset(reset));


/******************************************************************/
/*            Count number of cycles when sending 1s/0s           */
/*******************************************************************/
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

/******************************************************************/
/*                              Wait 50 us Counters                 */
/*******************************************************************/ 
  // Wait 50 microseconds between each display packet
  logic [11:0] wait50_count;
  logic wait50_en, wait50_clear;

  counter #(12) wait50 (.en(wait50_en), .clear(wait50_clear), .q(wait50_count),
                              .d(12'd0), .clock(clock), .reset(reset));

/******************************************************************/
/*                  Producer FSM: Neo Controller                  */
/*******************************************************************/

  // Signal variables

  logic send_one, send_zero;  // Sending one bit/zero bit

  // States
  enum logic [3:0] {RESET, IDLE_OR_LOAD, SEND, SEND1_1, SEND1_0, SEND0_1,
                                     SEND0_0, WAIT} currstate, nextstate;

  // Next state logic 
  always_ff @(posedge clock, posedge reset)
    if (reset) currstate <= RESET;
    else currstate <= nextstate;   

  // FSM logic for states/output values
  always_comb begin
    // Default neo_data when not sending
    neo_data = 1'b0;  

    // Signal variables to hardware thread Task2
    begin_send = 0; done_send = 0; send_one = 0; send_zero = 0; done_wait = 0;

    wait50_en = 0; wait50_clear = 1;      // reset counters to 0
    cycle_en = 0; cycle_clear = 1;   
    send_en = 0; send_clear = 1;   
  
    ready_to_load = 0; ready_to_send = 0; // not ready to load/send 

    // maintain rgb values if not clear/reset or en 
    R_en = 5'b00000; R_clear = 5'b00000; R_in = 40'd0;
    B_en = 5'b00000; B_clear = 5'b00000; B_in = 40'd0;
    G_en = 5'b00000; G_clear = 5'b00000; G_in = 40'd0;

    case (currstate)
      // Reset: Clear RGB
      RESET: begin 
          R_en = 5'b00000; R_clear = 5'b11111; R_in = 40'd0;
          B_en = 5'b00000; B_clear = 5'b11111; B_in = 40'd0;
          G_en = 5'b00000; G_clear = 5'b11111; G_in = 40'd0;
          nextstate = IDLE_OR_LOAD;
          ready_to_load = 1; ready_to_send = 1;
      end 

      // Loading 
      IDLE_OR_LOAD: begin
        // Can load and send 
        ready_to_load = 1; ready_to_send = 1;

        // Load Color 
        if (load_color) begin      
           nextstate = IDLE_OR_LOAD;
           case (color_index)
            2'b00: begin // red
              R_en[pixel_index] = 1; R_clear[pixel_index] = 0;
              R_in[pixel_index] = color_level;
            end
            2'b01: begin // blue
              B_en[pixel_index] = 1; B_clear[pixel_index] = 0;
              B_in[pixel_index] = color_level;
            end
            2'b10: begin // green
              G_en[pixel_index] = 1; G_clear[pixel_index] = 0;
              G_in[pixel_index] = color_level;
            end 
          default: begin end 
          endcase
        // Start Sending 
        end else if (send_it) begin 
           begin_send = 1;
           nextstate = SEND;
        // Stay Idle 
        end else nextstate = IDLE_OR_LOAD; 
      end

      // Send display packet of 120 bits 
      SEND: begin 
        // Sent all 120 pixels in display packet 
        if (send_count == NUM_BITS) begin 
            done_send = 1;
            nextstate = WAIT; // wait 50 microseconds 
            ready_to_load = 1; ready_to_send = 0;
        
        // Still sending 
        end else begin 
            send_en = 0; send_clear = 0; 
            ready_to_load = 0; ready_to_send = 0; 
            nextstate = SEND;

            // Send 1-bit
            if (display_packet[send_count] == 1) begin 
              send_one = 1;
              nextstate = SEND1_1; 
              neo_data = 1; 
              cycle_en = 1; cycle_clear = 0;
            end 

            // Send 0-bit
            else if (display_packet[send_count] == 0) begin 
              send_zero = 1;
              nextstate = SEND0_1;
              neo_data = 1;
              cycle_en = 1; cycle_clear = 0; 
            end 

        end
      end


    /******************************************************************/
    /*       SEND A ONE-BIT: 35 cycles high, 30 cycles low            */
    /******************************************************************/
        
    // 35 highs 
    SEND1_1: begin 
        ready_to_load = 0; ready_to_send = 0;
        send_en = 0; send_clear = 0; 
        cycle_en = 1; cycle_clear = 0;
    
        // If done sending 30 high 
        if (cycle_count == BIT_1_HIGH) begin 
          neo_data = 0; 
          nextstate = SEND1_0;
        // Else not done sending 30 high 
        end else begin 
          neo_data = 1; 
          nextstate = SEND1_1; 
        end 
     end 
     
     // 30 lows 
     SEND1_0: begin 
        // If done sending 30 lows 
        if (cycle_count == BIT_1_HIGH + BIT_1_LOW - 1) begin 
          neo_data = 0; // send last 0 
          nextstate = SEND;
          cycle_en = 0; cycle_clear = 1; 
          send_en = 1; send_clear = 0; 
        // Else keep sending lows 
        end else begin 
          neo_data = 0;
          nextstate = SEND1_0;
          cycle_en = 1; cycle_clear = 0;
           send_en = 0; send_clear = 0;  
        end 
     end 

    /******************************************************************/
    /*       SEND A ZERO-BIT: 18 cycles high, 40 cycles low            */
    /******************************************************************/
    
    // Send one-bit: assert high 18 cycles, low 40 
    SEND0_1: begin 
        ready_to_load = 0; ready_to_send = 0;
        send_en = 0; send_clear = 0;
        cycle_en = 1; cycle_clear = 0;
    
        // Done 18 highs 
        if (cycle_count == BIT_0_HIGH) begin 
          neo_data = 0; // send first 0
          nextstate = SEND0_0;
        // Else keep sending 1s
        end else begin 
          neo_data = 1; // send ones 
          nextstate = SEND0_1; 
        end 
     end 

     // Send 40 lows 
     SEND0_0: begin 
        // Done 40 lows 
        if (cycle_count == BIT_0_HIGH + BIT_0_LOW - 1) begin 
          nextstate = SEND;
          neo_data = 0; // send last 0 
          cycle_en = 0; cycle_clear = 1; 
          send_en = 1; send_clear = 0; 
        // Else keep sending 0s 
        end else begin
          nextstate = SEND0_0; 
          neo_data = 0;
          cycle_en = 1; cycle_clear = 0; 
          send_en = 0; send_clear = 0; 
        end 
     end 

    /******************************************************************/
    /*       Wait 50 microseconds between display packets             */
    /******************************************************************/

      // Can load while waiting 
      WAIT: begin 
        if (load_color) begin 
          case (color_index)
            2'b00: begin // red
              R_en[pixel_index] = 1; R_clear[pixel_index] = 0;
              R_in[pixel_index] = color_level;
            end
            2'b01: begin // blue
              B_en[pixel_index] = 1; B_clear[pixel_index] = 0;
              B_in[pixel_index] = color_level;
            end
            2'b10: begin // green
              G_en[pixel_index] = 1; G_clear[pixel_index] = 0;
              G_in[pixel_index] = color_level;
            end 
          default: begin end 
          endcase
        end 
        ready_to_load = 1;

        // If waited 50 microseconds, return to IDLE_OR_LOAD
        if (wait50_count == 12'd2500) begin 
          done_wait = 1;
            nextstate = IDLE_OR_LOAD;
            wait50_en = 0; wait50_clear = 1;
            ready_to_send = 1;
        // Else keep waiting 
        end else begin 
            nextstate = WAIT;
            wait50_en = 1; wait50_clear = 0;
            ready_to_send = 0;
        end 
      end 
      
    endcase
    
  end
endmodule:NeoPixelStrandController

