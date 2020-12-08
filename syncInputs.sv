
`default_nettype none

// Synchronize asynchronous inputs using double Flip Flop synchronizers

module syncInputs 
(input logic inKEY0, 
 input logic [9:0] inSW,
 input logic clock, reset,
 output logic [4:0] syncedSW, output logic syncedKEY0);

  
// Flip flop synchronizers for KEY[0], SW[0], SW[1] to reduce metastability

logic syncedKEY0_temp;

register #(1) syncKEY0_0 (.q(syncedKEY0_temp), .d(inKEY0), .en(1'b1), .clock(clock), .clear(1'b0), .reset(1'b0));
register #(1) syncKEY0_1 (.q(syncedKEY0), .d(syncedKEY0_temp), .en(1'b1), .clock(clock), .clear(1'b0), .reset(1'b0));

 logic [4:0] syncedSW_temp;
 logic [4:0] syncedSW;

 genvar j; 
 generate
 for (j = 0; j < 5; j++) begin: sw
    register #(1) syncSW_0 (.q(syncedSW_temp[j]), .d(inSW[j]), .en(1'b1), .clock(clock), .clear(1'b0), .reset(reset));
    register #(1) syncSW_1 (.q(syncedSW[j]), .d(syncedSW_temp[j]]), .en(1'b1), .clock(clock), .clear(1'b0), .reset(reset));
 end
 endgenerate

endmodule: syncInputs