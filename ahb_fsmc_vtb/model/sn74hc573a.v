/*------------------------------------------------------------------------------
--  SNx4HC573A Octal Transparent D-Type Latches With 3-State Outputs
--  Verilog Behavioral Model
------------------------------------------------------------------------------*/
module sn74hc573a (
  input  wire        oe_n    ,
  input  wire        latch_en,
  input  wire [15:0] d       ,
  output wire [15:0] q
);

  assign q = ~oe_n ? latch_en ? d : q : 16'bz;

endmodule