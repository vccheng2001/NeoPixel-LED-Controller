`default_nettype none

module Task2
  (input  logic clock, reset, 
   // Handshaking signals 
   input logic neo_data,
   input logic ready_to_load,
   input logic ready_to_send,
   input logic begin_send, done_send, done_wait,
   
   output logic [2:0] pixel_index,      
   output logic [1:0] color_index,
   output logic [7:0] color_level,

   output logic load_color, 
   output logic send_it);

  /******************************************************************/
  /*                  Control color level (0-32 )                   */
  /******************************************************************/
 

  logic [4:0] hue_to_load;
  logic hue_en, hue_clear;

  counter #(5) hueCounter (.en(hue_en), .clear(hue_clear), .q(hue_to_load),
                              .d(5'd0), .clock(clock), .reset(reset));


  /******************************************************************/
  /*              Control which pixel to load (0 - 4)                */
  /******************************************************************/

  logic [1:0] pixel_to_load;
  logic pixel_en, pixel_clear;

  counter #(2) pixelCounter (.en(pixel_en), .clear(pixel_clear), .q(pixel_to_load),
                              .d(2'd0), .clock(clock), .reset(reset));



  logic [1:0] count;
  logic count_en, count_clear;
  assign pixel_en = (count==3); 

  counter #(2) ccounter (.en(count_en), .clear(count_clear), .q(count),
                              .d(2'd0), .clock(clock), .reset(reset));

  /******************************************************************/
  /*                  Control number of loads                       */
  /******************************************************************/
 
 localparam MAX_NUM_LOADS = 8'd255;

  // Number of loads
  logic [7:0] load_count;
  logic load_count_en, load_count_clear;

  counter #(8) loadCounter (.en(load_count_en), .clear(load_count_clear), .q(load_count),
                              .d(8'd0), .clock(clock), .reset(reset));

 /******************************************************************/
  /*                  Control number of sends                       */
  /******************************************************************/
 
  // Num times the same LED vals were sent
  logic [19:0] sent_count;
  logic sent_count_en, sent_count_clear;

  counter #(20) sentCounter (.en(sent_count_en), .clear(sent_count_clear), .q(sent_count),
                              .d(20'd0), .clock(clock), .reset(reset));

  /******************************************************************/
  /*                      Producer FSM                              */
  /******************************************************************/
  enum logic [2:0] {RESET, IDLE,IDLE2, LOAD, SEND} currstate, nextstate;

  // Next state logic 
  always_ff @(posedge clock, posedge reset)
    if (reset) currstate <= IDLE;
    else currstate <= nextstate;   

  logic loaded; 
  // FSM logic for states/output values
  always_comb begin
    count_en = 1; count_clear = 0;
    pixel_clear = 0; // always vary values
    hue_en = 1; hue_clear = 0;     // always vary hues 
    pixel_index = 3'd0; color_level = 8'h00; color_index = 2'b00;

    load_color = 0; send_it = 0; 
    load_count_en = 0; load_count_clear = 1;
    loaded = 0;
    sent_count_en = 0; sent_count_clear = 0;


    case (currstate)
      RESET: begin 
        nextstate = IDLE;
        sent_count_en = 0; sent_count_clear = 1; 
      end 

      /******************************************************************/
      /*                 Wait for Load/Send                             */
      /******************************************************************/
    
      IDLE: begin
        if (ready_to_load && sent_count == 20'h0) begin  // only load if not already done 
          nextstate = LOAD;
          // tell neopixel to use these values 
          load_color = 1; 
          load_count_en = 1; load_count_clear = 0;

          pixel_index = pixel_to_load;
          color_index = count;
          color_level = hue_to_load;   
        end else if (ready_to_send) begin 
          sent_count_clear = 0; sent_count_en = 1;
          loaded = 0;
          nextstate = SEND;
          send_it = 1; 
        end else nextstate = IDLE;
  
      end

      IDLE2: begin
        loaded = 1; 
        if (ready_to_send) begin 
          sent_count_clear = 0; sent_count_en = 1;  
          loaded = 0;
          nextstate = SEND;
          send_it = 1; 
        end else nextstate = IDLE2;
  
      end


    /******************************************************************/
    /*                 Load MAX_LOAD times                            */
    /******************************************************************/
 
      LOAD: begin

        if (!ready_to_load || load_count == MAX_NUM_LOADS) begin 
          nextstate = IDLE2;
          load_count_clear = 1; load_count_en = 0;
          load_color = 0;
          loaded = 1;
        end 
        // keep loading until MAX_NUM_LOADS
        else begin 
          nextstate = LOAD;

          load_color = 1; 
          load_count_en = 1; load_count_clear = 0; 

          pixel_index = pixel_to_load;
          color_index = count;
          color_level = hue_to_load; 
        end
      end

      /******************************************************************/
      /*                 Wait while sending                             */
      /******************************************************************/
 

      SEND: begin // wait for a ready_to_load signal
        if (!done_wait) nextstate = SEND;
        else nextstate = IDLE;
      end


    endcase
  end
   

endmodule: Task2