`default_nettype none

module chipInterface
  (input  logic CLOCK_50,
   input logic [3:0] KEY,
   output logic [31:0] GPIO_0); 
 
   logic [2:0] pixel_index;          
   logic [1:0] color_index;
   logic [7:0] color_level;

   logic load_color, send_it;        
   logic neo_data, ready_to_load, ready_to_send;

   logic clock, reset;

   logic syncedKEY2_temp, syncedKEY2;   // synchronized output for KEY2
  
   // Flip flop synchronizers for KEY[2] to reduce metastability
   register #(1) sync2_0 (.q(syncedKEY2_temp), .d(KEY[2]), .en(1'b1), .clock(CLOCK_50), .clear(1'b0), .reset(1'b0));
   register #(1) sync2_1 (.q(syncedKEY2), .d(syncedKEY2_temp), .en(1'b1), .clock(CLOCK_50), .clear(1'b0), .reset(1'b0));

   assign clock = CLOCK_50;    // 50 MHz clock
   assign reset = ~syncedKEY2; // reset when KEY2 pressed 
   assign GPIO_0[1] = neo_data;
   
   NeoPixelStrandController np (.*);
   Task2 t2 (.*);
   
endmodule: chipInterface 