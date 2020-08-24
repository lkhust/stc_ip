//Flexible static memory controller (FSMC) AHB Register Testbench

// fsmc_ahb_reg_tb.v

// AHB Register Tests

// Configuration restrictions:
//   none.
`timescale 1ns/1ps

module tb_top ();

`include "fsmc_def.v"
`include "m58bw16f_defin.v"

parameter ADDRWIDTH = 32,
          DATAWIDTH = 32;
parameter  IDLE   = 2'b00,
           BUSY   = 2'b01,
           NONSEQ = 2'b10,
           SEQ    = 2'b11;

// Status
reg [31:0] rdata              ;
reg [31:0] MCUTxData [0:`SRAM_SIZE-1]; // Data write to sram
reg [31:0] MCURxData [0:`SRAM_SIZE-1]; // Data read from sram
reg [ 1:0] mwidata            ;
reg [ 7:0] data_byte          ;
reg [15:0] data_halfword      ;
reg [31:0] data_word          ;
reg [15:0] fsmc_ad;

reg [ADDRWIDTH-1:0] haddr     ;
reg [DATAWIDTH-1:0] hwdata    ;
reg [          2:0] hburst    ;
reg [          2:0] hsize     ;
reg [          1:0] htrans    ;
reg                 hwrite    ;
reg                 hclk      ;
reg                 hresetn   ;
reg                 hsel      ;
reg                 fsmc_nwait;
reg                 mux1_en;
reg                 mux2_en;
reg                 nor_en;
reg                 sram_en;

// wire signals
wire [          1:0] hresp    ; // AHB response
wire                 hreadyi  ;
wire                 hreadyo  ; // AHB slave ready
wire [DATAWIDTH-1:0] hrdata   ; // AHB read data bus
wire [         25:0] fsmc_a   ;
wire [         15:0] fsmc_do  ;
wire [         15:0] fsmc_di  ;
wire [         15:0] fsmc_doen;
wire                 fsmc_noe ; //Output enable
wire                 fsmc_nwe ; // Write enable
wire [          4:1] fsmc_ne  ; // Bank SEL
wire                 fsmc_nl  ; // Latch
wire [          1:0] fsmc_nbl ; // Upper/Low byte
wire                 fsmc_clk ;
wire [         15:0] sram_dq  ;
wire [         19:0] fsmc_adr ;
wire                 oe_n     ;
wire                 latch_en ;
wire [         15:0] d        ;
wire [         15:0] q        ;
wire                 R        ;
wire [          4:1] E_       ;
wire [          4:1] CS_      ;

integer Vector, Errors, i, j;

`include "fsmc_tasks.v"
`include "m58bw16f_functions.v"

assign hreadyi = hreadyo;
assign sram_dq = (&fsmc_doen) ? fsmc_do : 16'bz;
assign fsmc_di = sram_dq;
assign E_      = nor_en ? fsmc_ne : 4'b1111;
assign CS_     = sram_en ? fsmc_ne : 4'b1111;

fsmc u_fsmc (
  .HCLK      (hclk      ),
  .HRESETn   (hresetn   ),
  .HSEL      (hsel      ),
  .HTRANS    (htrans    ),
  .HWRITE    (hwrite    ),
  .HSIZE     (hsize     ),
  .HADDR     (haddr     ),
  .HWDATA    (hwdata    ),
  .HREADY    (hreadyi   ),
  .FSMC_NWAIT(fsmc_nwait),
  .FSMC_DI   (fsmc_di   ),
  .HRESP     (hresp     ),
  .HREADYOUT (hreadyo   ),
  .HRDATA    (hrdata    ),
  .FSMC_A    (fsmc_a    ),
  .FSMC_DO   (fsmc_do   ),
  .FSMC_DOEN (fsmc_doen ),
  .FSMC_NOE  (fsmc_noe  ),
  .FSMC_NWE  (fsmc_nwe  ),
  .FSMC_NE   (fsmc_ne   ),
  .FSMC_NL   (fsmc_nl   ),
  .FSMC_NBL  (fsmc_nbl  ),
  .FSMC_CLK  (fsmc_clk  )
);

cellram u_cellram1 (
  .zz_n(1'b1       ),
  .ce_n(CS_[1]     ),
  .oe_n(fsmc_noe   ),
  .we_n(fsmc_nwe   ),
  .ub_n(fsmc_nbl[1]),
  .lb_n(fsmc_nbl[0]),
  .addr(fsmc_adr   ),
  .dq  (sram_dq    )
);

cellram u_cellram2 (
  .zz_n(1'b1       ),
  .ce_n(CS_[2]     ),
  .oe_n(fsmc_noe   ),
  .we_n(fsmc_nwe   ),
  .ub_n(fsmc_nbl[1]),
  .lb_n(fsmc_nbl[0]),
  .addr(fsmc_adr   ),
  .dq  (sram_dq    )
);

cellram u_cellram3 (
  .zz_n(1'b1       ),
  .ce_n(CS_[3]     ),
  .oe_n(fsmc_noe   ),
  .we_n(fsmc_nwe   ),
  .ub_n(fsmc_nbl[1]),
  .lb_n(fsmc_nbl[0]),
  .addr(fsmc_adr   ),
  .dq  (sram_dq    )
);

cellram u_cellram4 (
  .zz_n(1'b1       ),
  .ce_n(CS_[4]     ),
  .oe_n(fsmc_noe   ),
  .we_n(fsmc_nwe   ),
  .ub_n(fsmc_nbl[1]),
  .lb_n(fsmc_nbl[0]),
  .addr(fsmc_adr   ),
  .dq  (sram_dq    )
);

m58bw16f_top u_m58bw16f_top1 (
  .A     (fsmc_adr[18:0]    ),
  .E_    (E_[1]             ),
  .K     (1'b1              ),
  .PEN   (1'b1              ),
  .L_    (fsmc_nl           ),
  .RP_   (hresetn           ),
  .G_    (fsmc_noe          ),
  .GD_   (1'b1              ),
  .W_    (fsmc_nwe          ),
  .WP_   (1'b1              ),
  .B_    (1'b1              ),
  .VDD   (1'b1              ),
  .VDDQ  (1'b1              ),
  .VDDQIN(1'b1              ),
  .VSS   (1'b0              ),
  .VSSQ  (1'b0              ),
  .DQ    ({sram_dq, sram_dq}),
  .R     (R                 )
);

m58bw16f_top u_m58bw16f_top2 (
  .A     (fsmc_adr[18:0]    ),
  .E_    (E_[2]             ),
  .K     (1'b1              ),
  .PEN   (1'b1              ),
  .L_    (fsmc_nl           ),
  .RP_   (hresetn           ),
  .G_    (fsmc_noe          ),
  .GD_   (1'b1              ),
  .W_    (fsmc_nwe          ),
  .WP_   (1'b1              ),
  .B_    (1'b1              ),
  .VDD   (1'b1              ),
  .VDDQ  (1'b1              ),
  .VDDQIN(1'b1              ),
  .VSS   (1'b0              ),
  .VSSQ  (1'b0              ),
  .DQ    ({sram_dq, sram_dq}),
  .R     (R                 )
);

m58bw16f_top u_m58bw16f_top3 (
  .A     (fsmc_adr[18:0]    ),
  .E_    (E_[3]             ),
  .K     (1'b1              ),
  .PEN   (1'b1              ),
  .L_    (fsmc_nl           ),
  .RP_   (hresetn           ),
  .G_    (fsmc_noe          ),
  .GD_   (1'b1              ),
  .W_    (fsmc_nwe          ),
  .WP_   (1'b1              ),
  .B_    (1'b1              ),
  .VDD   (1'b1              ),
  .VDDQ  (1'b1              ),
  .VDDQIN(1'b1              ),
  .VSS   (1'b0              ),
  .VSSQ  (1'b0              ),
  .DQ    ({sram_dq, sram_dq}),
  .R     (R                 )
);

m58bw16f_top u_m58bw16f_top4 (
  .A     (fsmc_adr[18:0]    ),
  .E_    (E_[4]             ),
  .K     (1'b1              ),
  .PEN   (1'b1              ),
  .L_    (fsmc_nl           ),
  .RP_   (hresetn           ),
  .G_    (fsmc_noe          ),
  .GD_   (1'b1              ),
  .W_    (fsmc_nwe          ),
  .WP_   (1'b1              ),
  .B_    (1'b1              ),
  .VDD   (1'b1              ),
  .VDDQ  (1'b1              ),
  .VDDQIN(1'b1              ),
  .VSS   (1'b0              ),
  .VSSQ  (1'b0              ),
  .DQ    ({sram_dq, sram_dq}),
  .R     (R                 )
);

sn74hc573a u_sn74hc573a (
  .oe_n    (oe_n    ),
  .latch_en(latch_en),
  .d       (d       ),
  .q       (q       )
);

assign oe_n = fsmc_ne[1] && fsmc_ne[2];
assign latch_en = ~fsmc_nl;
assign d = sram_dq;

assign fsmc_adr = ~(mux1_en && mux2_en) ? fsmc_a[19:0] : fsmc_nl ? {fsmc_a[19:16], q} : 20'bz;

always @(posedge u_fsmc.u_fsmc_core.addhld1_clr) begin
  if(u_fsmc.u_fsmc_core.current_state[3:0] == 4'b0101)
    nwait_set();
  if(u_fsmc.u_fsmc_core.current_state[3:0] == 4'b1010)
    nwait_set();
end

initial begin
  hclk = 0;
  forever #`CYCLE hclk = ~hclk;
end

// Generate input data
always @ (negedge hclk) begin
  get_randomVal(data_word);
end

// Main
initial begin
  Errors = `DISABLE;
  sram_en = `DISABLE;
  mux1_en = `DISABLE;
  mux2_en = `DISABLE;
  nor_en = `DISABLE;
  sys_reset();

  sram_en = `ENABLE;
  `include "mode1.v"
  `include "mode1_NE2.v"
  `include "mode2.v"
  `include "mode2_NE3.v"
  `include "modeA_D.v"
  `include "modeB_B.v"
  `include "modeC_B.v"
  `include "modeC_C.v"
  `include "modeD_D.v"
  `include "modeD_D_NE4.v"
  `include "modeMux.v"
  `include "modeMux_NE2.v"
  sram_en = `DISABLE;
  nor_en = `ENABLE;
  `include "mode2_Nor.v"
  `include "modeC_D_Nor_NE4.v"
  `include "modeC_C_Nor_NE2.v"
  `include "modeD_D_Nor_NE3.v"
  nor_en = `DISABLE;

  // End of test bench
  $display("");
  if (Errors == 1)
    $display("%t **ERROR: completed with 1 error! *_* *_* ", $realtime);
  else if (Errors)
    $display("%t **ERROR: completed with %d errors!!! *_* *_* ", $realtime, Errors);
  else
    $display("%t INFO: Simulation is completed without errors, ^_^ ^_^ ^_^ ", $realtime);
  #(`CYCLE*50);
  $finish;
end

`ifdef FSDB
  initial begin
    $fsdbDumpfile("./tb_top.fsdb");
    $fsdbDumpvars;
  end
`endif

endmodule
