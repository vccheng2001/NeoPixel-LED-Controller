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

   output logic load_it, 
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

   

  // States
  enum logic [1:0] {IDLE_OR_LOAD, SEND} currstate, nextstate;

  // Next state logic 
  always_ff @(posedge clock, posedge reset)
    if (reset) currstate <= IDLE_OR_LOAD;
    else currstate <= nextstate;   

  // FSM logic for states/output values
  always_comb begin
    pixel_en = 1; pixel_clear = 0; // always vary values
    hue_en = 1; hue_clear = 0;     // always vary hues 
    pixel_index = 3'd0; color_index = 2'b00; color_level = 8'h00;
    load_it = 0; send_it = 0; 
    case (currstate)
      IDLE_OR_LOAD: begin
        if (!ready_to_load) nextstate = IDLE_OR_LOAD; 
        else if (ready_to_load) begin 
          nextstate = IDLE_OR_LOAD;
          load_it = 1; 
          pixel_index = pixel_to_load;
          color_index = pixel_to_load; // red 
          color_level = hue; // full brightness
        end
        else if (ready_to_send) begin 
          send_it = 1; 
          nextstate = SEND;
        end 
      end
      SEND: begin 
        load_it = 0; send_it = 0;
        if (!ready_to_load && !ready_to_send) begin 
          nextstate = SEND;
        end 
        else if (ready_to_load) begin 
          load_it = 1; 
          nextstate = IDLE_OR_LOAD;
        end 
      end
    endcase
  end
   

endmodule: Task2