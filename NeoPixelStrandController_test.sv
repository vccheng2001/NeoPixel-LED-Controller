`default_nettype none

/******************************************************************/
//    Generate randomized constrained fields for load_color
/*******************************************************************/
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


  function display_randomized_colors();
    $display("Randomized vals: Pixel Index= %d, Color Index=%d, Color Level=%h", pixel_index, color_index, color_level);
  endfunction
endclass 

/******************************************************************/
//    Generate randomized number of times to load_color 
/*******************************************************************/
// Num_loads: calls load_color 0 - 63 times 
class genNumLoads;
  rand logic [5:0] num_loads;
   function display_num_loads();
    $display("Load_color %d times", num_loads);
  endfunction
endclass



/******************************************************************/
//                  NeoPixel Controller: Testbench                 */ 
/*******************************************************************/
module NeoPixelStrandController_test;
   logic clock, reset;

   logic [2:0] pixel_index;           // Fields for load_color 
   logic [1:0] color_index;
   logic [7:0] color_level;

   logic load_color, send_it;         // Signals 
   logic neo_data, ready_to_load, ready_to_send;
   logic begin_send, done_send, done_wait;

  // Instantiate dut
  NeoPixelStrandController dut (.*);

  // Testbench clock
  initial begin
    clock = 0;
    forever #0.5 clock = ~clock;
  end

  // randomized class handles
  genLoadColor lc;
  genNumLoads nl;

/*******************************************************************/
/*                      Task: Reset inputs to dut                  */
/*******************************************************************/ 
  task do_reset();
    $display("\n*****RESETTING ALL VALUES AND INPUTS TO DUT****\n" );
    reset = 1; 
    load_color = 0; send_it = 0;
    color_index = 2'b00; pixel_index = 3'd0; color_level = 8'h00;
    @(posedge clock);          
    reset <= 0;
    @(posedge clock); 
  endtask

/*****************************************************************(*/
/*                  Task: Randomized loads, then send packet       */
/*******************************************************************/ 

  task loadSendTest();
   begin
    $display("\n******** Begin a round of load/sends:***********");
 
    nl = new();                              // Randomize number of loads
    nl.randomize();
    nl.display_num_loads();

    repeat(nl.num_loads) begin               // Calls load_color <num_loads> times  
      load_color <= 1;
      lc = new();                            // Randomize fields to load color 
      lc.randomize();
      pixel_index <= lc.pixel_index;         // Set randomized pixel index, 
      color_index <= lc.color_index;         // color index, color levels 
      color_level <= lc.color_level;
      lc.display_randomized_colors();
      $display("Display packet: %h", dut.display_packet); 
      @(posedge clock);
    end 

    $display("DISPLAY PACKET TO SEND: %h", dut.display_packet);

    load_color <= 0; send_it <= 1;            // Send 
    @(posedge clock);
    send_it <= 0;                             // De-assert send  
    @(posedge clock);
    wait(dut.send_count == 120);              // Wait for all 120 bits to send 
    wait(dut.wait50_count == 2500);           // Wait between display packets 
   end
  endtask


/******************************************************************/
/*                    Main TB:  Runs all tests                    */
/******************************************************************/
  initial begin
    $display("\n******** TESTING RANDOMIZED LOADS/SENDS ***********");
    do_reset();               // Reset inputs to dut
    repeat (20) begin         // Keep loading randomized colors, then sending
      loadSendTest();         
    end
    do_reset();
    repeat (10) begin         // Keep loading randomized colors, then sending
      loadSendTest();         
    end
    #1 $finish;
  end

/******************************************************************/
/*                     Concurrent Assertions                      */
/******************************************************************/

// Load color assertions
assert property (load_R_prop) else $error("Incorrectly loaded Red");
assert property (load_G_prop) else $error ("Incorrectly loaded Green");
assert property (load_B_prop) else $error ("Incorrectly loaded Blue");

// Reset assertions
assert property (reset_loadsend_prop) else $error ("Upon reset, should be ready to load/send");
assert property (reset_blank_packet_prop) else $error ("Upon reset, display packet should be blank");

// Sending assertions
assert property (send_blank_pixels_prop) else $error ("If immediately send, display packet should be zeros (blank pixels");
assert property (send_all_120) else $error ("Did not send complete display packet");

// Timing assertions
assert property (wait_between_packets_prop) else $error ("Must wait at least 2500 clocks before sending another packet");
assert property (send_one_prop) else $error ("Send zero bit timing off:  Neo_data should be high 18 cycles, then low 40");
assert property (send_one_prop) else $error ("Send zero bit timing off:  Neo_data should be high 18 cycles, then low 40");

// /******************************************************************/
// /*                        SEQUENCES/PROPERTIES                     */
// /******************************************************************/

// Check that Red was loaded correctly (correct pixel index/color level)
property load_R_prop;
    logic [2:0] pi;       // Local vars: pixel index, color level 
    logic [7:0] cl;     
    @(posedge clock) (load_color && color_index == 2'b00, pi = pixel_index, cl = color_level) |=> (dut.R[pi] == cl); 
endproperty: load_R_prop

// Check that Green was loaded correctly (correct pixel index/color level)
property load_G_prop;
    logic [2:0] pi;        // Local vars: pixel index, color level 
    logic [7:0] cl;      
    @(posedge clock) (load_color && color_index == 2'b10, pi = pixel_index, cl = color_level) |=> (dut.G[pi] == cl); 
endproperty: load_G_prop

// Check that Blue was loaded correctly (correct pixel index/color level)
property load_B_prop;
    logic [2:0] pi;        // Local vars: pixel index, color level 
    logic [7:0] cl;      
    @(posedge clock) (load_color && color_index == 2'b01, pi = pixel_index, cl = color_level) |=> (dut.B[pi] == cl); 
endproperty: load_B_prop


// Resets to ready_to_load = 1, ready_to_send = 1
property reset_loadsend_prop;
  @(posedge clock) $rose(reset) |-> (ready_to_load && ready_to_send);
endproperty

// Resets to blank packet (all zeros)
property reset_blank_packet_prop;
  @(posedge clock) $rose(reset) |-> dut.display_packet == 120'd0;
endproperty

// Sequence: detect no loads before sending display packet 
sequence no_load_before_send_seq;
  (reset) ##1 (!load_color throughout send_it[->1]);
endsequence 

// If immediately send (detect no load_colors before send_it), should send blank display packet (all zeros) 
property send_blank_pixels_prop;
  @(posedge clock) no_load_before_send_seq |-> dut.display_packet == 120'd0;
endproperty

// Must send all 120 bits in display packet upon done sending 
property send_all_120;
  @(posedge clock) $rose(dut.done_send) |-> dut.send_count == 120;
endproperty

// Sending a one-bit: assert high for 35 cycles, low 30 cycles
property send_one_prop;
  @(posedge clock) (dut.send_one) |-> neo_data[*35] ##1 !neo_data[*30];
endproperty

// Sending a one-bit: assert high for 18 cycles, low 40 cycles
property send_zero_prop;
  @(posedge clock) (dut.send_zero) |-> neo_data[*18] ##1 !neo_data[*40];
endproperty

// Must wait at least 50 microseconds (50/0.02 = 2500 clocks) until we can send a new packet 
property wait_between_packets_prop;
  @(posedge clock) $rose(dut.done_send) |-> dut.done_send ##[2500:$] $rose(dut.begin_send);
endproperty


endmodule: NeoPixelStrandController_test

