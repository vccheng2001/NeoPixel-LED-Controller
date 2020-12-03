`default_nettype none

// Load color with randomly-generated fields
// Pixel index: num of LED (0-4)
// Color index: R = 2'b00, B = 2'b01, G = 2'b10;
// Color_level: 0 to 255
class genLoadColor;
  rand logic [2:0] pixel_index; 
  rand logic [1:0] color_index;
  rand logic [7:0] color_level; 

  // five possible pixels 
  constraint pi { pixel_index inside {3'd0, 3'd1, 3'd2, 3'd3, 3'd4}; }
  // red,  blue,  green
  constraint ci { color_index inside {2'b00, 2'b01, 2'b10}; }
  // brightness 0 to 255
  constraint cl { 8'h00 <= color_level <= 8'hff; }

  function display_load_color();
    $display("Rand PI= %d, Rand CI=%d, Rand CL=%h", pixel_index, color_index, color_level);
  endfunction
endclass 



// Testbench module
module NeoPixelStrandController_test;
   logic [7:0] color_level;
   logic [1:0] color_index;
   logic [2:0] pixel_index;
   logic clock, reset;
   logic load_color, send_it;
   logic neo_data, ready_to_load, ready_to_send;
   logic [119:0] display_packet;

  // Instantiate dut
  NeoPixelStrandController dut (.*);

  // Testbench clock
  initial begin
    clock = 0;
    forever #0.5 clock = ~clock;
  end

  // Simulates test
  initial begin
    // Initialize random class
    genLoadColor lc;

    // $monitor($time," Reset=%d, Curr=%s, Next=%s, LI=%d, SI=%d, RL=%b, RS=%b, G=%h, R=%h,B=%h, CI=%d,PI=%d,CL=%h,SCnt=%d, W50=%d",
    // reset, dut.currstate.name, dut.nextstate.name, load_color, send_it, ready_to_load, ready_to_send, dut.G, dut.R, dut.B, color_index, pixel_index, color_level, dut.send_count, dut.wait50_count);
    // $monitor($time," Reset=%d, Curr=%s, Next=%s, LI=%d, SI=%d, DP[sc]=%h, NeoData=%b, SCnt=%d, W50=%d",
    // reset, dut.currstate.name, dut.nextstate.name, load_color, send_it, dut.display_packet, dut.neo_data, dut.send_count, dut.wait50_count);
    $monitor($time," Reset=%d, Curr=%s, Next=%s, LI=%d, SI=%d, RL=%b, RS=%b,DispPacket=%h, NeoData=%b, SCnt=%d, CC=%d, W50=%d",
    reset, dut.currstate.name, dut.nextstate.name,load_color, send_it, ready_to_load, ready_to_send, dut.display_packet,dut.neo_data, dut.send_count, dut.cycle_count,dut.wait50_count);
 
    reset = 1; 
    load_color = 0; send_it = 0;
    color_index = 2'b00; pixel_index = 3'd0; color_level = 8'h00;
    @(posedge clock);          
    reset <= 0;
    @(posedge clock);

    // Load color 
    repeat(20) begin 
      load_color <= 1;
      // Randomize fields to load color 
      lc = new();
      lc.randomize();
      pixel_index <= lc.pixel_index;
      color_index <= lc.color_index;
      color_level <= lc.color_level;
      $display("Rand PI= %d, Rand CI=%d, Rand CL=%h", lc.pixel_index, lc.color_index, lc.color_level);
      @(posedge clock);
    end 

    // Send 
    load_color <= 0; send_it <= 1;
    @(posedge clock);
    // De-assert send 
    send_it <= 0; 
    @(posedge clock);

    $display("LED Command=%h", dut.LED_Command);
    #100000 $finish;            
  end
endmodule: NeoPixelStrandController_test
