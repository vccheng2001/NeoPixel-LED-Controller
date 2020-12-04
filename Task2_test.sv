`default_nettype none

module Task2_test();
   logic clock, reset;

   logic [2:0] pixel_index;           // Fields for load_color 
   logic [1:0] color_index;
   logic [7:0] color_level;

   logic load_color, send_it;         // Signals 
   logic neo_data, ready_to_load, ready_to_send;

  // Instantiate dut
    Task2 dut (.*);

  // Testbench clock
  initial begin
    clock = 0;
    forever #0.5 clock = ~clock;
  end

  // Simulates test
  initial begin
    $monitor($time," Reset=%d, Curr=%s, Next=%s, LI=%d, SI=%d, RL=%b, RS=%b,  CI=%d,PI=%d,CL=%h",
    reset, dut.currstate.name, dut.nextstate.name,load_color, send_it, ready_to_load, ready_to_send, color_index, pixel_index, color_level);
 
    reset = 1; 
    // Init to 0
    @(posedge clock);          
    reset <= 0;
    ready_to_load <= 0;
    ready_to_send <= 0;
    @(posedge clock);
    @(posedge clock);
    @(posedge clock);
    ready_to_load <= 1; ready_to_send <= 0; // load
    @(posedge clock);
    ready_to_load <= 1; ready_to_send <= 1; // load 
    @(posedge clock);
    ready_to_load <= 1;                     // load
    @(posedge clock);
    ready_to_load <= 0; ready_to_send <= 1; // send 
    @(posedge clock);
    ready_to_send <= 0;
    @(posedge clock);
    @(posedge clock);
    @(posedge clock);
    @(posedge clock);
    @(posedge clock);
    @(posedge clock);
    @(posedge clock);
    ready_to_load <= 1; ready_to_send <= 0; // send 
    @(posedge clock);
    ready_to_load <= 1;
    @(posedge clock);
    ready_to_load <= 1;
    @(posedge clock);
    @(posedge clock);
    @(posedge clock);
    @(posedge clock);
    @(posedge clock);
    @(posedge clock);
    ready_to_load <= 0; ready_to_send <= 0;
    @(posedge clock);
    #1000 $finish;            
  end


endmodule: Task2_test

