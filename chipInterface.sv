`default_nettype none

module chipInterface
  (input  logic CLOCK_50,
   output logic [31:0] GPIO_0); 
 
   logic reset;

   logic [2:0] pixel_index;          
   logic [1:0] color_index;
   logic [7:0] color_level;

   logic load_color, send_it;        
   logic neo_data, ready_to_load, ready_to_send;

   assign GPIO_0[1] = neo_data;
   
   NeoPixelStrandController (.clock(CLOCK_50), .*);
   Task2 (.clock(CLOCK_50), .*);
   
endmodule: chipInterface 