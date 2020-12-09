`default_nettype none

module chipInterface
  (input  logic CLOCK_50,
   input  logic [9:0] SW,       // Switches control color patterns
   input logic [3:0] KEY,       // KEY0 used for reset 
   output logic [31:0] GPIO_0); // Neo_data output to FPGA Pin B16

    // Global clock, reset 
    logic clock, reset; 

   // Color parameters 
    logic [2:0] pixel_index;          
    logic [1:0] color_index;
    logic [7:0] color_level;

    // Signal variables between NeoController/Hardware Thread
    logic load_color, send_it;        
    logic neo_data, ready_to_load, ready_to_send;
    logic begin_send, done_send, done_wait;

    // Synchronize key/switch inputs 
    logic syncedKEY0;
    logic [4:0] syncedSW;
    syncInputs si (.inKEY0(KEY[0]), .inSW(SW), .*);

    // Switches determine color pattern, which is input into Hardware Thread 
    logic [62:0][7:0] color_array;
    logic [62:0][2:0] pixel_array;
    logic [6:0] max_num_loads;
    Colors c (.*);

    assign clock = CLOCK_50;    // 50 MHz clock
    assign reset = ~syncedKEY0; // reset when KEY0 pressed 
    assign GPIO_0[1] = neo_data; // LED output
    
    NeoPixelStrandController np (.*); // Neopixel controller 
    Task2 t2 (.*); // Hardware thread, tells NeoPixel controller to load/send

endmodule: chipInterface 