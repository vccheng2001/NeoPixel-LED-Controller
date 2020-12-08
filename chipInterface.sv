`default_nettype none

module chipInterface
  (input  logic CLOCK_50,
   input  logic [9:0] SW,
   input logic [3:0] KEY,
   output logic [31:0] GPIO_0); 
 
   logic [2:0] pixel_index;          
   logic [1:0] color_index;
   logic [7:0] color_level;

   logic load_color, send_it;        
   logic neo_data, ready_to_load, ready_to_send;
   logic begin_send, done_send, done_wait;

   logic clock, reset;

  logic syncedKEY0;
  logic [4:0] syncedSW;

  syncInputs si (.inKEY0(KEY[0]), .inSW(SW), .*);

   assign clock = CLOCK_50;    // 50 MHz clock
   assign reset = ~syncedKEY0; // reset when KEY2 pressed 
   assign GPIO_0[1] = neo_data;

  //  assign color_index = {syncedSW1, syncedSW0};
   
   NeoPixelStrandController np (.*);
   Task2 t2 (.*);
   
endmodule: chipInterface 