`timescale 1ns / 1ns

module top_tb ();

  localparam IDLE   = 2'b00;
  localparam NONSEQ = 2'b10;
  localparam SEQ    = 2'b11;
  localparam BIT32  = 2'b10;

  wire        hready_m ;
  wire        hready_s ;
  wire [31:0] hrdata_m ;
  wire [31:0] hrdata_s ;
  wire        pwrite_m ;
  wire        pwrite_s ;
  wire        penable_m;
  wire        penable_s;
  wire        psel_m   ;
  wire        psel_s   ;
  wire [31:0] pwdata_m ;
  wire [31:0] pwdata_s ;
  wire [31:0] prdata_m ;
  wire [31:0] prdata_s ;
  wire [31:0] paddr_m  ;
  wire [31:0] paddr_s  ;
  wire        pclk     ;
  wire        presetn  ;
  wire [ 7:0] paddr    ;
  wire        ic_clk   ;
  wire        ic_rst_n ;

  wire       cc_in       ;
  wire       cc_out      ;
  wire       cc_oen      ;
  wire       tx_ucpd_intr;
  wire       rx_ucpd_intr;

  wire data_en_tb;

  reg        hclk    ;
  reg        hsi_clk ;
  reg        hsel_m  ;
  reg [ 2:0] hsize_m ;
  reg [ 1:0] htrans_m;
  reg        hwrite_m;
  reg [31:0] haddr_m ;
  reg [31:0] hwdata_m;

  reg [ 2:0] hsize_s ;
  reg [ 1:0] htrans_s;
  reg        hwrite_s;
  reg [31:0] haddr_s ;
  reg [31:0] hwdata_s;
  reg        hsel_s  ;
  reg        hresetn ;

  reg [7:0] PD1_tx_buf [0:1024];
  reg [7:0] PD1_rx_buf [0:1024];
  reg [7:0] PD2_tx_buf [0:1024];
  reg [7:0] PD2_rx_buf [0:1024];

  reg [ 7:0] randval;
  reg ErrorStatus;

  reg finish_flag   ;
  reg tx_finished   ;
  reg rx_finished   ;
  reg tx_processing ;
  reg buf_rd_en     ;
  reg rx_hrst_flag  ;
  reg tx_hrst_flag  ;
  reg rx_orddet_flag;

  reg [31:0] rxdr      = 0;
  reg [31:0] rx_ordset = 0;
  reg [31:0] rx_paysz  = 0;
  integer Errors;
  integer i=0;
  integer j=0;

  `include "parameters.inc"
  `include "ucpd_irq.v"
  `include "ucpd_task.v"

  ahb2apb_m u_ahb2apb_m (
    .hclk     (hclk     ),
    .hresetn  (hresetn  ),
    .hsel_m   (hsel_m   ),
    .hsize_m  (hsize_m  ),
    .htrans_m (htrans_m ),
    .prdata_m (prdata_m ),
    .hwrite_m (hwrite_m ),
    .haddr_m  (haddr_m  ),
    .hwdata_m (hwdata_m ),
    .hrdata_m (hrdata_m ),
    .pwrite_m (pwrite_m ),
    .penable_m(penable_m),
    .hready_m (hready_m ),
    .psel_m   (psel_m   ),
    .pwdata_m (pwdata_m ),
    .paddr_m  (paddr_m  )
  );

  ahb2apb_s u_ahb2apb_s (
    .hclk     (hclk     ),
    .hresetn  (hresetn  ),
    .hsel_s   (hsel_s   ),
    .hsize_s  (hsize_s  ),
    .htrans_s (htrans_s ),
    .hwrite_s (hwrite_s ),
    .haddr_s  (haddr_s  ),
    .prdata_s (prdata_s ),
    .hwdata_s (hwdata_s ),
    .hrdata_s (hrdata_s ),
    .pwrite_s (pwrite_s ),
    .penable_s(penable_s),
    .hready_s (hready_s ),
    .psel_s   (psel_s   ),
    .pwdata_s (pwdata_s ),
    .paddr_s  (paddr_s  )

  );

  assign pclk     = hclk;
  assign ic_clk   = hclk;
  assign ic_rst_n = hresetn;
  assign data_en_tb = u_apb_ucpd_top_rx.u_apb_ucpd_core.u_apb_ucpd_fsm.rx_data_en;


  wire [2:0] cc1_compout;
  wire [2:0] cc2_compout;
  wire [1:0] phy_en;
  wire set_c500;
  wire set_c1500;
  wire set_c3000;
  wire set_pd;
  wire source_en;
  wire phy_rx_en;
  wire cc1_det_en;
  wire cc2_det_en;
  wire phy_cc1_com;
  wire phy_cc2_com;
  wire tx_cc1_datao;
  wire tx_cc1_dataoen;
  wire tx_cc2_datao;
  wire tx_cc2_dataoen;
  wire tx_cc1_datai;
  wire tx_cc2_datai;
  wire rx_cc1_datao;
  wire rx_cc1_dataoen;
  wire rx_cc2_datao;
  wire rx_cc2_dataoen;
  wire rx_cc1_datai;
  wire rx_cc2_datai;

  apb_ucpd_top u_apb_ucpd_top_tx (
    .pclk       (pclk          ),
    .presetn    (hresetn       ),
    .psel       (psel_m        ),
    .penable    (penable_m     ),
    .pwrite     (pwrite_m      ),
    .paddr      (paddr_m[7:0]  ),
    .pwdata     (pwdata_m      ),
    .ic_clk     (ic_clk        ),
    .ic_rst_n   (ic_rst_n      ),
    .cc1_datai  (tx_cc1_datai  ),
    .cc2_datai  (tx_cc2_datai  ),
    .phy_en     (              ),
    .set_c500   (              ),
    .set_c1500  (              ),
    .set_c3000  (              ),
    .set_pd     (              ),
    .source_en  (              ),
    .phy_rx_en  (              ),
    .cc1_det_en (              ),
    .cc2_det_en (              ),
    .phy_cc1_com(              ),
    .phy_cc2_com(              ),
    .cc1_datao  (tx_cc1_datao  ),
    .cc1_dataoen(tx_cc1_dataoen),
    .cc2_datao  (tx_cc2_datao  ),
    .cc2_dataoen(tx_cc2_dataoen),
    .ucpd_intr  (tx_ucpd_intr  ),
    .prdata     (prdata_m      )
  );


  apb_ucpd_top u_apb_ucpd_top_rx (
    .pclk       (pclk          ),
    .presetn    (hresetn       ),
    .psel       (psel_s        ),
    .penable    (penable_s     ),
    .pwrite     (pwrite_s      ),
    .paddr      (paddr_s[7:0]  ),
    .pwdata     (pwdata_s      ),
    .ic_clk     (ic_clk        ),
    .ic_rst_n   (ic_rst_n      ),
    .cc1_datai  (rx_cc1_datai  ),
    .cc2_datai  (rx_cc2_datai  ),
    .phy_en     (              ),
    .set_c500   (              ),
    .set_c1500  (              ),
    .set_c3000  (              ),
    .set_pd     (              ),
    .source_en  (              ),
    .phy_rx_en  (              ),
    .cc1_det_en (              ),
    .cc2_det_en (              ),
    .phy_cc1_com(              ),
    .phy_cc2_com(              ),
    .cc1_datao  (rx_cc1_datao  ),
    .cc1_dataoen(rx_cc1_dataoen),
    .cc2_datao  (rx_cc2_datao  ),
    .cc2_dataoen(rx_cc2_dataoen),
    .ucpd_intr  (rx_ucpd_intr  ),
    .prdata     (prdata_s      )
  );

  pulldown(rx_cc1_datai);
  pulldown(rx_cc2_datai);

  assign rx_cc1_datai = tx_cc1_dataoen ? tx_cc1_datao : 1'bz;
  assign rx_cc2_datai = tx_cc2_dataoen ? tx_cc2_datao : 1'bz;

  initial begin : gen_pclk
    hclk = 0;
    forever #`CYCLE hclk = ~hclk;
  end

  initial begin : gen_hsi_clk
    hsi_clk = 0;
    forever #`HSI_CYCLE hsi_clk = ~hsi_clk;
  end

  // Generate input data
  always @ (negedge hclk) begin
    get_randomVal(0, 255, randval);
  end

  // Main
  initial begin
    Errors = 0;
    ErrorStatus = 0;
    flag_init();
    sys_reset();
    trans_init();
    recv_init();
    tx_rx_test(8);
    // tx_rx_hrst(8);
    // tx_rx_data_hrst(8);
    // tx_rx_crst(8);
    // tx_rx_data_crst(8);
    // End of test bench
    Delay(20000);
    $display("");
    if (Errors == 1)
      $display("%t **ERROR: completed with 1 error! *_*  ", $realtime);
    else if (Errors)
      $display("%t **ERROR: completed with %d errors!!! *_*  ", $realtime, Errors);
    else
      $display("%t INFO: Simulation is completed without errors, ^_^ ^_^ ", $realtime);
    #(`CYCLE*15000);
    $finish;
  end

  `ifdef FSDB_ON
    initial begin
      $fsdbDumpfile ( "./ucpd_top.fsdb" );
      $fsdbDumpvars;
    end
  `endif

endmodule



