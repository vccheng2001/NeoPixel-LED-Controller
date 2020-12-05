
`default_nettype none

// Synchronize asynchronous inputs using double Flip Flop synchronizers

module syncInputs 
(input logic inKEY0, inSW0, inSW1, clock, reset,
 output logic syncedKEY0, syncedSW0, syncedSW1);

  
// Flip flop synchronizers for KEY[0], SW[0], SW[1] to reduce metastability

logic syncedKEY0_temp;

register #(1) syncKEY0_0 (.q(syncedKEY0_temp), .d(inKEY0), .en(1'b1), .clock(clock), .clear(1'b0), .reset(1'b0));
register #(1) syncKEY0_1 (.q(syncedKEY0), .d(syncedKEY0_temp), .en(1'b1), .clock(clock), .clear(1'b0), .reset(1'b0));

logic syncedSW0_temp;

register #(1) syncSW0_0 (.q(syncedSW0_temp), .d(inSW0), .en(1'b1), .clock(clock), .clear(1'b0), .reset(reset));
register #(1) syncSW0_1 (.q(syncedSW0), .d(syncedSW0_temp), .en(1'b1), .clock(clock), .clear(1'b0), .reset(reset));

logic syncedSW1_temp;

register #(1) syncSW1_0 (.q(syncedSW1_temp), .d(inSW1), .en(1'b1), .clock(clock), .clear(1'b0), .reset(reset));
register #(1) syncSW1_1 (.q(syncedSW1), .d(syncedSW1_temp), .en(1'b1), .clock(clock), .clear(1'b0), .reset(reset));


endmodule: syncInputs