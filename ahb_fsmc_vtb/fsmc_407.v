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
    if (!hresetn)
      hwdata_r <= 32'b0;
    else if(ahb_write_r)
      hwdata_r <= hwdata[31:0];
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

// -----------------------------------------------------------------------------
// Copyright (c) 2014-2020 All rights reserved
// -----------------------------------------------------------------------------
// Author : luok
// File   : fsmc_core.v
// Create : 2020-05-24 16:32:50
// Revise : 2020-06-22 15:17:20
// Editor : sublime text3, tab size (2)
// -----------------------------------------------------------------------------

module fsmc_core (
  //input signals
  input             hclk            ,
  input             hresetn         ,
  input      [31:0] fsmcbcr1        ,
  input      [31:0] fsmcbtr1        ,
  input      [31:0] fsmcbcr2        ,
  input      [31:0] fsmcbtr2        ,
  input      [31:0] fsmcbcr3        ,
  input      [31:0] fsmcbtr3        ,
  input      [31:0] fsmcbcr4        ,
  input      [31:0] fsmcbtr4        ,
  input      [31:0] fsmcbwtr1       ,
  input      [31:0] fsmcbwtr2       ,
  input      [31:0] fsmcbwtr3       ,
  input      [31:0] fsmcbwtr4       ,
  input      [31:0] fsmcpcr2        ,
  input      [31:0] fsmcpcr3        ,
  input      [31:0] fsmcpcr4        ,
  input      [31:0] fsmcsr2         ,
  input      [31:0] fsmcsr3         ,
  input      [31:0] fsmcsr4         ,
  input      [31:0] fsmcpmem2       ,
  input      [31:0] fsmcpmem3       ,
  input      [31:0] fsmcpmem4       ,
  input      [31:0] fsmcpatt2       ,
  input      [31:0] fsmcpatt3       ,
  input      [31:0] fsmcpatt4       ,
  input      [31:0] fsmcpio4        ,
  input      [31:0] fsmceccr2       ,
  input      [31:0] fsmceccr3       ,
  input             buf_we_en_r     ,
  input             tx_byte_r       ,
  input             tx_word_r       ,
  input             ahb_access      ,
  input             fsmc_nwait      , // wait state input
  input      [ 3:0] bank1_region_sel,
  input      [ 3:0] fsmc_bank_sel   ,
  input      [27:0] buf_adr         ,
  input      [31:0] hwdata_r        ,
  //output signals
  output            hreadyout_bank1 ,
  output            word_1sthalf    ,
  output            word_1sthalf_clr,
  output reg [25:0] fsmc_a          ,
  output reg [15:0] fsmc_do         ,
  output reg [15:0] fsmc_doen       ,
  output            fsmc_noe        , // Output enable, active low
  output            fsmc_nwe        , // Write enable, active low
  output reg [ 4:1] fsmc_ne         , // Bank SEL, active low
  output            fsmc_nl         , // Latch, active low
  output     [ 1:0] fsmc_nbl        , // Upper/Low byte, active low
  output            fsmc_clk
);

  //--------------------------------------------------------
  //  FSM state machine define
  //--------------------------------------------------------
  localparam IDLE        = 4'b0000; // 0
  localparam ADDSET1     = 4'b0001; // 1
  localparam DATATST1_W  = 4'b0010; // 2
  localparam DATATST1_R  = 4'b0011; // 3
  localparam ADDHLD1     = 4'b0100; // 4
  localparam DATATST1_WF = 4'b0101; // 5
  localparam ADDSET2     = 4'b0111; // 6
  localparam DATATST2_W  = 4'b1000; // 7
  localparam DATATST2_R  = 4'b1001; // 8
  localparam ADDHLD2     = 4'b1010; // 9
  localparam DATATST2_WF = 4'b1011; // A

  //-------------------------------------------------------
  //internal registers
  //-------------------------------------------------------
  reg [ 3:0] addset1_cnt  ;
  reg [ 3:0] addhld1_cnt  ;
  reg [ 7:0] datast1_cnt  ;
  reg [ 3:0] busturn_cnt  ;
  reg [ 1:0] datahld_cnt  ;
  reg [ 3:0] current_state;
  reg [ 3:0] next_state   ;
  reg [15:0] fsmc_do_r    ;
  reg [ 3:0] bank1_region_sel_dly;

  reg       fsmc_noe_r;
  reg       fsmc_nwe_r;
  reg [4:1] fsmc_ne_r ;

  //------------------------------------------------------
  //Internal wire signals
  //------------------------------------------------------
  wire addset1_wclr;
  wire datast1_wclr;
  wire addhld1_wclr;
  wire addset1_clr ;
  wire datast1_clr ;
  wire addhld1_clr ;
  wire addset1_wadd;
  wire datast1_wadd;
  wire addhld1_wadd;
  wire addset1_add ;
  wire datast1_add ;
  wire addhld1_add ;
  wire datahld_clr ;
  wire datahld_add ;
  wire busturn_clr ;
  wire busturn_add ;

  wire [25:0] buf_add_one    ;
  wire        fsmc_wr_en     ;
  wire        nor_acess_en   ;
  wire        asyn_mode_vaild;
  wire        avd_nl_vaild   ;
  wire [ 3:0] bank_sel       ;

  /*------------------------------------------------------------------------------
  --  NOR/PSRAM control bank1 registers Bit define
  ------------------------------------------------------------------------------*/
  wire       mbken1    = fsmcbcr1[    0];
  wire       muxen1    = fsmcbcr1[    1];
  wire [1:0] mtyp1     = fsmcbcr1[ 3: 2];
  wire [1:0] mwid1     = fsmcbcr1[ 5: 4];
  wire       faccen1   = fsmcbcr1[    6];
  wire       bursten1  = fsmcbcr1[    8];
  wire       waitpol1  = fsmcbcr1[    9];
  wire       wrapmod1  = fsmcbcr1[   10];
  wire       waitcfg1  = fsmcbcr1[   11];
  wire       wren1     = fsmcbcr1[   12];
  wire       waiten1   = fsmcbcr1[   13];
  wire       extmod1   = fsmcbcr1[   14];
  wire       asynwait1 = fsmcbcr1[   15];
  wire [1:0] cpsize1   = fsmcbcr1[18:16];
  wire       cburstrw1 = fsmcbcr1[   19];

  wire [3:0] addset1  = fsmcbtr1[ 3: 0];
  wire [3:0] addhld1  = fsmcbtr1[ 7: 4];
  wire [7:0] datast1  = fsmcbtr1[15: 8];
  wire [3:0] busturn1 = fsmcbtr1[19:16];
  wire [3:0] clkdiv1  = fsmcbtr1[23:20];
  wire [3:0] datlat1  = fsmcbtr1[27:24];
  wire [1:0] accmod1  = fsmcbtr1[29:28];

  wire [3:0] addset_w1  = fsmcbwtr1[ 3: 0];
  wire [3:0] addhld_w1  = fsmcbwtr1[ 7: 4];
  wire [7:0] datast_w1  = fsmcbwtr1[15: 8];
  wire [3:0] busturn_w1 = fsmcbwtr1[19:16];
  wire [1:0] accmod_w1  = fsmcbwtr1[29:28];

  /*------------------------------------------------------------------------------
  --  NOR/PSRAM control bank2 registers Bit define
  ------------------------------------------------------------------------------*/
  wire       mbken2    = fsmcbcr2[    0];
  wire       muxen2    = fsmcbcr2[    1];
  wire [1:0] mtyp2     = fsmcbcr2[ 3: 2];
  wire [1:0] mwid2     = fsmcbcr2[ 5: 4];
  wire       faccen2   = fsmcbcr2[    6];
  wire       bursten2  = fsmcbcr2[    8];
  wire       waitpol2  = fsmcbcr2[    9];
  wire       wrapmod2  = fsmcbcr2[   10];
  wire       waitcfg2  = fsmcbcr2[   11];
  wire       wren2     = fsmcbcr2[   12];
  wire       waiten2   = fsmcbcr2[   13];
  wire       extmod2   = fsmcbcr2[   14];
  wire       asynwait2 = fsmcbcr2[   15];
  wire [1:0] cpsize2   = fsmcbcr2[18:16];
  wire       cburstrw2 = fsmcbcr2[   19];

  wire [3:0] addset2  = fsmcbtr2[ 3: 0];
  wire [3:0] addhld2  = fsmcbtr2[ 7: 4];
  wire [7:0] datast2  = fsmcbtr2[15: 8];
  wire [3:0] busturn2 = fsmcbtr2[19:16];
  wire [3:0] clkdiv2  = fsmcbtr2[23:20];
  wire [3:0] datlat2  = fsmcbtr2[27:24];
  wire [1:0] accmod2  = fsmcbtr2[29:28];

  wire [3:0] addset_w2  = fsmcbwtr2[ 3: 0];
  wire [3:0] addhld_w2  = fsmcbwtr2[ 7: 4];
  wire [7:0] datast_w2  = fsmcbwtr2[15: 8];
  wire [3:0] busturn_w2 = fsmcbwtr2[19:16];
  wire [1:0] accmod_w2  = fsmcbwtr2[29:28];

  /*------------------------------------------------------------------------------
  --  NOR/PSRAM control bank3 registers Bit define
  ------------------------------------------------------------------------------*/
  wire       mbken3    = fsmcbcr3[    0];
  wire       muxen3    = fsmcbcr3[    1];
  wire [1:0] mtyp3     = fsmcbcr3[ 3: 2];
  wire [1:0] mwid3     = fsmcbcr3[ 5: 4];
  wire       faccen3   = fsmcbcr3[    6];
  wire       bursten3  = fsmcbcr3[    8];
  wire       waitpol3  = fsmcbcr3[    9];
  wire       wrapmod3  = fsmcbcr3[   10];
  wire       waitcfg3  = fsmcbcr3[   11];
  wire       wren3     = fsmcbcr3[   12];
  wire       waiten3   = fsmcbcr3[   13];
  wire       extmod3   = fsmcbcr3[   14];
  wire       asynwait3 = fsmcbcr3[   15];
  wire [1:0] cpsize3   = fsmcbcr3[18:16];
  wire       cburstrw3 = fsmcbcr3[   19];

  wire [3:0] addset3  = fsmcbtr3[ 3: 0];
  wire [3:0] addhld3  = fsmcbtr3[ 7: 4];
  wire [7:0] datast3  = fsmcbtr3[15: 8];
  wire [3:0] busturn3 = fsmcbtr3[19:16];
  wire [3:0] clkdiv3  = fsmcbtr3[23:20];
  wire [3:0] datlat3  = fsmcbtr3[27:24];
  wire [1:0] accmod3  = fsmcbtr3[29:28];

  wire [3:0] addset_w3  = fsmcbwtr3[ 3: 0];
  wire [3:0] addhld_w3  = fsmcbwtr3[ 7: 4];
  wire [7:0] datast_w3  = fsmcbwtr3[15: 8];
  wire [3:0] busturn_w3 = fsmcbwtr3[19:16];
  wire [1:0] accmod_w3  = fsmcbwtr3[29:28];

  /*------------------------------------------------------------------------------
  --  NOR/PSRAM control bank4 registers Bit define
  ------------------------------------------------------------------------------*/
  wire       mbken4    = fsmcbcr4[    0];
  wire       muxen4    = fsmcbcr4[    1];
  wire [1:0] mtyp4     = fsmcbcr4[ 3: 2];
  wire [1:0] mwid4     = fsmcbcr4[ 5: 4];
  wire       faccen4   = fsmcbcr4[    6];
  wire       bursten4  = fsmcbcr4[    8];
  wire       waitpol4  = fsmcbcr4[    9];
  wire       wrapmod4  = fsmcbcr4[   10];
  wire       waitcfg4  = fsmcbcr4[   11];
  wire       wren4     = fsmcbcr4[   12];
  wire       waiten4   = fsmcbcr4[   13];
  wire       extmod4   = fsmcbcr4[   14];
  wire       asynwait4 = fsmcbcr4[   15];
  wire [1:0] cpsize4   = fsmcbcr4[18:16];
  wire       cburstrw4 = fsmcbcr4[   19];

  wire [3:0] addset4  = fsmcbtr4[ 3: 0];
  wire [3:0] addhld4  = fsmcbtr4[ 7: 4];
  wire [7:0] datast4  = fsmcbtr4[15: 8];
  wire [3:0] busturn4 = fsmcbtr4[19:16];
  wire [3:0] clkdiv4  = fsmcbtr4[23:20];
  wire [3:0] datlat4  = fsmcbtr4[27:24];
  wire [1:0] accmod4  = fsmcbtr4[29:28];

  wire [3:0] addset_w4  = fsmcbwtr4[ 3: 0];
  wire [3:0] addhld_w4  = fsmcbwtr4[ 7: 4];
  wire [7:0] datast_w4  = fsmcbwtr4[15: 8];
  wire [3:0] busturn_w4 = fsmcbwtr4[19:16];
  wire [1:0] accmod_w4  = fsmcbwtr4[29:28];

  wire mode1_s   = (bank1_region_sel == 4'b0001) ? ~(extmod1 | mtyp1[1]) & ~muxen1 :
                   (bank1_region_sel == 4'b0010) ? ~(extmod2 | mtyp2[1]) & ~muxen2 :
                   (bank1_region_sel == 4'b0100) ? ~(extmod3 | mtyp3[1]) & ~muxen3 :
                   (bank1_region_sel == 4'b1000) ? ~(extmod4 | mtyp4[1]) & ~muxen4 : mode1_s;

  wire modea_s   = (bank1_region_sel == 4'b0001) ? extmod1 & (accmod1 == 2'b00) & ~mtyp1[1] & ~muxen1 :
                   (bank1_region_sel == 4'b0010) ? extmod2 & (accmod2 == 2'b00) & ~mtyp2[1] & ~muxen2 :
                   (bank1_region_sel == 4'b0100) ? extmod3 & (accmod3 == 2'b00) & ~mtyp3[1] & ~muxen3 :
                   (bank1_region_sel == 4'b1000) ? extmod4 & (accmod4 == 2'b00) & ~mtyp4[1] & ~muxen4 : modea_s;

  wire modea_ws  = (bank1_region_sel == 4'b0001) ? extmod1 & (accmod_w1 == 2'b00) & ~mtyp1[1] & ~muxen1 :
                   (bank1_region_sel == 4'b0010) ? extmod2 & (accmod_w2 == 2'b00) & ~mtyp2[1] & ~muxen2 :
                   (bank1_region_sel == 4'b0100) ? extmod3 & (accmod_w3 == 2'b00) & ~mtyp3[1] & ~muxen3 :
                   (bank1_region_sel == 4'b1000) ? extmod4 & (accmod_w4 == 2'b00) & ~mtyp4[1] & ~muxen4 : modea_ws;

  wire mode2_s   = (bank1_region_sel == 4'b0001) ? ~extmod1 & mtyp1[1] & ~muxen1 & faccen1 :
                   (bank1_region_sel == 4'b0010) ? ~extmod2 & mtyp2[1] & ~muxen2 & faccen2 :
                   (bank1_region_sel == 4'b0100) ? ~extmod3 & mtyp3[1] & ~muxen3 & faccen3 :
                   (bank1_region_sel == 4'b1000) ? ~extmod4 & mtyp4[1] & ~muxen4 & faccen4 : mode2_s;

  wire modeb_s   = (bank1_region_sel == 4'b0001) ? extmod1 & (accmod1 == 2'b01) & mtyp1[1] & ~muxen1 & faccen1 :
                   (bank1_region_sel == 4'b0010) ? extmod2 & (accmod2 == 2'b01) & mtyp2[1] & ~muxen2 & faccen2 :
                   (bank1_region_sel == 4'b0100) ? extmod3 & (accmod3 == 2'b01) & mtyp3[1] & ~muxen3 & faccen3 :
                   (bank1_region_sel == 4'b1000) ? extmod4 & (accmod4 == 2'b01) & mtyp4[1] & ~muxen4 & faccen4 : modeb_s;

  wire modeb_ws  = (bank1_region_sel == 4'b0001) ? extmod1 & (accmod_w1 == 2'b01) & mtyp1[1] & ~muxen1 & faccen1 :
                   (bank1_region_sel == 4'b0010) ? extmod2 & (accmod_w2 == 2'b01) & mtyp2[1] & ~muxen2 & faccen2 :
                   (bank1_region_sel == 4'b0100) ? extmod3 & (accmod_w3 == 2'b01) & mtyp3[1] & ~muxen3 & faccen3 :
                   (bank1_region_sel == 4'b1000) ? extmod4 & (accmod_w4 == 2'b01) & mtyp4[1] & ~muxen4 & faccen4 : modeb_ws;

  wire modemux_s = (bank1_region_sel == 4'b0001) ? muxen1 & ~extmod1 & (accmod1 == 2'b00) & mtyp1[1] & faccen1 :
                   (bank1_region_sel == 4'b0010) ? muxen2 & ~extmod2 & (accmod2 == 2'b00) & mtyp2[1] & faccen2 :
                   (bank1_region_sel == 4'b0100) ? muxen3 & ~extmod3 & (accmod3 == 2'b00) & mtyp3[1] & faccen3 :
                   (bank1_region_sel == 4'b1000) ? muxen4 & ~extmod4 & (accmod4 == 2'b00) & mtyp4[1] & faccen4 : modemux_s;

  wire modec_s   = (bank1_region_sel == 4'b0001) ? extmod1 & (accmod1 ==2'b10) & mtyp1[1] & ~muxen1 & faccen1 :
                   (bank1_region_sel == 4'b0010) ? extmod2 & (accmod2 ==2'b10) & mtyp2[1] & ~muxen2 & faccen2 :
                   (bank1_region_sel == 4'b0100) ? extmod3 & (accmod3 ==2'b10) & mtyp3[1] & ~muxen3 & faccen3 :
                   (bank1_region_sel == 4'b1000) ? extmod4 & (accmod4 ==2'b10) & mtyp4[1] & ~muxen4 & faccen4 : modec_s;

  wire modec_ws  = (bank1_region_sel == 4'b0001) ? extmod1 & (accmod_w1 ==2'b10) & mtyp1[1] & ~muxen1 & faccen1 :
                   (bank1_region_sel == 4'b0010) ? extmod2 & (accmod_w2 ==2'b10) & mtyp2[1] & ~muxen2 & faccen2 :
                   (bank1_region_sel == 4'b0100) ? extmod3 & (accmod_w3 ==2'b10) & mtyp3[1] & ~muxen3 & faccen3 :
                   (bank1_region_sel == 4'b1000) ? extmod4 & (accmod_w4 ==2'b10) & mtyp4[1] & ~muxen4 & faccen4 : modec_ws;

  wire moded_s   = (bank1_region_sel == 4'b0001) ? extmod1 & (accmod1 ==2'b11) :
                   (bank1_region_sel == 4'b0010) ? extmod2 & (accmod2 ==2'b11) :
                   (bank1_region_sel == 4'b0100) ? extmod3 & (accmod3 ==2'b11) :
                   (bank1_region_sel == 4'b1000) ? extmod4 & (accmod4 ==2'b11) : moded_s;

  wire moded_ws  = (bank1_region_sel == 4'b0001) ? extmod1 & (accmod_w1 ==2'b11) :
                   (bank1_region_sel == 4'b0010) ? extmod2 & (accmod_w2 ==2'b11) :
                   (bank1_region_sel == 4'b0100) ? extmod3 & (accmod_w3 ==2'b11) :
                   (bank1_region_sel == 4'b1000) ? extmod4 & (accmod_w4 ==2'b11) : moded_ws;

  wire [3:0] addset_s  = ( bank1_region_sel == 4'b0001 ) ? addset1 :
                         ( bank1_region_sel == 4'b0010 ) ? addset2 :
                         ( bank1_region_sel == 4'b0100 ) ? addset3 :
                         ( bank1_region_sel == 4'b1000 ) ? addset4 : addset_s;

  wire [3:0] addhld_s  = ( bank1_region_sel == 4'b0001 ) ? addhld1 :
                         ( bank1_region_sel == 4'b0010 ) ? addhld2 :
                         ( bank1_region_sel == 4'b0100 ) ? addhld3 :
                         ( bank1_region_sel == 4'b1000 ) ? addhld4 : addhld_s;

  wire [7:0] datast_s  = ( bank1_region_sel == 4'b0001 ) ? datast1 :
                         ( bank1_region_sel == 4'b0010 ) ? datast2 :
                         ( bank1_region_sel == 4'b0100 ) ? datast3 :
                         ( bank1_region_sel == 4'b1000 ) ? datast4 : datast_s;

  wire [3:0] addset_ws = ( bank1_region_sel == 4'b0001 ) ? addset_w1 :
                         ( bank1_region_sel == 4'b0010 ) ? addset_w2 :
                         ( bank1_region_sel == 4'b0100 ) ? addset_w3 :
                         ( bank1_region_sel == 4'b1000 ) ? addset_w4 : addset_ws;

  wire [3:0] addhld_ws = ( bank1_region_sel == 4'b0001 ) ? addhld_w1 :
                         ( bank1_region_sel == 4'b0010 ) ? addhld_w2 :
                         ( bank1_region_sel == 4'b0100 ) ? addhld_w3 :
                         ( bank1_region_sel == 4'b1000 ) ? addhld_w4 : addhld_ws;

  wire [7:0] datast_ws = ( bank1_region_sel == 4'b0001 ) ? datast_w1 :
                         ( bank1_region_sel == 4'b0010 ) ? datast_w2 :
                         ( bank1_region_sel == 4'b0100 ) ? datast_w3 :
                         ( bank1_region_sel == 4'b1000 ) ? datast_w4 : datast_ws;

  wire [3:0] bsturn_s = ( bank1_region_sel == 4'b0001 ) ? busturn1 :
                        ( bank1_region_sel == 4'b0010 ) ? busturn2 :
                        ( bank1_region_sel == 4'b0100 ) ? busturn3 :
                        ( bank1_region_sel == 4'b1000 ) ? busturn4 : bsturn_s;

  wire  mbken_s       = ( bank1_region_sel == 4'b0001 ) ? mbken1 :
                        ( bank1_region_sel == 4'b0010 ) ? mbken2 :
                        ( bank1_region_sel == 4'b0100 ) ? mbken3 :
                        ( bank1_region_sel == 4'b1000 ) ? mbken4 : mbken_s;

  wire wren_s         = ( bank1_region_sel == 4'b0001 ) ? wren1 :
                        ( bank1_region_sel == 4'b0010 ) ? wren2 :
                        ( bank1_region_sel == 4'b0100 ) ? wren3 :
                        ( bank1_region_sel == 4'b1000 ) ? wren4 : wren_s;

  wire [1:0] mtyp_s   = ( bank1_region_sel == 4'b0001 ) ? mtyp1 :
                        ( bank1_region_sel == 4'b0010 ) ? mtyp2 :
                        ( bank1_region_sel == 4'b0100 ) ? mtyp3 :
                        ( bank1_region_sel == 4'b1000 ) ? mtyp4 : mtyp_s;

  wire [1:0] mwid_s   = ( bank1_region_sel == 4'b0001 ) ? mwid1 :
                        ( bank1_region_sel == 4'b0010 ) ? mwid2 :
                        ( bank1_region_sel == 4'b0100 ) ? mwid3 :
                        ( bank1_region_sel == 4'b1000 ) ? mwid4 : mwid_s;

  wire  extmod_s      = ( bank1_region_sel == 4'b0001 ) ? extmod1 :
                        ( bank1_region_sel == 4'b0010 ) ? extmod2 :
                        ( bank1_region_sel == 4'b0100 ) ? extmod3 :
                        ( bank1_region_sel == 4'b1000 ) ? extmod4 : extmod_s;

  wire asynwait_s     = ( bank1_region_sel == 4'b0001 ) ? asynwait1 :
                        ( bank1_region_sel == 4'b0010 ) ? asynwait2 :
                        ( bank1_region_sel == 4'b0100 ) ? asynwait3 :
                        ( bank1_region_sel == 4'b1000 ) ? asynwait4 : asynwait_s;

  wire waitpol_s      = ( bank1_region_sel == 4'b0001 ) ? waitpol1 :
                        ( bank1_region_sel == 4'b0010 ) ? waitpol2 :
                        ( bank1_region_sel == 4'b0100 ) ? waitpol3 :
                        ( bank1_region_sel == 4'b1000 ) ? waitpol4 : waitpol_s;

  wire wait_vaild = asynwait_s & ((waitpol_s & fsmc_nwait) | (~waitpol_s & ~fsmc_nwait));
  assign asyn_mode_vaild = mode1_s || modea_s || modea_ws || mode2_s || modeb_s || modeb_ws || modec_s ||
                           modec_ws || moded_s || moded_ws || modemux_s;
  assign fsmc_wr_en   = buf_we_en_r & wren_s;

  assign addset1_wclr = extmod_s ? (addset_ws == addset1_cnt) : (addset_s == addset1_cnt);
  assign datast1_wclr = extmod_s ? (datast_ws == datast1_cnt) : (datast_s == datast1_cnt);
  assign addhld1_wclr = extmod_s ? (addhld_ws == addhld1_cnt) : (addhld_s == addhld1_cnt);

  assign addset1_clr  = fsmc_wr_en ? addset1_wclr : (addset_s == addset1_cnt) ;
  assign datast1_clr  = fsmc_wr_en ? datast1_wclr : (datast_s == datast1_cnt) ;
  assign addhld1_clr  = fsmc_wr_en ? addhld1_wclr : (addhld_s == addhld1_cnt) ;

  assign addset1_wadd = extmod_s ? (addset_ws > addset1_cnt) : (addset_s > addset1_cnt) ;
  assign datast1_wadd = extmod_s ? (datast_ws > datast1_cnt) : (datast_s > datast1_cnt) ;
  assign addhld1_wadd = extmod_s ? (addhld_ws > addhld1_cnt) : (addhld_s > addhld1_cnt) ;

  assign addset1_add  = fsmc_wr_en ? addset1_wadd : (addset_s > addset1_cnt) ;
  assign datast1_add  = fsmc_wr_en ? datast1_wadd : (datast_s > datast1_cnt) ;
  assign addhld1_add  = fsmc_wr_en ? addhld1_wadd : (addhld_s > addhld1_cnt) ;

  always @ (posedge hclk or negedge hresetn) begin
    if (!hresetn)
      addset1_cnt <= 4'd1;
    else if((current_state == ADDSET1 || current_state == ADDSET2) && addset1_add)
      addset1_cnt <= addset1_cnt+1;
    else
      addset1_cnt <= 4'd1;
  end

  always @ (posedge hclk or negedge hresetn) begin
    if (!hresetn)
      addhld1_cnt <= 4'd1;
    else if((current_state == ADDHLD1 || current_state == ADDHLD2) && addhld1_add)
      addhld1_cnt <= addhld1_cnt+1;
    else
      addhld1_cnt <= 4'd1;
  end

  always @ (posedge hclk or negedge hresetn) begin
    if (!hresetn)
      datast1_cnt <= 4'd1;
    else if((current_state == DATATST1_W || current_state == DATATST1_R ||
             current_state == DATATST2_W || current_state == DATATST2_R) && datast1_add)
      datast1_cnt <= datast1_cnt+1;
    else
      datast1_cnt <= 4'd1;
  end

  always @(posedge hclk or negedge hresetn) begin
    if(!hresetn)
      bank1_region_sel_dly <= 4'b0;
    else
      case (bank1_region_sel)
        4'b0001 : bank1_region_sel_dly[0] <= 1'b1;
        4'b0010 : bank1_region_sel_dly[1] <= 1'b1;
        4'b0100 : bank1_region_sel_dly[2] <= 1'b1;
        4'b1000 : bank1_region_sel_dly[3] <= 1'b1;
        default : bank1_region_sel_dly    <= 4'b0;
      endcase
  end

  wire [3:0] region_sel = bank1_region_sel | bank1_region_sel_dly;

  //--------------------------------------------------------
  //  FSM state machine process
  //--------------------------------------------------------
  always @ (posedge hclk or negedge hresetn) begin
    if (!hresetn)
      current_state <= IDLE;
    else
      current_state <= next_state;
  end

  always @(*) begin
    case(current_state)
      IDLE : begin
        if(ahb_access)
          next_state = ADDSET1;
        else
          next_state = IDLE;
      end

      ADDSET1 : begin
        if(addset1_clr && mbken_s) begin
          if(moded_s | modemux_s)
            next_state = ADDHLD1;
          else
            next_state = fsmc_wr_en ? DATATST1_W : DATATST1_R;
        end
        else
          next_state = ADDSET1;
      end

      DATATST1_W : begin
        if(datast1_clr)
          next_state = DATATST1_WF;
        else
          next_state = DATATST1_W;
      end

      DATATST1_WF : begin
        if(tx_word_r)
          next_state = ADDSET2;
        else
          next_state = IDLE;
      end

      DATATST1_R : begin
        if(datast1_clr) begin
          if(tx_word_r)
            next_state = ADDSET2;
          else
            next_state = IDLE;
        end
        else
          next_state = DATATST1_R;
      end

      ADDHLD1 : begin
        if(addhld1_clr)
          next_state = fsmc_wr_en ? DATATST1_W : DATATST1_R;
        else
          next_state = ADDHLD1;
      end

      ADDSET2 : begin
        if(addset1_clr) begin
          if(moded_s | modemux_s)
            next_state = ADDHLD2;
          else
            next_state = fsmc_wr_en ? DATATST2_W : DATATST2_R;
        end
        else
          next_state = ADDSET2;
      end

      DATATST2_W : begin
        if(datast1_clr)
          next_state = DATATST2_WF;
        else
          next_state = DATATST2_W;
      end

      DATATST2_WF :
        next_state = IDLE ;

      DATATST2_R : begin
        if(datast1_clr)
          next_state = IDLE;
        else
          next_state = DATATST2_R;
      end

      ADDHLD2 : begin
        if(addhld1_clr)
          next_state = fsmc_wr_en ? DATATST2_W : DATATST2_R;
        else
          next_state = ADDHLD2;
      end

    endcase
  end// end FSM

  always @(*) begin
    if(fsmc_wr_en) begin
      fsmc_nwe_r = ~( current_state == DATATST1_W || current_state == DATATST2_W ||
                    ((current_state == ADDSET1 || current_state == ADDSET2) && (modeb_s || modeb_ws)) ||
                    ((current_state == ADDHLD1 || current_state == ADDHLD2) && modemux_s));
      fsmc_noe_r = 1'b1;
    end
    else begin
      if(current_state != IDLE) begin
        if(modea_s | modec_s | moded_s | modemux_s)
          fsmc_noe_r = ~(current_state == DATATST1_R || current_state == DATATST2_R);
        else
          fsmc_noe_r = ~(current_state != IDLE);
      end
      else
        fsmc_noe_r = 1'b1;
    end
  end

  always @(*) begin
    fsmc_do = 16'd0;
    if((modemux_s & (current_state == ADDSET1 || current_state == ADDSET2 ||
          current_state == ADDHLD1 || current_state == ADDHLD2)))
      fsmc_do = fsmc_a[15:0];
    else if(current_state == DATATST2_W || current_state == DATATST2_WF)
      fsmc_do = hwdata_r[31:16];
    else if(current_state == DATATST1_W || current_state == DATATST1_WF)
      fsmc_do = hwdata_r[15:0];
  end

  always @(*) begin
    if(current_state != IDLE) begin
      if(fsmc_wr_en)
        case (bank1_region_sel)
          4'b0001 : fsmc_ne = 4'b1110;
          4'b0010 : fsmc_ne = 4'b1101;
          4'b0100 : fsmc_ne = 4'b1011;
          4'b1000 : fsmc_ne = 4'b0111;
          default : fsmc_ne = 4'b1111;
        endcase
      else
        case (region_sel)
          4'b0001 : fsmc_ne = 4'b1110;
          4'b0010 : fsmc_ne = 4'b1101;
          4'b0100 : fsmc_ne = 4'b1011;
          4'b1000 : fsmc_ne = 4'b0111;
          default : fsmc_ne = 4'b1111;
        endcase
    end
    else
      fsmc_ne = 4'b1111;
  end

  always @(*) begin
    fsmc_a[15: 0] = 16'd0;
    fsmc_a[25:16] = 16'd0;
    if(current_state != IDLE) begin
      if(tx_byte_r) begin
        fsmc_a[15: 0] = buf_adr[15: 0];
        fsmc_a[25:16] = buf_adr[25:16];
      end
      else if(current_state == ADDSET2 || current_state == ADDHLD2 || current_state == DATATST2_WF
              || current_state == DATATST2_R || current_state == DATATST2_W) begin
        fsmc_a[15: 0] = buf_add_one[15: 0];
        fsmc_a[25:16] = buf_add_one[25:16];
      end
      else begin
        fsmc_a[15: 0] = {1'b0, buf_adr[16: 1]};
        fsmc_a[25:16] = {1'b0, buf_adr[25:17]};
      end
    end
  end

  always @(*) begin
    fsmc_doen = 16'd0;
    if(current_state == DATATST2_W || current_state == DATATST2_WF ||
       current_state == DATATST1_W || current_state == DATATST1_WF ||
      (modemux_s & (current_state == ADDSET1 || current_state == ADDSET2 ||
                    current_state == ADDHLD1 || current_state == ADDHLD2)))
       fsmc_doen = 16'hffff;
  end

  assign buf_add_one = buf_adr[25:1] + 26'd1 ;
  assign avd_nl_vaild = mode2_s | modeb_s | modeb_ws | modec_s | modec_ws | moded_s | moded_ws | modemux_s;

  assign fsmc_nwe = asyn_mode_vaild ? fsmc_nwe_r : 1'b1;
  assign fsmc_noe = asyn_mode_vaild ? fsmc_noe_r : 1'b1;

  assign fsmc_nl  = ~(avd_nl_vaild & (current_state == ADDSET1 || current_state == ADDSET2)) ;

  assign fsmc_nbl = (current_state != IDLE) ? (tx_byte_r) ? ~{buf_adr[0], ~buf_adr[0]} : 2'b00 : 2'b11;
  assign fsmc_clk = ~(current_state == IDLE) & hclk;

  assign hreadyout_bank1 = current_state == IDLE;

  assign word_1sthalf     = tx_word_r & (current_state == DATATST1_R);
  assign word_1sthalf_clr = current_state == IDLE;

endmodule

//============================================================================
//  File name   : fsmc_top.v
//  Author      : luok
//  Date        : 2020-5-4
//  Version     : 0.1
//  Function    : Memory on the chip for recoding data.
//                This module is the top level of the sram controller.
//                It contains two modules:ahb_slave_if.v,sram_core.v .
//============================================================================
module fsmc (
  input         HCLK      , // System clock (May be gated externally to this block)
  input         HRESETn   , // System reset
  input         HSEL      , // AHB slave selected
  input  [31:0] HADDR     , // AHB transfer address
  input         HWRITE    , // AHB transfer direction
  input  [ 1:0] HTRANS    , // AHB transaction type
  input  [ 2:0] HSIZE     , // AHB transfer size
  input  [31:0] HWDATA    , // AHB write data bus
  input         HREADY    , // AHB bus ready
  input         FSMC_NWAIT, // wait state input
  input  [15:0] FSMC_DI   ,
  output        HREADYOUT , // AHB slave ready
  output [ 1:0] HRESP     , // AHB response
  output [31:0] HRDATA    , // AHB read data bus
  output [25:0] FSMC_A    ,
  output [15:0] FSMC_DO   ,
  output [15:0] FSMC_DOEN ,
  output        FSMC_NOE  , // Output enable
  output        FSMC_NWE  , // Write enable
  output [ 4:1] FSMC_NE   , // Bank SEL
  output        FSMC_NL   , // Latch
  output [ 1:0] FSMC_NBL  , // Upper/Low byte
  output        FSMC_CLK
);

  wire        hclk            ;
  wire        hresetn         ;
  wire        hsel            ;
  wire        hwrite          ;
  wire        hready          ;
  wire [ 1:0] htrans          ;
  wire [ 2:0] hsize           ;
  wire [31:0] hwdata          ;
  wire [31:0] haddr           ;
  wire [15:0] fsmc_di         ;
  wire        hreadyout_bank1 ;
  wire        word_1sthalf    ;
  wire        word_1sthalf_clr;
  wire        hreadyout      ;
  wire [ 1:0] hresp           ;
  wire [31:0] hrdata          ;
  wire [31:0] fsmcbcr1        ;
  wire [31:0] fsmcbtr1        ;
  wire [31:0] fsmcbcr2        ;
  wire [31:0] fsmcbtr2        ;
  wire [31:0] fsmcbcr3        ;
  wire [31:0] fsmcbtr3        ;
  wire [31:0] fsmcbcr4        ;
  wire [31:0] fsmcbtr4        ;
  wire [31:0] fsmcbwtr1       ;
  wire [31:0] fsmcbwtr2       ;
  wire [31:0] fsmcbwtr3       ;
  wire [31:0] fsmcbwtr4       ;
  wire [31:0] fsmcpcr2        ;
  wire [31:0] fsmcpcr3        ;
  wire [31:0] fsmcpcr4        ;
  wire [31:0] fsmcsr2         ;
  wire [31:0] fsmcsr3         ;
  wire [31:0] fsmcsr4         ;
  wire [31:0] fsmcpmem2       ;
  wire [31:0] fsmcpmem3       ;
  wire [31:0] fsmcpmem4       ;
  wire [31:0] fsmcpatt2       ;
  wire [31:0] fsmcpatt3       ;
  wire [31:0] fsmcpatt4       ;
  wire [31:0] fsmcpio4        ;
  wire [31:0] fsmceccr2       ;
  wire [31:0] fsmceccr3       ;
  wire        buf_we_en_r     ;
  wire        tx_byte_r       ;
  wire        tx_word_r       ;
  wire        ahb_access      ;
  wire [ 3:0] fsmc_bank_sel   ;
  wire [ 3:0] bank1_region_sel;
  wire [31:0] hwdata_r        ;
  wire        fsmc_nwait      ;
  wire [27:0] buf_adr         ;
  wire [15:0] fsmc_do         ;
  wire [15:0] fsmc_doen       ;
  wire        fsmc_noe        ;
  wire        fsmc_nwe        ;
  wire [ 4:1] fsmc_ne         ;
  wire        fsmc_nl         ;
  wire [ 1:0] fsmc_nbl        ;
  wire        fsmc_clk        ;
  wire [25:0] fsmc_a          ;


  assign hclk        = HCLK      ;
  assign hresetn     = HRESETn   ;
  assign hsel        = HSEL      ;
  assign haddr       = HADDR     ;
  assign hwrite      = HWRITE    ;
  assign htrans      = HTRANS    ;
  assign hsize       = HSIZE     ;
  assign hwdata      = HWDATA    ;
  assign hready      = HREADY    ;
  assign fsmc_nwait  = FSMC_NWAIT;
  assign fsmc_di     = FSMC_DI   ;

  assign HREADYOUT = hreadyout;
  assign HRESP     = hresp    ;
  assign HRDATA    = hrdata   ;
  assign FSMC_A    = fsmc_a   ;
  assign FSMC_DO   = fsmc_do  ;
  assign FSMC_DOEN = fsmc_doen;
  assign FSMC_NOE  = fsmc_noe ;
  assign FSMC_NWE  = fsmc_nwe ;
  assign FSMC_NE   = fsmc_ne  ;
  assign FSMC_NL   = fsmc_nl  ;
  assign FSMC_NBL  = fsmc_nbl ;
  assign FSMC_CLK  = fsmc_clk ;

  ahb_slave_if u_ahb_slave_if (
    .hclk            (hclk            ),
    .hresetn         (hresetn         ),
    .hsel            (hsel            ),
    .hwrite          (hwrite          ),
    .hready          (hready          ),
    .htrans          (htrans          ),
    .hsize           (hsize           ),
    .hwdata          (hwdata          ),
    .haddr           (haddr           ),
    .fsmc_di         (fsmc_di         ),
    .word_1sthalf    (word_1sthalf    ),
    .word_1sthalf_clr(word_1sthalf_clr),
    .hreadyout_bank1 (hreadyout_bank1 ),
    .hreadyout       (hreadyout       ),
    .hresp           (hresp           ),
    .hrdata          (hrdata          ),
    .fsmcbcr1        (fsmcbcr1        ),
    .fsmcbtr1        (fsmcbtr1        ),
    .fsmcbcr2        (fsmcbcr2        ),
    .fsmcbtr2        (fsmcbtr2        ),
    .fsmcbcr3        (fsmcbcr3        ),
    .fsmcbtr3        (fsmcbtr3        ),
    .fsmcbcr4        (fsmcbcr4        ),
    .fsmcbtr4        (fsmcbtr4        ),
    .fsmcbwtr1       (fsmcbwtr1       ),
    .fsmcbwtr2       (fsmcbwtr2       ),
    .fsmcbwtr3       (fsmcbwtr3       ),
    .fsmcbwtr4       (fsmcbwtr4       ),
    .fsmcpcr2        (fsmcpcr2        ),
    .fsmcpcr3        (fsmcpcr3        ),
    .fsmcpcr4        (fsmcpcr4        ),
    .fsmcsr2         (fsmcsr2         ),
    .fsmcsr3         (fsmcsr3         ),
    .fsmcsr4         (fsmcsr4         ),
    .fsmcpmem2       (fsmcpmem2       ),
    .fsmcpmem3       (fsmcpmem3       ),
    .fsmcpmem4       (fsmcpmem4       ),
    .fsmcpatt2       (fsmcpatt2       ),
    .fsmcpatt3       (fsmcpatt3       ),
    .fsmcpatt4       (fsmcpatt4       ),
    .fsmcpio4        (fsmcpio4        ),
    .fsmceccr2       (fsmceccr2       ),
    .fsmceccr3       (fsmceccr3       ),
    .buf_we_en_r     (buf_we_en_r     ),
    .tx_byte_r       (tx_byte_r       ),
    .tx_word_r       (tx_word_r       ),
    .ahb_access      (ahb_access      ),
    .fsmc_bank_sel   (fsmc_bank_sel   ),
    .bank1_region_sel(bank1_region_sel),
    .buf_adr         (buf_adr         ),
    .hwdata_r        (hwdata_r        )
  );

  fsmc_core u_fsmc_core (
    .hclk            (hclk            ),
    .hresetn         (hresetn         ),
    .fsmcbcr1        (fsmcbcr1        ),
    .fsmcbtr1        (fsmcbtr1        ),
    .fsmcbcr2        (fsmcbcr2        ),
    .fsmcbtr2        (fsmcbtr2        ),
    .fsmcbcr3        (fsmcbcr3        ),
    .fsmcbtr3        (fsmcbtr3        ),
    .fsmcbcr4        (fsmcbcr4        ),
    .fsmcbtr4        (fsmcbtr4        ),
    .fsmcbwtr1       (fsmcbwtr1       ),
    .fsmcbwtr2       (fsmcbwtr2       ),
    .fsmcbwtr3       (fsmcbwtr3       ),
    .fsmcbwtr4       (fsmcbwtr4       ),
    .fsmcpcr2        (fsmcpcr2        ),
    .fsmcpcr3        (fsmcpcr3        ),
    .fsmcpcr4        (fsmcpcr4        ),
    .fsmcsr2         (fsmcsr2         ),
    .fsmcsr3         (fsmcsr3         ),
    .fsmcsr4         (fsmcsr4         ),
    .fsmcpmem2       (fsmcpmem2       ),
    .fsmcpmem3       (fsmcpmem3       ),
    .fsmcpmem4       (fsmcpmem4       ),
    .fsmcpatt2       (fsmcpatt2       ),
    .fsmcpatt3       (fsmcpatt3       ),
    .fsmcpatt4       (fsmcpatt4       ),
    .fsmcpio4        (fsmcpio4        ),
    .fsmceccr2       (fsmceccr2       ),
    .fsmceccr3       (fsmceccr3       ),
    .buf_we_en_r     (buf_we_en_r     ),
    .tx_byte_r       (tx_byte_r       ),
    .tx_word_r       (tx_word_r       ),
    .ahb_access      (ahb_access      ),
    .fsmc_nwait      (fsmc_nwait      ),
    .bank1_region_sel(bank1_region_sel),
    .fsmc_bank_sel   (fsmc_bank_sel   ),
    .buf_adr         (buf_adr         ),
    .hwdata_r        (hwdata_r        ),
    .hreadyout_bank1 (hreadyout_bank1 ),
    .word_1sthalf    (word_1sthalf    ),
    .word_1sthalf_clr(word_1sthalf_clr),
    .fsmc_a          (fsmc_a          ),
    .fsmc_do         (fsmc_do         ),
    .fsmc_doen       (fsmc_doen       ),
    .fsmc_noe        (fsmc_noe        ),
    .fsmc_nwe        (fsmc_nwe        ),
    .fsmc_ne         (fsmc_ne         ),
    .fsmc_nl         (fsmc_nl         ),
    .fsmc_nbl        (fsmc_nbl        ),
    .fsmc_clk        (fsmc_clk        )
  );


endmodule
//          finished  file  fsmc_407.v           // 
