`default_nettype none

// Testbench module
module NeoPixelStrandController_test;
   logic [7:0] color_level;
   logic [1:0] color_index;
   logic [2:0] pixel_index;
   logic clock, reset;
   logic load_color, send_it;
   logic neo_data, ready_to_load, ready_to_send;

  // Instantiate dut
  NeoPixelStrandController dut (.*);

  // Testbench clock
  initial begin
    clock = 0;
    forever #0.5 clock = ~clock;
  end

  // Simulates test
  initial begin
    $monitor($time," Reset=%d, Curr=%s, Next=%s, LI=%d, SI=%d, RL=%b, RS=%b, G=%h, R=%h,B=%h, CI=%d,PI=%d,CL=%h,SCnt=%d, W50=%d",
    reset, dut.currstate.name, dut.nextstate.name, load_color, send_it, ready_to_load, ready_to_send, dut.G, dut.R, dut.B, color_index, pixel_index, color_level, dut.send_count, dut.wait50_count);
    reset = 1; 
    load_color = 0; send_it = 0;
    color_index = 2'b00; pixel_index = 3'd0; color_level = 8'h00;
    @(posedge clock);          
    reset <= 0;
    @(posedge clock);     
    pixel_index <= 3'h4; color_level <= 8'hFF; color_index <= 2'b00; // Red, 5th lED, 255
    load_color <= 1;
    @(posedge clock);    
    pixel_index <= 3'h1; color_level <= 8'hA0; color_index <= 2'b01; // Blue, 2nd lED, A0
    @(posedge clock);
    pixel_index <= 3'h2; color_level <= 8'hB3; color_index <= 2'b10; // Green,2nd lED, A0
    @(posedge clock);
    pixel_index <= 3'h1; color_level <= 8'hd4; color_index <= 2'b11; // INVALID
    @(posedge clock);
    load_color <= 0; send_it <= 1;
    @(posedge clock);
    send_it <= 0; 
    @(posedge clock);

    $display("LED Command=%h", dut.LED_Command);
    #1000000 $finish;            
  end
endmodule: NeoPixelStrandController_test
