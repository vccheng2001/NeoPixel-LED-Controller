`default_nettype none


// Patterns:
// Regular Neon (SW[0], ~SW[2])
// Special Neon mode: Rainbow (SW[0], SW[2])
// Christmas:   (~SW[0])
// If SW[1], holds current color 
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
       // Neon mode 
       if (syncedSW[0]) begin 
           // Regular Neon mode 
           if (~syncedSW[2]) begin 
                color_hues = {8'h16, 8'h05, 8'h10, 8'h02};
                // SW[1] determines rate of blinking
                max_num_loads = (syncedSW[1]) ? 7'd63 : 7'd15;
           end else begin 
           // Special Neon mode: Rainbow mode!!!
                color_hues = {8'h20, 8'h10, 8'h05, 8'h00};
                // SW[1] determines rate of blinking
                max_num_loads = 7'd63;
           end
           color_array = NEON_COLOR_ARRAY;
           pixel_array = NEON_PIXEL_ARRAY;
       // Christmas 
       end else begin 
           // Red/Green 
           color_hues = {8'h20, 8'h10, 8'h05, 8'h00};
           max_num_loads = (syncedSW[1]) ? 7'd63 : 7'd31; 
           // SW[1] determines rate of blinking
           color_array = XMAS_COLOR_ARRAY;
           pixel_array = XMAS_PIXEL_ARRAY;
       end
   end

 // Neon color array: encodes color index
 assign NEON_COLOR_ARRAY = {    C0, C1, C0, C1, C1, C3, C2, C0, C3, C2, C3, C0, C1, C3, C1, 
                                C1, C2, C3, C2, C0, C2, C2, C0, C3, C1, C0, C0, C0, C3, C2, 
                                C0, C3, C1, C2, C3, C1, C1, C2, C2, C0, C2, C1, C3, C2, C0,
                                C0, C1, C0, C1, C1, C0, C0, C1, C3, C3, C3, C2, C2, C0, C1,
                                C0, C3, C1, C2, C2, C0, C1, C1, C3, C2, C0, C3, C0, C2, C3,
                                C1, C0, C3, C0, C1, C2, C2, C0, C3, C1, C0, C0, C0, C3, C2,
                                C0, C3, C1, C2, C3, C1, C1, C2, C2, C0, C1, C2, C3};

 // Neon pixel array: Encodes which pixels to load
 assign NEON_PIXEL_ARRAY = {3'd1,3'd1,3'd2,3'd0,3'd0,3'd0,3'd1,3'd1,3'd1,3'd2,3'd2,3'd2,3'd3,3'd3,3'd3,3'd4,3'd4,3'd4,3'd0,3'd1,3'd2,3'd1,3'd0,
                            3'd0,3'd0,3'd0,3'd1,3'd1,3'd1,3'd2,3'd2,3'd2,3'd3,3'd3,3'd3,3'd4,3'd4,3'd4,3'd0,3'd1,3'd2,3'd1,3'd0,
                            3'd0,3'd0,3'd0,3'd1,3'd1,3'd1,3'd2,3'd2,3'd2,3'd3,3'd3,3'd3,3'd4,3'd4,3'd4,3'd0,3'd1,3'd2,3'd1,3'd0};

  // Xmas color array: Encodes color index
 assign XMAS_PIXEL_ARRAY = { 3'd0,3'd0,3'd0,3'd1,3'd1,3'd1,3'd2,3'd2,3'd2,3'd3,3'd3,3'd3,3'd4,3'd4,3'd4, 
                            3'd4,3'd4,3'd4,3'd3,3'd3,3'd3,3'd2,3'd2,3'd2,3'd1,3'd1,3'd1,3'd0,3'd0,3'd0,
                            3'd3,3'd3,3'd3,3'd2,3'd2,3'd2,3'd1,3'd1,3'd1,3'd0,3'd0,3'd0,3'd4,3'd4,3'd4,
                            3'd2,3'd2,3'd2,3'd1,3'd1,3'd1,3'd0,3'd0,3'd0,3'd4,3'd4,3'd4,3'd3,3'd3,3'd3,
                            3'd1,3'd1,3'd1};
 // Xmas pixel array: Encodes which pixels to load
 assign XMAS_COLOR_ARRAY =  {C0,C1,C2,C3,C3,C2,C1,C0,C0,C1,C2,C3,C3,C2,C1,C0,C0,C1,C2,C3,
                            C0,C2,C1,C3,C3,C1,C2,C0,C0,C2,C1,C3,C3,C1,C2,C0,C0,C2,C1,C3,
                            C0,C0,C1,C1,C2,C2,C3,C3,C3,C3,C2,C2,C1,C1,C0,C0,C0,C0,C1,C1,
                            C0,C1,C2,C3,C3,C2,C1,C0,C0,C1,C2,C3,C3,C2,C1,C0,C0,C1,C2,C3,
                            C0,C2,C1,C3,C3,C1,C2,C0,C0,C2,C1,C3,C3,C1,C2,C0,C0,C2,C1,C3,
                            C0,C0,C1,C1,C2,C2,C3,C3,C3,C3,C2,C2,C1,C1,C0,C0,C0,C0,C1,C1,
                            C2,C2,C3};
endmodule