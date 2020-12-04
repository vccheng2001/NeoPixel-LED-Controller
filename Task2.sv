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


  // Control color level (0 - 32 hex to )
  logic [4:0] hue;
  logic hue_en, hue_clear;

  counter #(5) hueCounter (.en(hue_en), .clear(hue_clear), .q(hue),
                              .d(5'd0), .clock(clock), .reset(reset));

   // Control which pixel to load (0,1,2,3,4)
  logic [1:0] pixel_to_load;
  logic pixel_en, pixel_clear;

  counter #(2) pixelCounter (.en(pixel_en), .clear(pixel_clear), .q(pixel_to_load),
                              .d(2'd0), .clock(clock), .reset(reset));

  localparam MAX_NUM_LOADS = 4'd15;
  // Number of loads
  logic [3:0] load_count;
  logic load_count_en, load_count_clear;

  counter #(4) loadCouter (.en(load_count_en), .clear(load_count_clear), .q(load_count),
                              .d(4'd0), .clock(clock), .reset(reset));

  logic done_load;

  // States
  enum logic [1:0] {IDLE, LOAD, SEND} currstate, nextstate;

  // Next state logic 
  always_ff @(posedge clock, posedge reset)
    if (reset) currstate <= IDLE;
    else currstate <= nextstate;   

  // FSM logic for states/output values
  always_comb begin
    done_load = 0;
    pixel_en = 1; pixel_clear = 0; // always vary values
    hue_en = 1; hue_clear = 0;     // always vary hues 
    pixel_index = 3'd0; color_index = 2'b00; color_level = 8'h00;
    load_color = 0; send_it = 0; 
    load_count_en = 0; load_count_clear = 1;
    case (currstate)
      IDLE: begin
        if (done_load) done_load = 1; 

        if (!ready_to_load && !ready_to_send) nextstate = IDLE;
        // if already done loading up to 15 times, 
        else if (ready_to_load) begin 
          if (done_load) begin 
            nextstate = IDLE;
          end 
          else begin 
            nextstate = LOAD;
            // tell neopixel to use these values 
            load_color = 1; 
            pixel_index = pixel_to_load;
            color_index = pixel_to_load; // red 
            color_level = hue; // full brightness
          end 
        end
        else if (ready_to_send) begin 
          send_it = 1; 
          nextstate = SEND;
          done_load = 0;
        end 
      end

      LOAD: begin

        if (!ready_to_load || load_count == MAX_NUM_LOADS) begin 
          done_load = 1;
          nextstate = IDLE;
          load_count_clear = 1; load_count_en = 0;
          load_color = 0;
        end 
        // keep loading for <MAX_NUM_LOADS> times 
        else if (ready_to_load) begin 
          done_load = 0; 
          load_count_en = 1; load_count_clear = 0; 
          nextstate = LOAD;
          load_color = 1; 
          pixel_index = pixel_to_load;
          color_index = pixel_to_load; // red 
          color_level = hue; // full brightness
        end
      end

      SEND: begin 
        done_load = 0;
        load_color = 0; send_it = 0;
        if (!ready_to_load && !ready_to_send) begin 
          nextstate = SEND;
        end 
        else if (ready_to_load) begin 
          load_color = 1; 
          nextstate = IDLE;
        end 
      end
    endcase
  end
   

endmodule: Task2