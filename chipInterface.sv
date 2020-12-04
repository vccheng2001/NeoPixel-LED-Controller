`default_nettype none

module ChipInterface
  (input  logic CLOCK_50,
   output logic B13); 
 
   logic reset;

   logic [2:0] pixel_index;          
   logic [1:0] color_index;
   logic [7:0] color_level;

   logic load_color, send_it;        
   logic neo_data, ready_to_load, ready_to_send;

   assign B13 = neo_data; 

   NeoPixelStrandController led (.clock(CLOCK_50), .*);
   
endmodule: ChipInterface 