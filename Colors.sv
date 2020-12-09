`default_nettype none



module Colors
  (input  logic clock, reset, 
   input logic [4:0] syncedSW,
   output logic [62:0][7:0] color_array,
   output logic [62:0][2:0] pixel_array,
   output logic [6:0] max_num_loads); 


    logic [3:0][7:0] color_hues;

    logic [7:0] C3, C2, C1, C0;
 
    assign {C3, C2, C1, C0} = color_hues;

    logic [62:0][7:0] RAINBOW_COLOR_ARRAY, NEON_COLOR_ARRAY;
    logic [62:0][2:0] RAINBOW_PIXEL_ARRAY, NEON_PIXEL_ARRAY;

   always_comb begin 
       if (syncedSW[0]) begin 
           color_hues = {8'h20, 8'h10, 8'h05, 8'h00};
           max_num_loads = (syncedSW[1]) ? 7'd63 : 7'd15;
           color_array = RAINBOW_COLOR_ARRAY;
           pixel_array = RAINBOW_PIXEL_ARRAY;
       end else begin 
           color_hues = {8'h15, 8'h10, 8'h08, 8'h02};
           max_num_loads = 7'd31; 
           color_array = NEON_COLOR_ARRAY;
           pixel_array = NEON_PIXEL_ARRAY;
       end
   end

 assign RAINBOW_COLOR_ARRAY = {C0, C1, C0, C1, C1, C3, C2, C0, C3, C2, C3, C0, C1, C3, C1, C1, C2, C3, C2, C0,
                            C2, C2, C0, C3, C1, C0, C0, C0, C3, C2, C0, C3, C1, C2, C3, C1, C1, C2, C2, C0,
                            C2, C1, C3, C2, C0, C0, C1, C0, C1, C1, C0, C0, C1, C3, C3, C3, C2, C2, C0, C1,
                            C0, C3, C1, C2, C2, C0, C1, C1, C3, C2, C0, C3, C0, C2, C3, C1, C0, C3, C0, C1,
                            C2, C2, C0, C3, C1, C0, C0, C0, C3, C2, C0, C3, C1, C2, C3, C1, C1, C2, C2, C0,
                            C1, C2, C3};

 assign RAINBOW_PIXEL_ARRAY = {3'd1,3'd1,3'd2,3'd0,3'd0,3'd0,3'd1,3'd1,3'd1,3'd2,3'd2,3'd2,3'd3,3'd3,3'd3,3'd4,3'd4,3'd4,3'd0,3'd1,3'd2,3'd1,3'd0,
                            3'd0,3'd0,3'd0,3'd1,3'd1,3'd1,3'd2,3'd2,3'd2,3'd3,3'd3,3'd3,3'd4,3'd4,3'd4,3'd0,3'd1,3'd2,3'd1,3'd0,
                            3'd0,3'd0,3'd0,3'd1,3'd1,3'd1,3'd2,3'd2,3'd2,3'd3,3'd3,3'd3,3'd4,3'd4,3'd4,3'd0,3'd1,3'd2,3'd1,3'd0};

 assign NEON_PIXEL_ARRAY = { 3'd0,3'd0,3'd0,3'd1,3'd1,3'd1,3'd2,3'd2,3'd2,3'd3,3'd3,3'd3,3'd4,3'd4,3'd4, 
                            3'd4,3'd4,3'd4,3'd3,3'd3,3'd3,3'd2,3'd2,3'd2,3'd1,3'd1,3'd1,3'd0,3'd0,3'd0,
                            3'd3,3'd3,3'd3,3'd2,3'd2,3'd2,3'd1,3'd1,3'd1,3'd0,3'd0,3'd0,3'd4,3'd4,3'd4,
                            3'd2,3'd2,3'd2,3'd1,3'd1,3'd1,3'd0,3'd0,3'd0,3'd4,3'd4,3'd4,3'd3,3'd3,3'd3,
                            3'd1,3'd1,3'd1};

 assign NEON_COLOR_ARRAY =  {C0,C1,C2,C3,C3,C2,C1,C0,C0,C1,C2,C3,C3,C2,C1,C0,C0,C1,C2,C3,
                            C0,C2,C1,C3,C3,C1,C2,C0,C0,C2,C1,C3,C3,C1,C2,C0,C0,C2,C1,C3,
                            C0,C0,C1,C1,C2,C2,C3,C3,C3,C3,C2,C2,C1,C1,C0,C0,C0,C0,C1,C1,
                            C0,C1,C2,C3,C3,C2,C1,C0,C0,C1,C2,C3,C3,C2,C1,C0,C0,C1,C2,C3,
                            C0,C2,C1,C3,C3,C1,C2,C0,C0,C2,C1,C3,C3,C1,C2,C0,C0,C2,C1,C3,
                            C0,C0,C1,C1,C2,C2,C3,C3,C3,C3,C2,C2,C1,C1,C0,C0,C0,C0,C1,C1,
                            C2,C2,C3};
endmodule