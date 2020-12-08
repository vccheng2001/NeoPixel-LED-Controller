`default_nettype none



module Task2
  (input  logic clock, reset, 
   // Handshaking signals 
   input logic [4:0] syncedSW,
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

  logic [5:0] hue_count;
  logic hue_en, hue_clear;

  counter #(6) hueCounter (.en(hue_en), .clear(hue_clear), .q(hue_count),
                              .d(6'd0), .clock(clock), .reset(reset));


  localparam C0 = 8'h00;
  localparam C1 = 8'h05;
  localparam C2 = 8'h10;
  localparam C3 = 8'h20;

logic [62:0][7:0] C_ARR;
logic [62:0][2:0] P_ARR;
    
 assign C_ARR = {C0, C1, C0, C1, C1, C3, C2, C0, C3, C2, C3, C0, C1, C3, C1, C1, C2, C3, C2, C0,
                      C2, C2, C0, C3, C1, C0, C0, C0, C3, C2, C0, C3, C1, C2, C3, C1, C1, C2, C2, C0, 
                      C2, C1, C3, C2, C0, C0, C1, C0, C1,  C1, C0, C0, C1, C3, C3, C3, C2, C2, C0, C1,
                      C0, C3, C1, C2, C2, C0, C1,C1, C3, C2, C0, C3, C0, C2, C3, C1, C0, C3, C0, C1, 
                      C2, C2, C0, C3, C1, C0, C0, C0, C3, C2, C0, C3, C1, C2, C3, C1, C1, C2, C2, C0, C1, C2, C3};
 assign P_ARR = {3'd1,3'd1,3'd2,
                3'd0,3'd0,3'd0,3'd1,3'd1,3'd1,3'd2,3'd2,3'd2,3'd3,3'd3,3'd3,3'd4,3'd4,3'd4,3'd0,3'd1,3'd2,3'd1,3'd0,
                3'd0,3'd0,3'd0,3'd1,3'd1,3'd1,3'd2,3'd2,3'd2,3'd3,3'd3,3'd3,3'd4,3'd4,3'd4,3'd0,3'd1,3'd2,3'd1,3'd0,
                3'd0,3'd0,3'd0,3'd1,3'd1,3'd1,3'd2,3'd2,3'd2,3'd3,3'd3,3'd3,3'd4,3'd4,3'd4,3'd0,3'd1,3'd2,3'd1,3'd0};
 


  /******************************************************************/
  /*              Control which pixel to load (0 - 4)                */
  /******************************************************************/

  logic [2:0] pixel_to_load;
  logic pixel_en, pixel_clear;

  counter #(3) pixelCounter (.en(pixel_en), .clear(pixel_clear), .q(pixel_to_load),
                              .d(3'd0), .clock(clock), .reset(reset));

  logic [1:0] count;
  logic count_en, count_clear;

  counter #(2) ccounter (.en(count_en), .clear(count_clear), .q(count),
                              .d(2'd0), .clock(clock), .reset(reset));

 /******************************************************************/
  /*              Control color toggle                              */
  /******************************************************************/

  logic [1:0] toggle;
  logic toggle_en, toggle_clear;
  counter #(2) toggleCounter (.en(toggle_en), .clear(toggle_clear), .q(toggle),
                              .d(2'b0), .clock(clock), .reset(reset));

  /******************************************************************/
  /*                  Control number of loads                       */
  /******************************************************************/

// function logic [2:0] get_pixel_index
//     (input logic [4:0] syncedSW,
//      input logic [2:0] pixel_to_load);
//     if (pixel_to_load <= 3'd4) begin 
//       if (syncedSW[pixel_to_load]) return pixel_to_load;
//       else return 3'd0;
//     end
//     else return 3'd4; 
// endfunction


// function logic [7:0] get_color_level
//      (input logic [1:0] toggle);
//     if (toggle == 2'b11 ) return 8'h20;
//     else if (toggle == 2'b10) return 8'h10;
//     else if (toggle == 2'b01) return 8'h05;
//     else return 8'h00;

// endfunction


 
 localparam MAX_NUM_LOADS = 6'd63;

  // Number of loads
  logic [7:0] load_count;
  logic load_count_en, load_count_clear;

  counter #(8) loadCounter (.en(load_count_en), .clear(load_count_clear), .q(load_count),
                              .d(8'd0), .clock(clock), .reset(reset));

 /******************************************************************/
  /*                  Control number of sends                       */
  /******************************************************************/
 
  // Num times the same LED vals were sent
  logic [12:0] sent_count;
  logic sent_count_en, sent_count_clear;

  counter #(13) sentCounter (.en(sent_count_en), .clear(sent_count_clear), .q(sent_count),
                              .d(13'd0), .clock(clock), .reset(reset));

  /******************************************************************/
  /*                      Producer FSM                              */
  /******************************************************************/
  enum logic [2:0] {RESET, IDLE,IDLE2, LOAD, SEND} currstate, nextstate;

  // Next state logic 
  always_ff @(posedge clock, posedge reset)
    if (reset) currstate <= RESET;
    else currstate <= nextstate;   

  logic loaded; 
  // FSM logic for states/output values
  always_comb begin
    count_en = 1; count_clear = 0;
    pixel_en = 1; pixel_clear = 0; // always vary values
    hue_en = 1; hue_clear = 0;     // always vary hues 
    pixel_index = 3'd0; color_level = 8'h00; color_index = 2'b00;

    load_color = 0; send_it = 0; 
    load_count_en = 0; load_count_clear = 1;
    loaded = 0;
    sent_count_en = 0; sent_count_clear = 0;
    toggle_en = 0; toggle_clear = 0;

    case (currstate)
      RESET: begin 
        nextstate = IDLE;
        toggle_en = 0; toggle_clear = 1; 
        hue_clear = 1; hue_en = 0;
        sent_count_en = 0; sent_count_clear = 1; 
      end 

      /******************************************************************/
      /*                 Wait for Load/Send                             */
      /******************************************************************/
    
      IDLE: begin
        if (ready_to_load && sent_count == 13'd0) begin  // only load if not already done 
          nextstate = LOAD;
          toggle_en = 1; toggle_clear = 0;
          // tell neopixel to use these values 
          load_color = 1; 
          load_count_en = 1; load_count_clear = 0;

          pixel_index = P_ARR[hue_count];
          color_index = (toggle == 2'b11)?  2'b00 : toggle;
          color_level = C_ARR[hue_count];
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
          
          pixel_index = P_ARR[hue_count];
          color_index = (toggle == 2'b11)? 2'b10 : toggle;// 0
          color_level = C_ARR[hue_count];
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