//============================================================================
//  FileName    : ahb_slave_if.v
//  Function    : AMBA 2.0 AHB Slave interface
//                Connect the sram controller into AHB bus and generate
//                sram control signals: sram address, rd/wr operation and chip
//                select signals etc.
//  Author      : luok
//  Date        : 2020-5-4
//  Version     : 0.1
//----------------------------------------------------------------------------
//  Version     : 1.0
//  Date        : 2020-5-4
//  Description : added "default case" in case(haddr_sel) list.
//----------------------------------------------------------------------------
  `define FSMC_BCR1     8'h00
  `define FSMC_BTR1     8'h01
  `define FSMC_BCR2     8'h02
  `define FSMC_BTR2     8'h03
  `define FSMC_BCR3     8'h04
  `define FSMC_BTR3     8'h05
  `define FSMC_BCR4     8'h06
  `define FSMC_BTR4     8'h07
  `define FSMC_BWTR1    8'h41
  `define FSMC_BWTR2    8'h43
  `define FSMC_BWTR3    8'h45
  `define FSMC_BWTR4    8'h47
  `define FSMC_PCR2     8'h18
  `define FSMC_PCR3     8'h20
  `define FSMC_PCR4     8'h28
  `define FSMC_SR2      8'h19
  `define FSMC_SR3      8'h21
  `define FSMC_SR4      8'h29
  `define FSMC_PMEM2    8'h1a
  `define FSMC_PMEM3    8'h22
  `define FSMC_PMEM4    8'h2a
  `define FSMC_PATT2    8'h1b
  `define FSMC_PATT3    8'h23
  `define FSMC_PATT4    8'h2b
  `define FSMC_PIO4     8'h2c
  `define FSMC_ECCR2    8'h1d
  `define FSMC_ECCR3    8'h25

module ahb_slave_if (
  //input signals
  input             hclk            , // System clock (May be gated externally to this block)
  input             hresetn         , // System reset
  input             hsel            , // AHB slave selected
  input             hwrite          , // AHB transfer direction
  input             hready          , // AHB bus ready
  input      [ 1:0] htrans          , // AHB transaction type
  input      [ 2:0] hsize           , // AHB transfer size
  input      [31:0] hwdata          , // AHB write data bus
  input      [31:0] haddr           , // AHB transfer address
  input      [15:0] fsmc_di         ,
  input             word_1sthalf    ,
  input             word_1sthalf_clr,
  input             hreadyout_bank1 ,
  //output signals
  output            hreadyout       , // AHB slave ready
  output     [ 1:0] hresp           , // AHB response
  output     [31:0] hrdata          , // AHB read data bus
  output reg [31:0] fsmcbcr1        ,
  output reg [31:0] fsmcbtr1        ,
  output reg [31:0] fsmcbcr2        ,
  output reg [31:0] fsmcbtr2        ,
  output reg [31:0] fsmcbcr3        ,
  output reg [31:0] fsmcbtr3        ,
  output reg [31:0] fsmcbcr4        ,
  output reg [31:0] fsmcbtr4        ,
  output reg [31:0] fsmcbwtr1       ,
  output reg [31:0] fsmcbwtr2       ,
  output reg [31:0] fsmcbwtr3       ,
  output reg [31:0] fsmcbwtr4       ,
  output reg [31:0] fsmcpcr2        ,
  output reg [31:0] fsmcpcr3        ,
  output reg [31:0] fsmcpcr4        ,
  output reg [31:0] fsmcsr2         ,
  output reg [31:0] fsmcsr3         ,
  output reg [31:0] fsmcsr4         ,
  output reg [31:0] fsmcpmem2       ,
  output reg [31:0] fsmcpmem3       ,
  output reg [31:0] fsmcpmem4       ,
  output reg [31:0] fsmcpatt2       ,
  output reg [31:0] fsmcpatt3       ,
  output reg [31:0] fsmcpatt4       ,
  output reg [31:0] fsmcpio4        ,
  output reg [31:0] fsmceccr2       ,
  output reg [31:0] fsmceccr3       ,
  output reg        buf_we_en_r     ,
  output reg        tx_byte_r       ,
  output reg        tx_word_r       ,
  output            ahb_access      ,
  output     [ 3:0] fsmc_bank_sel   ,
  output reg [ 3:0] bank1_region_sel,
  output reg [27:0] buf_adr         ,
  output reg [31:0] hwdata_r
);
  //-------------------------------------------------------
  //internal registers used for temp the input ahb signals
  //-------------------------------------------------------
  //temperate all the AHB input signals
  reg        hwrite_r;
  reg [2:0]  hsize_r ;
  reg [1:0]  htrans_r;
  reg [31:0] haddr_r;

  //------------------------------------------------------
  //Internal signals
  //------------------------------------------------------
  reg ahb_write_r;
  reg tx_half_r  ;
  /*------------------------------------------------------------------------------
  --  register default value
  ------------------------------------------------------------------------------*/
  localparam FSMC_BCR1_DEF = 32'h0000_30DB;
  // x is 1-4 except FSMC_BCR1
  localparam FSMC_BCRx_DEF  = 32'h0000_30D2;
  localparam FSMC_PCRx_DEF  = 32'h0000_0018;
  localparam FSMC_SRx_DEF   = 32'h0000_0040;
  localparam FSMC_PMEMx_DEF = 32'hFCFC_FCFC;
  localparam FSMC_PATTx_DEF = 32'hFCFC_FCFC;
  localparam FSMC_PIO4_DEF  = 32'hFCFC_FCFC;
  localparam FSMC_BTRx_DEF  = 32'h0FFF_FFFF;
  localparam FSMC_BWTx_DEF  = 32'h0FFF_FFFF;

  localparam NONSEQ = 2'b10;
  localparam SEQ    = 2'b11;

  reg        hsel_ctl_r          ;
  reg        hsel_bank1_r        ;
  reg        hsel_bank2_r        ;
  reg        hsel_bank3_r        ;
  reg        hsel_bank4_r        ;
  reg        word_1sthalf_r      ;
  reg [15:0] fsmc_di_word_1sthalf;

  //---------------------------------------------------------
  //  Combinatorial portion
  //---------------------------------------------------------
  assign fsmc_bank_sel = {hsel_bank4_r, hsel_bank3_r, hsel_bank2_r, hsel_bank1_r};

  //-----------------------------------------------------------------------------
  // AHB write register address control
  //-----------------------------------------------------------------------------
  wire hsel_ctl   = hsel && (haddr[31:12] == 20'ha_0000);
  wire hsel_bank1 = hsel && (haddr[31:28] == 4'h6)      ;
  wire hsel_bank2 = hsel && (haddr[31:28] == 4'h7)      ;
  wire hsel_bank3 = hsel && (haddr[31:28] == 4'h8)      ;
  wire hsel_bank4 = hsel && (haddr[31:28] == 4'h9)      ;

  wire hwrite_en = ((htrans_r == NONSEQ) || (htrans_r == SEQ)) && hwrite_r;
  // Detect a valid write to this slave reg field
  wire hwrite_trans  = hsel_ctl_r & hwrite_en;

  // Registered HSEL
  always @(posedge hclk or negedge hresetn) begin
    if(!hresetn) begin
      hsel_ctl_r   <= 1'b0;
      hsel_bank1_r <= 1'b0;
      hsel_bank2_r <= 1'b0;
      hsel_bank3_r <= 1'b0;
      hsel_bank4_r <= 1'b0;
    end
    else if (hready) begin
      hsel_ctl_r   <= hsel_ctl  ;
      hsel_bank1_r <= hsel_bank1;
      hsel_bank2_r <= hsel_bank2;
      hsel_bank3_r <= hsel_bank3;
      hsel_bank4_r <= hsel_bank4;
    end
  end

  always@(posedge hclk or negedge hresetn) begin
    if(!hresetn) begin
      hwrite_r <= 1'b0  ;
      hsize_r  <= 3'b0  ;
      htrans_r <= 2'b0  ;
      haddr_r  <= 32'b0 ;
    end
    else if(hsel && hready) begin
      hwrite_r <= hwrite ;
      hsize_r  <= hsize  ;
      htrans_r <= htrans ;
      haddr_r  <= haddr  ;
    end else begin
      hwrite_r <= 1'b0  ;
      hsize_r  <= 3'b0  ;
      htrans_r <= 2'b0  ;
      haddr_r  <= 32'b0 ;
    end
  end

  always @(posedge hclk or negedge hresetn) begin
    if(!hresetn) begin
      fsmcbcr1  <= FSMC_BCR1_DEF;
      fsmcbtr1  <= FSMC_BTRx_DEF;
      fsmcbcr2  <= FSMC_BCRx_DEF;
      fsmcbtr2  <= FSMC_BTRx_DEF;
      fsmcbcr3  <= FSMC_BCRx_DEF;
      fsmcbtr3  <= FSMC_BTRx_DEF;
      fsmcbcr4  <= FSMC_BCRx_DEF;
      fsmcbtr4  <= FSMC_BTRx_DEF;
      fsmcbwtr1 <= FSMC_BWTx_DEF;
      fsmcbwtr2 <= FSMC_BWTx_DEF;
      fsmcbwtr3 <= FSMC_BWTx_DEF;
      fsmcbwtr4 <= FSMC_BWTx_DEF;
      fsmcpcr2  <= FSMC_PCRx_DEF;
      fsmcpcr3  <= FSMC_PCRx_DEF;
      fsmcpcr4  <= FSMC_PCRx_DEF;
      fsmcsr2   <= FSMC_SRx_DEF;
      fsmcsr3   <= FSMC_SRx_DEF;
      fsmcsr4   <= FSMC_SRx_DEF;
      fsmcpmem2 <= FSMC_PMEMx_DEF;
      fsmcpmem3 <= FSMC_PMEMx_DEF;
      fsmcpmem4 <= FSMC_PMEMx_DEF;
      fsmcpatt2 <= FSMC_PATTx_DEF;
      fsmcpatt3 <= FSMC_PATTx_DEF;
      fsmcpatt4 <= FSMC_PATTx_DEF;
      fsmcpio4  <= FSMC_PIO4_DEF;
      fsmceccr2 <= 32'd0;
      fsmceccr3 <= 32'd0;
    end
    else if (hwrite_trans) begin
      case (haddr_r[9:2])
        `FSMC_BCR1  : fsmcbcr1  <= hwdata;
        `FSMC_BTR1  : fsmcbtr1  <= hwdata;
        `FSMC_BCR2  : fsmcbcr2  <= hwdata;
        `FSMC_BTR2  : fsmcbtr2  <= hwdata;
        `FSMC_BCR3  : fsmcbcr3  <= hwdata;
        `FSMC_BTR3  : fsmcbtr3  <= hwdata;
        `FSMC_BCR4  : fsmcbcr4  <= hwdata;
        `FSMC_BTR4  : fsmcbtr4  <= hwdata;
        `FSMC_BWTR1 : fsmcbwtr1 <= hwdata;
        `FSMC_BWTR2 : fsmcbwtr2 <= hwdata;
        `FSMC_BWTR3 : fsmcbwtr3 <= hwdata;
        `FSMC_BWTR4 : fsmcbwtr4 <= hwdata;
        `FSMC_PCR2  : fsmcpcr2  <= hwdata;
        `FSMC_PCR3  : fsmcpcr3  <= hwdata;
        `FSMC_PCR4  : fsmcpcr4  <= hwdata;
        `FSMC_SR2   : fsmcsr2   <= hwdata;
        `FSMC_SR3   : fsmcsr3   <= hwdata;
        `FSMC_SR4   : fsmcsr4   <= hwdata;
        `FSMC_PMEM2 : fsmcpmem2 <= hwdata;
        `FSMC_PMEM3 : fsmcpmem3 <= hwdata;
        `FSMC_PMEM4 : fsmcpmem4 <= hwdata;
        `FSMC_PATT2 : fsmcpatt2 <= hwdata;
        `FSMC_PATT3 : fsmcpatt3 <= hwdata;
        `FSMC_PATT4 : fsmcpatt4 <= hwdata;
        `FSMC_PIO4  : fsmcpio4  <= hwdata;
        `FSMC_ECCR2 : fsmceccr2 <= hwdata;
        `FSMC_ECCR3 : fsmceccr3 <= hwdata;
      endcase
    end
  end

  //-----------------------------------------------------------------------------
  // AHB register read mux
  //-----------------------------------------------------------------------------
  reg [9:0] read_mux;

  // Drive read mux next state from word address when selected
  wire [9:0] nxt_read_mux = hsel ? haddr[9:0] : read_mux;

  always @(posedge hclk or negedge hresetn)
    if(!hresetn)
      read_mux <= 10'b0;          // Set select to input on reset
    else if(hready)               // When bus is ready:
      read_mux <= nxt_read_mux;   // assign mux select next value

  wire [31:0] hrdata0  = ((read_mux[9:2] == `FSMC_BCR1 ) ? fsmcbcr1  :
                          (read_mux[9:2] == `FSMC_BTR1 ) ? fsmcbtr1  :
                          (read_mux[9:2] == `FSMC_BCR2 ) ? fsmcbcr2  :
                          (read_mux[9:2] == `FSMC_BTR2 ) ? fsmcbtr2  :
                          (read_mux[9:2] == `FSMC_BCR3 ) ? fsmcbcr3  :
                          (read_mux[9:2] == `FSMC_BTR3 ) ? fsmcbtr3  :
                          (read_mux[9:2] == `FSMC_BCR4 ) ? fsmcbcr4  :
                          (read_mux[9:2] == `FSMC_BTR4 ) ? fsmcbtr4  :
                          (read_mux[9:2] == `FSMC_BWTR1) ? fsmcbwtr1 :
                          (read_mux[9:2] == `FSMC_BWTR2) ? fsmcbwtr2 :
                          (read_mux[9:2] == `FSMC_BWTR3) ? fsmcbwtr3 :
                          (read_mux[9:2] == `FSMC_BWTR4) ? fsmcbwtr4 : 32'd0
                         );

  //-----------------------------------------------------------------------------
  // AHB tie offs
  //-----------------------------------------------------------------------------
  wire hreadyout_ctl = 1'b1 ; // All accesses to fsmc are zero-wait
  wire hresp0        = 2'b00; // Generate OK responses only
  wire hresp1        = 2'b00; // Generate OK responses only
  wire hresp2        = 2'b00; // Generate OK responses only
  wire hresp3        = 2'b00; // Generate OK responses only
  wire hresp4        = 2'b00; // Generate OK responses only

  // ----------------------------------------------------------
  // Read/write control logic
  // ----------------------------------------------------------
  wire ahb_access1 = htrans[1] & hsel_bank1 & hready;
  wire ahb_access2 = htrans[1] & hsel_bank2 & hready;
  wire ahb_access3 = htrans[1] & hsel_bank3 & hready;
  wire ahb_access4 = htrans[1] & hsel_bank4 & hready;
  wire ahb_write  = ahb_access & hwrite;
  assign ahb_access = ahb_access1 | ahb_access2 | ahb_access3 | ahb_access4;

  always @(*) begin
    bank1_region_sel = 4'b0000;
    if(hsel_bank1_r)
      case (buf_adr[27:26])
        2'b11 : bank1_region_sel[3] = 1'b1;
        2'b10 : bank1_region_sel[2] = 1'b1;
        2'b01 : bank1_region_sel[1] = 1'b1;
        2'b00 : bank1_region_sel[0] = 1'b1;
      endcase
  end

  // ----------------------------------------------------------
  // Byte lane decoder and next state logic
  // ----------------------------------------------------------
  wire tx_byte = ~hsize[1] & ~hsize[0];
  wire tx_half = ~hsize[1] &  hsize[0];
  wire tx_word =  hsize[1]            ;

  wire byte_at_00 = tx_byte & ~haddr[1] & ~haddr[0];
  wire byte_at_01 = tx_byte & ~haddr[1] &  haddr[0];
  wire byte_at_10 = tx_byte &  haddr[1] & ~haddr[0];
  wire byte_at_11 = tx_byte &  haddr[1] &  haddr[0];

  wire half_at_00 = tx_half & ~haddr[1];
  wire half_at_10 = tx_half &  haddr[1];

  wire word_at_00 = tx_word;

  wire byte_sel_0 = word_at_00 | half_at_00 | byte_at_00;
  wire byte_sel_1 = word_at_00 | half_at_00 | byte_at_01;
  wire byte_sel_2 = word_at_00 | half_at_10 | byte_at_10;
  wire byte_sel_3 = word_at_00 | half_at_10 | byte_at_11;

  reg half_at_10_d,       half_at_00_d;
  reg byte_at_10_d,       byte_at_00_d;
  reg byte_at_11_d,       byte_at_01_d;

  always @ (posedge hclk or negedge hresetn)
    begin
      if (!hresetn)
        half_at_10_d <= 1'b0;
      else
        half_at_10_d <= half_at_10;
    end

  always @ (posedge hclk or negedge hresetn)
    begin
      if (!hresetn)
        half_at_00_d <= 1'b0;
      else
        half_at_00_d <= half_at_00;
    end

  always @ (posedge hclk or negedge hresetn)
    begin
      if (!hresetn) begin
        byte_at_00_d <= 1'b0;
        byte_at_01_d <= 1'b0;
        byte_at_10_d <= 1'b0;
        byte_at_11_d <= 1'b0;
      end
      else begin
        byte_at_00_d <= byte_at_00;
        byte_at_01_d <= byte_at_01;
        byte_at_10_d <= byte_at_10;
        byte_at_11_d <= byte_at_11;
      end
    end
  wire [31:0] hwdata_mux = byte_at_00_d ? {hwdata[ 7: 0],hwdata[ 7: 0],hwdata[ 7: 0],hwdata[ 7: 0]} :
                           byte_at_01_d ? {hwdata[15: 8],hwdata[15: 8],hwdata[15: 8],hwdata[15: 8]} :
                           byte_at_10_d ? {hwdata[23:16],hwdata[23:16],hwdata[23:16],hwdata[23:16]} :
                           byte_at_11_d ? {hwdata[31:24],hwdata[31:24],hwdata[31:24],hwdata[31:24]} :
                           half_at_00_d ? {hwdata[15:0],hwdata[15:0]} :
                           half_at_10_d ? {hwdata[31:16],hwdata[31:16]} :hwdata[31:0] ;

  always @ (posedge hclk or negedge hresetn)
    begin
      if (!hresetn)
        hwdata_r <= 32'b0;
      else if(ahb_write_r)
        hwdata_r <= hwdata_mux;
    end

  wire buf_we_en = ahb_write;

  wire word_1sthalf_rise = word_1sthalf & ~word_1sthalf_r;

  //--------------------------------------------------------
  //  Sequential portion
  //--------------------------------------------------------
  always @ (posedge hclk or negedge hresetn) begin
    if (!hresetn)
      word_1sthalf_r <= 16'b0;
    else
      word_1sthalf_r <= word_1sthalf;
  end

  always @ (posedge hclk or negedge hresetn) begin
    if (!hresetn)
      fsmc_di_word_1sthalf <= 16'b0;
    else if(word_1sthalf_rise)
      fsmc_di_word_1sthalf <= fsmc_di;
    else if(word_1sthalf_clr)
      fsmc_di_word_1sthalf <= 16'b0;
  end

  always @ (posedge hclk or negedge hresetn) begin
    if (!hresetn)
      ahb_write_r <= 1'b0;
    else if(hsel)
      ahb_write_r <= ahb_write;
  end

  always @ (posedge hclk or negedge hresetn) begin
    if (!hresetn)
      buf_adr <= 28'b0;
    else if(ahb_access)
      buf_adr <= haddr[27:0];
  end


  always @ (posedge hclk or negedge hresetn) begin
    if (!hresetn) begin
      buf_we_en_r <= 1'b0;
      tx_byte_r   <= 1'b0;
      tx_half_r   <= 1'b0;
      tx_word_r   <= 1'b0;
    end
    else if(ahb_access) begin
      buf_we_en_r <= buf_we_en;
      tx_byte_r   <= tx_byte;
      tx_half_r   <= tx_half;
      tx_word_r   <= tx_word;
    end
  end

  wire [31:0] hrdata1 = tx_word_r ? {fsmc_di, fsmc_di_word_1sthalf} : {fsmc_di, fsmc_di};

  assign hrdata     = ({32{hsel_ctl_r  }} & hrdata0) |
                      ({32{hsel_bank1_r}} & hrdata1) |
                      ({32{hsel_bank2_r}} & hrdata1) |
                      ({32{hsel_bank3_r}} & hrdata1) |
                      ({32{hsel_bank4_r}} & hrdata1);

  assign hresp      = ({2{hsel_ctl_r  }} & hresp0) |
                      ({2{hsel_bank1_r}} & hresp1) |
                      ({2{hsel_bank2_r}} & hresp2) |
                      ({2{hsel_bank3_r}} & hresp3) |
                      ({2{hsel_bank4_r}} & hresp4);

  assign hreadyout  = (hsel_ctl_r   & hreadyout_ctl  ) |
                      (hsel_bank1_r & hreadyout_bank1) |
                      (hsel_bank2_r & hreadyout_bank1) |
                      (hsel_bank3_r & hreadyout_bank1) |
                      (hsel_bank4_r & hreadyout_bank1) |
                      (~(hsel_ctl_r | hsel_bank1_r | hsel_bank2_r | hsel_bank3_r | hsel_bank4_r));

endmodule

