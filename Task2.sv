`default_nettype none


// Hardware thread, tells NeoPixelController to load/send 
module Task2
  (input  logic clock, reset, 
   // Handshaking signals 
   input logic [4:0] syncedSW, // FPGA Switches  

   // Inputs from Neo controller 
   input logic neo_data,
   input logic ready_to_load, ready_to_send,
   input logic begin_send, done_send, done_wait,

   // Inputs from color module: select different patterns based on Switches
   input logic [62:0][7:0] color_array,
   input logic [62:0][2:0] pixel_array,
   input logic [6:0] max_num_loads,

   // Outputs: tell controller which color parameters to load
   output logic [2:0] pixel_index,      
   output logic [1:0] color_index,
   output logic [7:0] color_level,

   // Signal variables to controller 
   output logic load_color,
   output logic send_it);

  /******************************************************************/
  /*      Counter to iterate through color arrays                   */
  /******************************************************************/

  logic [5:0] array_count;
  logic array_en, array_clear;

  counter #(6) arrayCounter (.en(array_en), .clear(array_clear), .q(array_count),
                              .d(6'd0), .clock(clock), .reset(reset));


 /******************************************************************/
  /*                      Control color index toggle               */
  /******************************************************************/

  logic [1:0] toggle;
  logic toggle_en, toggle_clear;
  counter #(2) toggleCounter (.en(toggle_en), .clear(toggle_clear), .q(toggle),
                              .d(2'b0), .clock(clock), .reset(reset));

  /******************************************************************/
  /*          Count number of loads (up to max_num_loads)           */
  /******************************************************************/
  // Number of loads
  logic [6:0] load_count;
  logic load_count_en, load_count_clear;

  counter #(7) loadCounter (.en(load_count_en), .clear(load_count_clear), .q(load_count),
                              .d(7'd0), .clock(clock), .reset(reset));

 /******************************************************************/
  /*          Counts number of sends of the same LED packet           */
  /******************************************************************/
 
  // Num times the same LED vals were sent
  logic [11:0] sent_count;
  logic sent_count_en, sent_count_clear;

  counter #(12) sentCounter (.en(sent_count_en), .clear(sent_count_clear), .q(sent_count),
                              .d(12'd0), .clock(clock), .reset(reset));

  /******************************************************************/
  /*                      Producer FSM                              */
  /******************************************************************/
  enum logic [2:0] {RESET, IDLE, LOAD, DONE_LOAD, SEND} currstate, nextstate;

  // Next state logic 
  always_ff @(posedge clock, posedge reset)
    if (reset) currstate <= RESET;
    else currstate <= nextstate;   

  // Indicates display packet has been loaded with colors 
  logic loaded; 

  // FSM logic for states/output values
  always_comb begin
    array_en = 1; array_clear = 0;          // Iterate through arrays 
    
    // Default color parameter values 
    pixel_index = 3'd0; color_level = 8'h00; color_index = 2'b00;

    load_color = 0; send_it = 0;             // Input to neo controller 

    loaded = 0;                             // Initially nothing loaded 

    load_count_en = 0; load_count_clear = 1; // Counter variables 
    sent_count_en = 0; sent_count_clear = 0;
    toggle_en = 1; toggle_clear = 0;

    case (currstate)

      // Reset: clear counters 
      RESET: begin 
        nextstate = IDLE;
        toggle_en = 0; toggle_clear = 1; 
        array_clear = 1; array_en = 0;
        sent_count_en = 0; sent_count_clear = 1; 
      end 

      /******************************************************************/
      /*                 Wait for Load/Send                             */
      /******************************************************************/
    
      IDLE: begin
        // Tell controller to load new values every 12'fff sends 
        if (ready_to_load && sent_count == 12'd0) begin  
          // Assert load_color 
          nextstate = LOAD;
          load_color = 1; 

          // Increment load count 
          load_count_en = 1; load_count_clear = 0;

          // Set color parameters 
          pixel_index = pixel_array[array_count];
          color_index =  (toggle == 2'b11)?  2'b00 : toggle;  
          color_level = color_array[array_count];

        // If can't load but can't send 
        end else if (ready_to_send) begin 
          // Assert send_it 
          nextstate = SEND;
          send_it = 1; 

           // Deassert loaded 
          sent_count_clear = 0; sent_count_en = 1;
          loaded = 0; 
        end else nextstate = IDLE;
  
      end


    /******************************************************************/
    /*             Load colors up to <max_num_loads> times            */
    /******************************************************************/
 
      LOAD: begin
        // Only stop if <num_max_loads> or no longer ready_to_load
        if (!ready_to_load || load_count == max_num_loads) begin 
          nextstate = DONE_LOAD;
          load_count_clear = 1; load_count_en = 0;
          load_color = 0;
          loaded = 1;
        end 
        // Else continue loading 
        else begin 
          nextstate = LOAD;
          // Assert load_color 
          load_color = 1; 
          // Increment load_count
          load_count_en = 1; load_count_clear = 0; 
          
          // Set color parameters 
          pixel_index = pixel_array[array_count];
          color_index =  (toggle == 2'b11)?  2'b00 : toggle;  
          color_level = color_array[array_count];
        end
      end

      
      /******************************************************************/
      /*               Done load, wait for send                         */
      /******************************************************************/

      DONE_LOAD: begin
        loaded = 1; 
        // Go to Send state 
        if (ready_to_send) begin 
          nextstate = SEND;
          send_it = 1; 
          sent_count_clear = 0; sent_count_en = 1;  
          loaded = 0;
        end else nextstate = DONE_LOAD;
  
      end

      /******************************************************************/
      /*                 Wait while sending                             */
      /******************************************************************/

      SEND: begin // wait for packet to finish sending + waited 50 microseconds
        if (!done_wait) nextstate = SEND;
        else nextstate = IDLE;
      end


    endcase
  end
   

endmodule: Task2