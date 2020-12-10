`default_nettype none

// Tells Task2 which colors/patterns to use, based on switches and keys
// Different LED display modes: Neon, Rainbow, Christmas, Regular 
module Colors
  (input  logic clock, reset, 
   input logic [4:0] syncedSW,
   output logic [62:0][7:0] color_array,
   output logic [62:0][2:0] pixel_array,
   output logic [6:0] max_num_loads); 


    // Define different RGB color intensities 
    logic [7:0] C3, C2, C1, C0;
    logic [3:0][7:0] color_hues;
    assign {C3, C2, C1, C0} = color_hues;

    // Rainbow / XMAS Color arrays
    logic [62:0][7:0] NEON_COLOR_ARRAY, XMAS_COLOR_ARRAY;
    logic [62:0][2:0] NEON_PIXEL_ARRAY, XMAS_PIXEL_ARRAY;

    // Change pattern parameters based on Switch 
   always_comb begin 
       // MODE 1: Neon Mode (Multiple LEDs update simultaneously
       if (syncedSW[1]) begin 
           color_array = NEON_COLOR_ARRAY;
           pixel_array = NEON_PIXEL_ARRAY;
           // Regular Neon Mode: Multiple LED updates simultaneously
           if (~syncedSW[2]) begin 
                color_hues = {8'h16, 8'h05, 8'h10, 8'h02};
                // SW[0] determines rate of blinking
                max_num_loads = (syncedSW[0]) ? 7'd63 : 7'd15;
           // RAINBOW MODE: Special mode if SW1 && SW2
           end else begin 
               color_hues = {8'h18, 8'h10, 8'h05, 8'h00};
                // SW[0] determines rate of blinking
                max_num_loads = (syncedSW[0]) ? 7'd63 : 7'd31;
           end 
       end 
       // MODE 2: Christmas blinking lights
       else if (syncedSW[2] && ~syncedSW[1]) begin 
           // Red/Green 
           color_hues = {8'h20, 8'h10, 8'h05, 8'h00};
           max_num_loads = (syncedSW[0]) ? 7'd63 : 7'd31; 
           // SW[0] determines rate of blinking
           color_array = XMAS_COLOR_ARRAY;
           pixel_array = XMAS_PIXEL_ARRAY;
       end
       // Mode 3: One-LED-at-a-time updates
       else begin 
           color_hues = {8'h02,8'h02,8'h02,8'h15};
           max_num_loads = (syncedSW[0]) ? 7'd63 : 7'd2; 
           // SW[0] determines rate of blinking
           color_array = NEON_COLOR_ARRAY;
           pixel_array = XMAS_PIXEL_ARRAY;
       end 
   end

 // Neon color array: encodes color index
 assign NEON_COLOR_ARRAY =
  { C0, C1, C0, C1, C1, C3, C2, C0, C3, C2, C3, C0, C1, C3, C1, 
    C1, C2, C3, C2, C0, C2, C2, C0, C3, C1, C0, C0, C0, C3, C2, 
    C0, C3, C1, C2, C3, C1, C1, C2, C2, C0, C2, C1, C3, C2, C0,
    C0, C1, C0, C1, C1, C0, C0, C1, C3, C3, C3, C2, C2, C0, C1,
    C0, C3, C1, C2, C2, C0, C1, C1, C3, C2, C0, C3, C0, C2, C3,
    C1, C0, C3, C0, C1, C2, C2, C0, C3, C1, C0, C0, C0, C3, C2,
    C0, C3, C1, C2, C3, C1, C1, C2, C2, C0, C1, C2, C3};

 // Neon pixel array: Encodes which pixels to load
 assign NEON_PIXEL_ARRAY = 
    {3'd1,3'd1,3'd2,3'd0,3'd0,3'd0,3'd1,3'd1,3'd1,3'd2,3'd2,3'd2,3'd3,3'd3,3'd3,
    3'd4,3'd4,3'd4,3'd0,3'd1,3'd2,3'd1,3'd0,3'd0,3'd0,3'd0,3'd1,3'd1,3'd1,3'd2,
    3'd2,3'd2,3'd3,3'd3,3'd3,3'd4,3'd4,3'd4,3'd0,3'd1,3'd2,3'd1,3'd0,3'd0,3'd0,
    3'd0,3'd1,3'd1,3'd1,3'd2,3'd2,3'd2,3'd3,3'd3,3'd3,3'd4,3'd4,3'd4,3'd0,3'd1,
    3'd2,3'd1,3'd0};

  // Xmas color array: Encodes color index
 assign XMAS_PIXEL_ARRAY =
  { 3'd0,3'd0,3'd0,3'd1,3'd1,3'd1,3'd2,3'd2,3'd2,3'd3,3'd3,3'd3,3'd4,3'd4,3'd4, 
    3'd4,3'd4,3'd4,3'd3,3'd3,3'd3,3'd2,3'd2,3'd2,3'd1,3'd1,3'd1,3'd0,3'd0,3'd0,
    3'd3,3'd3,3'd3,3'd2,3'd2,3'd2,3'd1,3'd1,3'd1,3'd0,3'd0,3'd0,3'd4,3'd4,3'd4,
    3'd2,3'd2,3'd2,3'd1,3'd1,3'd1,3'd0,3'd0,3'd0,3'd4,3'd4,3'd4,3'd3,3'd3,3'd3,
    3'd1,3'd1,3'd1};

 // Xmas pixel array: Encodes which pixels to load
 assign XMAS_COLOR_ARRAY =  
    {C0,C1,C2,C3,C3,C2,C1,C0,C0,C1,C2,C3,C3,C2,C1,C0,C0,C1,C2,C3,
    C0,C2,C1,C3,C3,C1,C2,C0,C0,C2,C1,C3,C3,C1,C2,C0,C0,C2,C1,C3,
    C0,C0,C1,C1,C2,C2,C3,C3,C3,C3,C2,C2,C1,C1,C0,C0,C0,C0,C1,C1,
    C0,C1,C2,C3,C3,C2,C1,C0,C0,C1,C2,C3,C3,C2,C1,C0,C0,C1,C2,C3,
    C0,C2,C1,C3,C3,C1,C2,C0,C0,C2,C1,C3,C3,C1,C2,C0,C0,C2,C1,C3,
    C0,C0,C1,C1,C2,C2,C3,C3,C3,C3,C2,C2,C1,C1,C0,C0,C0,C0,C1,C1,
    C2,C2,C3};
endmodule