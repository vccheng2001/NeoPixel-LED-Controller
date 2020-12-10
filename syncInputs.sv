
`default_nettype none

// Synchronize asynchronous inputs using double Flip Flop synchronizers

module syncInputs 
(input logic inKEY0, 
 input logic [9:0] inSW,
 input logic clock, reset,
 output logic [4:0] syncedSW, output logic syncedKEY0);

  
// Flip flop synchronizers for KEY[0] to reduce metastability
// KEY0 is used as a reset 

logic syncedKEY0_temp;
register #(1) syncKEY0_0 (.q(syncedKEY0_temp), .d(inKEY0), .en(1'b1),
                           .clock(clock), .clear(1'b0), .reset(1'b0));
register #(1) syncKEY0_1 (.q(syncedKEY0), .d(syncedKEY0_temp), .en(1'b1), 
                           .clock(clock), .clear(1'b0), .reset(1'b0));

// Flip flop synchronizers for SW Switches to reduce metastability
// SW0,1,2 used to determine color patterns/motions 

logic [4:0] syncedSW_temp;

 genvar j; 
 generate
 for (j = 0; j < 5; j++) begin: sw
    register #(1) syncSW_0 (.q(syncedSW_temp[j]), .d(inSW[j]), .en(1'b1), 
                              .clock(clock), .clear(1'b0), .reset(reset));
    register #(1) syncSW_1 (.q(syncedSW[j]), .d(syncedSW_temp[j]), .en(1'b1),
                                  .clock(clock), .clear(1'b0), .reset(reset));
 end
 endgenerate

endmodule: syncInputs