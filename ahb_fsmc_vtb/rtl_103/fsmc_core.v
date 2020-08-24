// -----------------------------------------------------------------------------
// Copyright (c) 2014-2020 All rights reserved
// -----------------------------------------------------------------------------
// Author : luok
// File   : fsmc_core.v
// Create : 2020-05-24 16:32:50
// Revise : 2020-08-05 15:08:49
// Editor : sublime text3, tab size (2)
// -----------------------------------------------------------------------------

module fsmc_core (
  //input signals
  input         hclk            ,
  input         hresetn         ,
  input  [31:0] fsmcbcr1        ,
  input  [31:0] fsmcbtr1        ,
  input  [31:0] fsmcbcr2        ,
  input  [31:0] fsmcbtr2        ,
  input  [31:0] fsmcbcr3        ,
  input  [31:0] fsmcbtr3        ,
  input  [31:0] fsmcbcr4        ,
  input  [31:0] fsmcbtr4        ,
  input  [31:0] fsmcbwtr1       ,
  input  [31:0] fsmcbwtr2       ,
  input  [31:0] fsmcbwtr3       ,
  input  [31:0] fsmcbwtr4       ,
  input  [31:0] fsmcpcr2        ,
  input  [31:0] fsmcpcr3        ,
  input  [31:0] fsmcpcr4        ,
  input  [31:0] fsmcsr2         ,
  input  [31:0] fsmcsr3         ,
  input  [31:0] fsmcsr4         ,
  input  [31:0] fsmcpmem2       ,
  input  [31:0] fsmcpmem3       ,
  input  [31:0] fsmcpmem4       ,
  input  [31:0] fsmcpatt2       ,
  input  [31:0] fsmcpatt3       ,
  input  [31:0] fsmcpatt4       ,
  input  [31:0] fsmcpio4        ,
  input  [31:0] fsmceccr2       ,
  input  [31:0] fsmceccr3       ,
  input         buf_we_en_r     ,
  input         tx_byte_r       ,
  input         tx_word_r       ,
  input         ahb_access      ,
  input         fsmc_nwait      , // wait state input
  input  [ 3:0] bank1_region_sel,
  input  [ 3:0] fsmc_bank_sel   ,
  input  [27:0] buf_adr         ,
  input  [31:0] hwdata_r        ,
  //output signals
  output        hreadyout_bank1 ,
  output        word_1sthalf    ,
  output        word_1sthalf_clr,
  output [25:0] fsmc_a          ,
  output [15:0] fsmc_do         ,
  output [15:0] fsmc_doen       ,
  output        fsmc_noe        , // Output enable, active low
  output        fsmc_nwe        , // Write enable, active low
  output [ 4:1] fsmc_ne         , // Bank SEL, active low
  output        fsmc_nl         , // Latch, active low
  output [ 1:0] fsmc_nbl        , // Upper/Low byte, active low
  output        fsmc_clk
);

  localparam DLY_2HCLK = 1;

  //--------------------------------------------------------
  //  FSM state machine define
  //--------------------------------------------------------
  localparam IDLE        = 4'b0000;
  localparam BUSTURN1_R  = 4'b0001;
  localparam BUSTURN2_R  = 4'b0010;
  localparam ADDSET1     = 4'b0011;
  localparam DATATST1_W  = 4'b0100;
  localparam DATATST1_R  = 4'b0101;
  localparam ADDHLD1     = 4'b0110;
  localparam DATATST1_WF = 4'b0111;
  localparam ADDSET2     = 4'b1000;
  localparam DATATST2_W  = 4'b1001;
  localparam DATATST2_R  = 4'b1010;
  localparam ADDHLD2     = 4'b1011;
  localparam DATATST2_WF = 4'b1100;
  localparam DATAHLD1_R  = 4'b1101;
  localparam DATAHLD2_R  = 4'b1110;

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
  reg       bsturn_en ;

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
                   (bank1_region_sel == 4'b1000) ? ~(extmod4 | mtyp4[1]) & ~muxen4 : 1'b0;

  wire modea_s   = (bank1_region_sel == 4'b0001) ? extmod1 & (accmod1 == 2'b00) & ~mtyp1[1] & ~muxen1 :
                   (bank1_region_sel == 4'b0010) ? extmod2 & (accmod2 == 2'b00) & ~mtyp2[1] & ~muxen2 :
                   (bank1_region_sel == 4'b0100) ? extmod3 & (accmod3 == 2'b00) & ~mtyp3[1] & ~muxen3 :
                   (bank1_region_sel == 4'b1000) ? extmod4 & (accmod4 == 2'b00) & ~mtyp4[1] & ~muxen4 : 1'b0;

  wire modea_ws  = (bank1_region_sel == 4'b0001) ? extmod1 & (accmod_w1 == 2'b00) & ~mtyp1[1] & ~muxen1 :
                   (bank1_region_sel == 4'b0010) ? extmod2 & (accmod_w2 == 2'b00) & ~mtyp2[1] & ~muxen2 :
                   (bank1_region_sel == 4'b0100) ? extmod3 & (accmod_w3 == 2'b00) & ~mtyp3[1] & ~muxen3 :
                   (bank1_region_sel == 4'b1000) ? extmod4 & (accmod_w4 == 2'b00) & ~mtyp4[1] & ~muxen4 : 1'b0;

  wire mode2_s   = (bank1_region_sel == 4'b0001) ? ~extmod1 & mtyp1[1] & ~muxen1 & faccen1 :
                   (bank1_region_sel == 4'b0010) ? ~extmod2 & mtyp2[1] & ~muxen2 & faccen2 :
                   (bank1_region_sel == 4'b0100) ? ~extmod3 & mtyp3[1] & ~muxen3 & faccen3 :
                   (bank1_region_sel == 4'b1000) ? ~extmod4 & mtyp4[1] & ~muxen4 & faccen4 : 1'b0;

  wire modeb_s   = (bank1_region_sel == 4'b0001) ? extmod1 & (accmod1 == 2'b01) & mtyp1[1] & ~muxen1 & faccen1 :
                   (bank1_region_sel == 4'b0010) ? extmod2 & (accmod2 == 2'b01) & mtyp2[1] & ~muxen2 & faccen2 :
                   (bank1_region_sel == 4'b0100) ? extmod3 & (accmod3 == 2'b01) & mtyp3[1] & ~muxen3 & faccen3 :
                   (bank1_region_sel == 4'b1000) ? extmod4 & (accmod4 == 2'b01) & mtyp4[1] & ~muxen4 & faccen4 : 1'b0;

  wire modeb_ws  = (bank1_region_sel == 4'b0001) ? extmod1 & (accmod_w1 == 2'b01) & mtyp1[1] & ~muxen1 & faccen1 :
                   (bank1_region_sel == 4'b0010) ? extmod2 & (accmod_w2 == 2'b01) & mtyp2[1] & ~muxen2 & faccen2 :
                   (bank1_region_sel == 4'b0100) ? extmod3 & (accmod_w3 == 2'b01) & mtyp3[1] & ~muxen3 & faccen3 :
                   (bank1_region_sel == 4'b1000) ? extmod4 & (accmod_w4 == 2'b01) & mtyp4[1] & ~muxen4 & faccen4 : 1'b0;

  wire modemux_s = (bank1_region_sel == 4'b0001) ? muxen1 & ~extmod1 & (accmod1 == 2'b00) & mtyp1[1] & faccen1 :
                   (bank1_region_sel == 4'b0010) ? muxen2 & ~extmod2 & (accmod2 == 2'b00) & mtyp2[1] & faccen2 :
                   (bank1_region_sel == 4'b0100) ? muxen3 & ~extmod3 & (accmod3 == 2'b00) & mtyp3[1] & faccen3 :
                   (bank1_region_sel == 4'b1000) ? muxen4 & ~extmod4 & (accmod4 == 2'b00) & mtyp4[1] & faccen4 : 1'b0;

  wire modec_s   = (bank1_region_sel == 4'b0001) ? extmod1 & (accmod1 ==2'b10) & mtyp1[1] & ~muxen1 & faccen1 :
                   (bank1_region_sel == 4'b0010) ? extmod2 & (accmod2 ==2'b10) & mtyp2[1] & ~muxen2 & faccen2 :
                   (bank1_region_sel == 4'b0100) ? extmod3 & (accmod3 ==2'b10) & mtyp3[1] & ~muxen3 & faccen3 :
                   (bank1_region_sel == 4'b1000) ? extmod4 & (accmod4 ==2'b10) & mtyp4[1] & ~muxen4 & faccen4 : 1'b0;

  wire modec_ws  = (bank1_region_sel == 4'b0001) ? extmod1 & (accmod_w1 ==2'b10) & mtyp1[1] & ~muxen1 & faccen1 :
                   (bank1_region_sel == 4'b0010) ? extmod2 & (accmod_w2 ==2'b10) & mtyp2[1] & ~muxen2 & faccen2 :
                   (bank1_region_sel == 4'b0100) ? extmod3 & (accmod_w3 ==2'b10) & mtyp3[1] & ~muxen3 & faccen3 :
                   (bank1_region_sel == 4'b1000) ? extmod4 & (accmod_w4 ==2'b10) & mtyp4[1] & ~muxen4 & faccen4 : 1'b0;

  wire moded_s   = (bank1_region_sel == 4'b0001) ? extmod1 & (accmod1 ==2'b11) :
                   (bank1_region_sel == 4'b0010) ? extmod2 & (accmod2 ==2'b11) :
                   (bank1_region_sel == 4'b0100) ? extmod3 & (accmod3 ==2'b11) :
                   (bank1_region_sel == 4'b1000) ? extmod4 & (accmod4 ==2'b11) : 1'b0;

  wire moded_ws  = (bank1_region_sel == 4'b0001) ? extmod1 & (accmod_w1 ==2'b11) :
                   (bank1_region_sel == 4'b0010) ? extmod2 & (accmod_w2 ==2'b11) :
                   (bank1_region_sel == 4'b0100) ? extmod3 & (accmod_w3 ==2'b11) :
                   (bank1_region_sel == 4'b1000) ? extmod4 & (accmod_w4 ==2'b11) : 1'b0;

  wire [3:0] addset_s  = ( bank1_region_sel == 4'b0001 ) ? addset1 :
                         ( bank1_region_sel == 4'b0010 ) ? addset2 :
                         ( bank1_region_sel == 4'b0100 ) ? addset3 :
                         ( bank1_region_sel == 4'b1000 ) ? addset4 : 4'b0;

  wire [3:0] addhld_s  = ( bank1_region_sel == 4'b0001 ) ? addhld1 :
                         ( bank1_region_sel == 4'b0010 ) ? addhld2 :
                         ( bank1_region_sel == 4'b0100 ) ? addhld3 :
                         ( bank1_region_sel == 4'b1000 ) ? addhld4 : 4'b0;

  wire [7:0] datast_s  = ( bank1_region_sel == 4'b0001 ) ? datast1 :
                         ( bank1_region_sel == 4'b0010 ) ? datast2 :
                         ( bank1_region_sel == 4'b0100 ) ? datast3 :
                         ( bank1_region_sel == 4'b1000 ) ? datast4 : 8'b0;

  wire [3:0] addset_ws = ( bank1_region_sel == 4'b0001 ) ? addset_w1 :
                         ( bank1_region_sel == 4'b0010 ) ? addset_w2 :
                         ( bank1_region_sel == 4'b0100 ) ? addset_w3 :
                         ( bank1_region_sel == 4'b1000 ) ? addset_w4 : 4'b0;

  wire [3:0] addhld_ws = ( bank1_region_sel == 4'b0001 ) ? addhld_w1 :
                         ( bank1_region_sel == 4'b0010 ) ? addhld_w2 :
                         ( bank1_region_sel == 4'b0100 ) ? addhld_w3 :
                         ( bank1_region_sel == 4'b1000 ) ? addhld_w4 : 4'b0;

  wire [7:0] datast_ws = ( bank1_region_sel == 4'b0001 ) ? datast_w1 :
                         ( bank1_region_sel == 4'b0010 ) ? datast_w2 :
                         ( bank1_region_sel == 4'b0100 ) ? datast_w3 :
                         ( bank1_region_sel == 4'b1000 ) ? datast_w4 : 8'b0;

  wire [3:0] bsturn_s = ( bank1_region_sel == 4'b0001 ) ? busturn1 :
                        ( bank1_region_sel == 4'b0010 ) ? busturn2 :
                        ( bank1_region_sel == 4'b0100 ) ? busturn3 :
                        ( bank1_region_sel == 4'b1000 ) ? busturn4 : 4'b0;

  wire  mbken_s       = ( bank1_region_sel == 4'b0001 ) ? mbken1 :
                        ( bank1_region_sel == 4'b0010 ) ? mbken2 :
                        ( bank1_region_sel == 4'b0100 ) ? mbken3 :
                        ( bank1_region_sel == 4'b1000 ) ? mbken4 : 1'b0;

  wire wren_s         = ( bank1_region_sel == 4'b0001 ) ? wren1 :
                        ( bank1_region_sel == 4'b0010 ) ? wren2 :
                        ( bank1_region_sel == 4'b0100 ) ? wren3 :
                        ( bank1_region_sel == 4'b1000 ) ? wren4 : 1'b0;

  wire [1:0] mtyp_s   = ( bank1_region_sel == 4'b0001 ) ? mtyp1 :
                        ( bank1_region_sel == 4'b0010 ) ? mtyp2 :
                        ( bank1_region_sel == 4'b0100 ) ? mtyp3 :
                        ( bank1_region_sel == 4'b1000 ) ? mtyp4 : 2'b0;

  wire [1:0] mwid_s   = ( bank1_region_sel == 4'b0001 ) ? mwid1 :
                        ( bank1_region_sel == 4'b0010 ) ? mwid2 :
                        ( bank1_region_sel == 4'b0100 ) ? mwid3 :
                        ( bank1_region_sel == 4'b1000 ) ? mwid4 : 2'b0;

  wire  extmod_s      = ( bank1_region_sel == 4'b0001 ) ? extmod1 :
                        ( bank1_region_sel == 4'b0010 ) ? extmod2 :
                        ( bank1_region_sel == 4'b0100 ) ? extmod3 :
                        ( bank1_region_sel == 4'b1000 ) ? extmod4 : 1'b0;

  wire asynwait_s     = ( bank1_region_sel == 4'b0001 ) ? asynwait1 :
                        ( bank1_region_sel == 4'b0010 ) ? asynwait2 :
                        ( bank1_region_sel == 4'b0100 ) ? asynwait3 :
                        ( bank1_region_sel == 4'b1000 ) ? asynwait4 : 1'b0;

  wire waitpol_s      = ( bank1_region_sel == 4'b0001 ) ? waitpol1 :
                        ( bank1_region_sel == 4'b0010 ) ? waitpol2 :
                        ( bank1_region_sel == 4'b0100 ) ? waitpol3 :
                        ( bank1_region_sel == 4'b1000 ) ? waitpol4 : 1'b0;

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
  assign datahld_clr  = (~fsmc_wr_en) ? (datahld_cnt == DLY_2HCLK) : 1'b0;
  assign datahld_add  = (~fsmc_wr_en) ? (datahld_cnt < DLY_2HCLK) : 1'b0;
  assign busturn_clr  = bsturn_s == busturn_cnt;
  assign busturn_add  = bsturn_s >  busturn_cnt;

  always @(posedge hclk or negedge hresetn) begin
    if(~hresetn)
      bsturn_en <= 1'b0;
    else if(modemux_s) begin
      if(datahld_clr && ~fsmc_wr_en)
        bsturn_en <= 1'b1;
      else if(busturn_clr || fsmc_wr_en)
        bsturn_en <= 1'b0;
    end
  end

  always @ (posedge hclk or negedge hresetn) begin
    if (!hresetn)
      busturn_cnt <= 4'd0;
    else if((current_state == BUSTURN1_R || current_state == BUSTURN2_R) && busturn_add && modemux_s)
      busturn_cnt <= busturn_cnt+1;
    else
      busturn_cnt <= 4'd0;
  end

  always @ (posedge hclk or negedge hresetn) begin
    if (!hresetn)
      datahld_cnt <= 2'd0;
    else if((current_state == DATAHLD1_R || current_state == DATAHLD2_R) && datahld_add)
      datahld_cnt <= datahld_cnt+1;
    else
      datahld_cnt <= 2'd0;
  end

  always @ (posedge hclk or negedge hresetn) begin
    if (!hresetn)
      addset1_cnt <= 4'd0;
    else if((current_state == ADDSET1 || current_state == ADDSET2) && addset1_add)
      addset1_cnt <= addset1_cnt+1;
    else
      addset1_cnt <= 4'd0;
  end

  always @ (posedge hclk or negedge hresetn) begin
    if (!hresetn)
      addhld1_cnt <= 4'd0;
    else if((current_state == ADDHLD1 || current_state == ADDHLD2) && addhld1_add)
      addhld1_cnt <= addhld1_cnt+1;
    else
      addhld1_cnt <= 4'd0;
  end

  // always @ (posedge hclk or negedge hresetn) begin
  //   if (!hresetn) begin
  //     if(fsmc_wr_en)
  //       datast1_cnt <= 8'd1;
  //     else
  //       datast1_cnt <= 8'd0;
  //   end
  //   else if((current_state == DATATST1_W || current_state == DATATST1_R ||
  //            current_state == DATATST2_W || current_state == DATATST2_R) && datast1_add)
  //     datast1_cnt <= datast1_cnt+1;
  //   else begin
  //     if(fsmc_wr_en)
  //       datast1_cnt <= 8'd1;
  //     else
  //       datast1_cnt <= 8'd0;
  //   end
  // end

  always @ (posedge hclk or negedge hresetn) begin
    if (!hresetn)
      datast1_cnt <= 8'd1;
    else if((current_state == DATATST1_W || current_state == DATATST1_R ||
             current_state == DATATST2_W || current_state == DATATST2_R) && datast1_add)
      datast1_cnt <= datast1_cnt+1;
    else
      datast1_cnt <= 8'd1;
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
        default : bank1_region_sel_dly <= 4'b0;
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
        if(datast1_clr)
          next_state = DATAHLD1_R;
        else
          next_state = DATATST1_R;
      end

      DATAHLD1_R : begin
        if(datahld_clr) begin
          if(modemux_s)
              next_state = BUSTURN1_R;
          else begin
            if(tx_word_r)
              next_state = ADDSET2;
            else
              next_state = IDLE;
          end
        end
        else
          next_state = DATAHLD1_R;
      end

      DATAHLD2_R : begin
        if(datahld_clr) begin
          if(modemux_s)
            next_state = BUSTURN2_R;
          else
            next_state = IDLE;
        end
        else
          next_state = DATAHLD2_R;
      end

      BUSTURN1_R : begin
        if(busturn_clr) begin
          if(tx_word_r)
            next_state = ADDSET2;
          else
            next_state = IDLE;
        end
        else
          next_state = BUSTURN1_R;
      end

      BUSTURN2_R : begin
        if(busturn_clr)
          next_state = IDLE;
        else
          next_state = BUSTURN2_R;
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
          next_state = DATAHLD2_R;
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
  end

  always @(*) begin
    fsmc_nwe_r = 1'b1;
    fsmc_noe_r = 1'b1;
    if(fsmc_wr_en) begin
      fsmc_nwe_r = ~( current_state == DATATST1_W || current_state == DATATST2_W ||
                    ((current_state == ADDSET1 || current_state == ADDSET2) && (modeb_s || modeb_ws)) ||
                    ((current_state == ADDHLD1 || current_state == ADDHLD2) && modemux_s));
      fsmc_noe_r = 1'b1;
    end
    else begin
      if(current_state != IDLE) begin
        if(modea_s | modec_s | moded_s | modemux_s)
          fsmc_noe_r = ~(current_state == DATATST1_R || current_state == DATATST2_R  ||
                         current_state == DATAHLD1_R || current_state == DATAHLD2_R);
        else
          fsmc_noe_r = ~(current_state != IDLE);
      end
      else
        fsmc_noe_r = 1'b1;
    end
  end

  always @(*) begin
    fsmc_do_r = 16'd0;
    if((modemux_s & (current_state == ADDSET1 || current_state == ADDSET2 ||
          current_state == ADDHLD1 || current_state == ADDHLD2)))
      fsmc_do_r = fsmc_a[15:0];
    else if(current_state == DATATST2_W || current_state == DATATST2_WF)
      fsmc_do_r = hwdata_r[31:16];
    else if(current_state == DATATST1_W || current_state == DATATST1_WF)
      fsmc_do_r = hwdata_r[15:0];
  end

  always @(*) begin
    if(current_state != IDLE) begin
      if(fsmc_wr_en)
        case (bank1_region_sel)
          4'b0001 : fsmc_ne_r = 4'b1110;
          4'b0010 : fsmc_ne_r = 4'b1101;
          4'b0100 : fsmc_ne_r = 4'b1011;
          4'b1000 : fsmc_ne_r = 4'b0111;
          default : fsmc_ne_r = 4'b1111;
        endcase
      else
        case (region_sel)
          4'b0001 : fsmc_ne_r = 4'b1110;
          4'b0010 : fsmc_ne_r = 4'b1101;
          4'b0100 : fsmc_ne_r = 4'b1011;
          4'b1000 : fsmc_ne_r = 4'b0111;
          default : fsmc_ne_r = 4'b1111;
        endcase
    end
    else
      fsmc_ne_r = 4'b1111;
  end

  assign buf_add_one = buf_adr[25:1] + 26'd1 ;

  assign fsmc_a[25:16] = (current_state != IDLE && current_state != BUSTURN1_R && current_state != BUSTURN2_R) ?
                         (tx_byte_r ? buf_adr[25:16] :
                         ((current_state == ADDSET2     || current_state == ADDHLD2    || current_state == DATAHLD2_R ||
                           current_state == DATATST2_WF || current_state == DATATST2_R || current_state == BUSTURN2_R ||
                           current_state == DATATST2_W) ? buf_add_one[25:16] : {1'b0, buf_adr[25:17]})) : 16'd0;

  assign fsmc_a[15:0] = (current_state != IDLE && current_state != BUSTURN1_R && current_state != BUSTURN2_R) ?
                        (tx_byte_r ? buf_adr[15:0] :
                        ((current_state == ADDSET2     || current_state == ADDHLD2    || current_state == DATAHLD2_R ||
                          current_state == DATATST2_WF || current_state == DATATST2_R || current_state == BUSTURN2_R ||
                          current_state == DATATST2_W) ? buf_add_one[15:0] : {1'b0, buf_adr[16:1]})) : 16'd0;

  assign fsmc_do = fsmc_do_r;
  assign fsmc_doen = (current_state == DATATST2_W || current_state == DATATST2_WF ||
                      current_state == DATATST1_W || current_state == DATATST1_WF ||
                      (modemux_s & (current_state == ADDSET1 || current_state == ADDSET2 ||
                       current_state == ADDHLD1 || current_state == ADDHLD2))) ? 16'hffff : 16'd0 ;

  assign avd_nl_vaild = mode2_s | modeb_s | modeb_ws | modec_s | modec_ws | moded_s | moded_ws | modemux_s;

  assign #1 fsmc_nwe = asyn_mode_vaild ? fsmc_nwe_r : 1'b1;
  assign fsmc_noe = asyn_mode_vaild ? fsmc_noe_r : 1'b1;
  assign fsmc_ne  = fsmc_ne_r;

  assign fsmc_nl  = ~(avd_nl_vaild & (current_state == ADDSET1 || current_state == ADDSET2)) ;

  assign fsmc_nbl = (current_state != IDLE) ? (tx_byte_r) ? ~{buf_adr[0], ~buf_adr[0]} : 2'b00 : 2'b11;
  assign fsmc_clk = ~(current_state == IDLE) & hclk;

  assign hreadyout_bank1 = current_state == IDLE || (~tx_word_r & (current_state == DATAHLD1_R)) || current_state == DATAHLD2_R;
                    // || current_state == BUSTURN1_R | current_state == BUSTURN2_R;
  // wire hreadyout2 = current_state == IDLE || (~tx_word_r & (current_state == DATAHLD1_R)) || current_state == DATAHLD2_R;
  //                   // || current_state == BUSTURN1_R | current_state == BUSTURN2_R;
  // wire hreadyout3 = current_state == IDLE || (~tx_word_r & (current_state == DATAHLD1_R)) || current_state == DATAHLD2_R;
  //                   // || current_state == BUSTURN1_R | current_state == BUSTURN2_R;
  // wire hreadyout4 = current_state == IDLE || (~tx_word_r & (current_state == DATAHLD1_R)) || current_state == DATAHLD2_R;
                    // || current_state == BUSTURN1_R | current_state == BUSTURN2_R;

  // assign hreadyout        = {hreadyout4, hreadyout3, hreadyout2, hreadyout1};
  assign word_1sthalf     = tx_word_r & (current_state == DATAHLD1_R);
  assign word_1sthalf_clr = current_state == IDLE;

endmodule

