`default_nettype none

module Task2
  (input  logic clock, reset, 
   // Handshaking signals 
   input logic neo_data,
   input logic ready_to_load,
   input logic ready_to_send,
   
   output logic [2:0] pixel_index,      
   output logic [1:0] color_index,
   output logic [7:0] color_level,

   output logic load_color, 
   output logic send_it);


  /******************************************************************/
  /*                  Control done_loaded                           */
  /******************************************************************/

  logic loaded;
  logic loaded_clear, loaded_en;

  register #(1) ld (.q(loaded), .d(1'b1), .en(loaded_en), .clear(loaded_clear), .clock(clock), .reset(reset));
  
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

  /******************************************************************/
  /*                  Control number of loads                       */
  /******************************************************************/
 
 localparam MAX_NUM_LOADS = 4'd15;

  // Number of loads
  logic [3:0] load_count;
  logic load_count_en, load_count_clear;

  counter #(4) loadCounter (.en(load_count_en), .clear(load_count_clear), .q(load_count),
                              .d(4'd0), .clock(clock), .reset(reset));


  /******************************************************************/
  /*                      Producer FSM                              */
  /******************************************************************/
  enum logic [2:0] {RESET, IDLE, LOAD, SEND} currstate, nextstate;

  // Next state logic 
  always_ff @(posedge clock, posedge reset)
    if (reset) currstate <= RESET;
    else currstate <= nextstate;   

  // FSM logic for states/output values
  always_comb begin

    pixel_en = 1; pixel_clear = 0; // always vary values
    hue_en = 1; hue_clear = 0;     // always vary hues 
    pixel_index = 3'd0; color_index = 2'b00; color_level = 8'h00;

    load_color = 0; send_it = 0; 
    load_count_en = 0; load_count_clear = 1;

    loaded_en = 0; loaded_clear = 0;

    case (currstate)
    
      RESET: begin 
        loaded_en = 0; loaded_clear = 1;
        nextstate = IDLE;
      end

      /******************************************************************/
      /*                 Wait for Load/Send                             */
      /******************************************************************/
    
      IDLE: begin

        if (ready_to_load && !loaded) begin  // only load if not already done 
          nextstate = LOAD;
          // tell neopixel to use these values 
          load_color = 1; 
          load_count_en = 1; load_count_clear = 0;

          pixel_index = pixel_to_load;
          color_index = pixel_to_load; // temp 
          color_level = hue_to_load;   

        end else if (ready_to_send) begin 
          nextstate = SEND;
          send_it = 1;
          loaded_clear = 1; loaded_en = 0;

        end else nextstate = IDLE;
  
      end


    /******************************************************************/
    /*                 Load MAX_LOAD times                            */
    /******************************************************************/
 
      LOAD: begin

        if (!ready_to_load || load_count == MAX_NUM_LOADS) begin 
          nextstate = IDLE;
          load_color = 0;
          loaded_en = 1; loaded_clear = 0; // loaded = 1
        end 
        // keep loading until MAX_NUM_LOADS
        else begin 
          nextstate = LOAD;

          load_color = 1; 
          load_count_en = 1; load_count_clear = 0; 

          pixel_index = pixel_to_load;
          color_index = pixel_to_load; // temp 
          color_level = hue_to_load; 
        end
      end

      /******************************************************************/
      /*                 Wait while sending                             */
      /******************************************************************/
 

      SEND: begin // wait for a ready_to_load signal
        loaded_en = 0; loaded_clear = 1; 
        if (!ready_to_load && !ready_to_send) nextstate = SEND;
        else nextstate = IDLE;
      end


    endcase
  end
   

endmodule: Task2