`default_nettype none

module Task2_test();
   logic clock, reset;

   logic [2:0] pixel_index;           // Fields for load_color 
   logic [1:0] color_index;
   logic [7:0] color_level;

   logic load_color, send_it;         // Signals 
   logic neo_data, ready_to_load, ready_to_send;
   logic begin_send, done_send, done_wait;
  // Instantiate dut
    Task2 t2 (.*);
    NeoPixelStrandController neo (.*);

  // Testbench clock
  initial begin
    clock = 0;
    forever #0.5 clock = ~clock;
  end

  // Simulates test
  initial begin
    // $monitor($time,"N_CS=%s, N_NS=%s, T2_CS=%s, T2_NS = %s, RL=%d,RS=%d,(PI=%d,CI=%d,CL=%h),LC=%d,SI=%d,T2LoadCnt=%d, T2Loaded=%d,GRB=%h%h%h, Neo=%d, CC=%d, W50=%d, DW=%d, SC=%h, Tog=%b", neo.currstate.name, neo.nextstate.name, t2.currstate.name, t2.nextstate.name, ready_to_load,ready_to_send,pixel_index,color_index,color_level,load_color,
    // send_it, t2.load_count, t2.loaded, neo.G,neo.R,neo.B, neo_data, neo.cycle_count, neo.wait50_count, done_wait, t2.sent_count, t2.toggle);
    //$monitor($time,"NeoCS=%s,neoNS=%s, GRB=%h%h%h, sendCount=%d", neo.currstate.name, neo.nextstate.name, neo.G, neo.R,neo.B, t2.sent_count);
        $monitor($time," GRB=%h%h%h, sendCount=%d",neo.G, neo.R,neo.B, t2.sent_count);

    reset = 1; 
    @(posedge clock);          
    reset <= 0;
    @(posedge clock);
    wait(begin_send);
    $display("\n***********BEGIN SENDING************\n");
    wait(done_send);
    $display("\n***********DONE SENDING************\n");
    wait(done_wait);
    $display("\n***********DONE WAITING************\n");

    #10000000 $finish;            
  end


endmodule: Task2_test

