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
