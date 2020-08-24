
  `define FSDB_ON
  //`define DEBUG_ON
  `define DEBUG_IRQ_ON

  // `define RANDOM
  `define DEL 1
  // `define VERBOSE
  `define TOP top_tb
  `define CYCLE  25
  `define HSI_CYCLE  62

  parameter BASE_ADDR = 32'h5000;

  parameter CFG1       = 8'h00;
  parameter CFG2       = 8'h04;
  // address 8'h08 is Reserved
  parameter CR         = 8'h0c;
  parameter IMR        = 8'h10;
  parameter SR         = 8'h14;
  parameter ICR        = 8'h18;
  parameter TX_ORDSET  = 8'h1c;
  parameter TX_PAYSZ   = 8'h20;
  parameter TXDR       = 8'h24;
  parameter RX_ORDSET  = 8'h28;
  parameter RX_PAYSZ   = 8'h2c;
  parameter RXDR       = 8'h30;
  parameter RX_ORDEXT1 = 8'h34;
  parameter RX_ORDEXT2 = 8'h38;

  parameter UCPD_CFG1       = BASE_ADDR + CFG1      ;
  parameter UCPD_CFG2       = BASE_ADDR + CFG2      ;
  parameter UCPD_CR         = BASE_ADDR + CR        ;
  parameter UCPD_IMR        = BASE_ADDR + IMR       ;
  parameter UCPD_SR         = BASE_ADDR + SR        ;
  parameter UCPD_ICR        = BASE_ADDR + ICR       ;
  parameter UCPD_TX_ORDSET  = BASE_ADDR + TX_ORDSET ;
  parameter UCPD_TX_PAYSZ   = BASE_ADDR + TX_PAYSZ  ;
  parameter UCPD_TXDR       = BASE_ADDR + TXDR      ;
  parameter UCPD_RX_ORDSET  = BASE_ADDR + RX_ORDSET ;
  parameter UCPD_RX_PAYSZ   = BASE_ADDR + RX_PAYSZ  ;
  parameter UCPD_RXDR       = BASE_ADDR + RXDR      ;
  parameter UCPD_RX_ORDEXT1 = BASE_ADDR + RX_ORDEXT1;
  parameter UCPD_RX_ORDEXT2 = BASE_ADDR + RX_ORDEXT2;


  parameter RESET     = 0       ;
  parameter SET       = 1       ;
  parameter DISABLE   = 0       ;
  parameter ENABLE    = 1       ;
  parameter SUCCESS   = 1       ;
  parameter ERROR     = 0       ;
  parameter MST       = 1       ;
  parameter SLV       = 0       ;
  parameter REG_CONST = 16'h7755;
  parameter CRC_NUM   = 5       ;
  parameter TRANS     = 1       ;
  parameter RCV       = 0       ;

  parameter SYNC_1 = 5'b11000;
  parameter SYNC_2 = 5'b10001;
  parameter SYNC_3 = 5'b00110;
  parameter RST_1  = 5'b00111;
  parameter RST_2  = 5'b11001;
  parameter EOP    = 5'b01101;

  parameter SOP = {SYNC_2,SYNC_1,SYNC_1,SYNC_1};

  // UCPD configuration register 1 (UCPD_CFG1)
  parameter HBITCLKDIV   = 32'h10 << 0; //32'h0000_0001;
  parameter IFRGAP       = 32'hD << 6 ;
  parameter TRANSWIN     = 32'h9 << 11;
  parameter PSC_USBPDCLK = 32'h1 << 17;
  parameter RXORDSETEN   = 32'h0 << 20;
  parameter TXDMAEN      = 32'h0 << 29;
  parameter RXDMAEN      = 32'h0 << 30;
  parameter UCPDEN       = 32'h1 << 31;
  parameter UCPDEN_DIS   = 32'h0 << 31;

  // UCPD configuration register 2 (UCPD_CFG2)
  parameter RXFILTDIS = 32'h1 << 0 ;
  parameter RXFILT2N3 = 32'h0 << 1 ;
  parameter FORCECLK  = 32'h0 << 2 ;
  parameter WUPEN     = 32'h0 << 13;

  parameter TXORDSET = SOP  ;
  parameter TXPAYSZ  = 5    ;
  parameter TXDATA   = 8'h55;

  // UCPD control register (UCPD_CR)
  parameter TXMODE     = 32'h1 << 0 ;
  parameter TXSEND     = 32'h1 << 2 ;
  parameter TXHRST     = 32'h1 << 3 ;
  parameter RXMODE     = 32'h0 << 4 ;
  parameter PHYRXEN    = 32'h0 << 5 ;
  parameter PHYCCSEL   = 32'h0 << 6 ;
  parameter ANASUBMODE = 32'h0 << 7 ;
  parameter ANAMODE    = 32'h0 << 9 ;
  parameter CCENABLE   = 32'h0 << 10;
  parameter FRSRXEN    = 32'h0 << 16;
  parameter FRSTX      = 32'h0 << 17;
  parameter RDCH       = 32'h0 << 18;
  parameter CC1TCDIS   = 32'h0 << 20;
  parameter CC2TCDIS   = 32'h0 << 21;

  // UCPD Interrupt Mask Register (UCPD_IMR)
  parameter TXISIE      = 32'h1 << 0 ;
  parameter TXMSGDISCIE = 32'h1 << 1 ;
  parameter TXMSGSENTIE = 32'h1 << 2 ;
  parameter TXMSGABTIE  = 32'h1 << 3 ;
  parameter HRSTDISCIE  = 32'h1 << 4 ;
  parameter HRSTSENTIE  = 32'h1 << 5 ;
  parameter TXUNDIE     = 32'h1 << 6 ;
  parameter RXNEIE      = 32'h1 << 8 ;
  parameter RXORDDETIE  = 32'h1 << 9 ;
  parameter RXHRSTDETIE = 32'h1 << 10;
  parameter RXOVRIE     = 32'h1 << 11;
  parameter RXMSGENDIE  = 32'h1 << 12;
  parameter TYPECEVT1IE = 32'h1 << 14;
  parameter TYPECEVT2IE = 32'h1 << 15;
  parameter FRSEVTIE    = 32'h1 << 20;

 // UCPD Interrupt Clear Register (UCPD_ICR)
  parameter TXMSGDISCCF_SET = 32'h1 << 1 ;
  parameter TXMSGSENTCF_SET = 32'h1 << 2 ;
  parameter TXMSGABTCF_SET  = 32'h1 << 3 ;
  parameter HRSTDISCCF_SET  = 32'h1 << 4 ;
  parameter HRSTSENTCF_SET  = 32'h1 << 5 ;
  parameter TXUNDCF_SET     = 32'h1 << 6 ;
  parameter RXORDDETCF_SET  = 32'h1 << 9 ;
  parameter RXHRSTDETCF_SET = 32'h1 << 10;
  parameter RXOVRCF_SET     = 32'h1 << 11;
  parameter RXMSGENDCF_SET  = 32'h1 << 12;
  parameter TYPECEVT1CF_SET = 32'h1 << 14;
  parameter TYPECEVT2CF_SET = 32'h1 << 15;
  parameter FRSEVTCF_SET    = 32'h1 << 20;

  parameter TXMSGDISCCF_RESET = 32'h0 << 1 ;
  parameter TXMSGSENTCF_RESET = 32'h0 << 2 ;
  parameter TXMSGABTCF_RESET  = 32'h0 << 3 ;
  parameter HRSTDISCCF_RESET  = 32'h0 << 4 ;
  parameter HRSTSENTCF_RESET  = 32'h0 << 5 ;
  parameter TXUNDCF_RESET     = 32'h0 << 6 ;
  parameter RXORDDETCF_RESET  = 32'h0 << 9 ;
  parameter RXHRSTDETCF_RESET = 32'h0 << 10;
  parameter RXOVRCF_RESET     = 32'h0 << 11;
  parameter RXMSGENDCF_RESET  = 32'h0 << 12;
  parameter TYPECEVT1CF_RESET = 32'h0 << 14;
  parameter TYPECEVT2CF_RESET = 32'h0 << 15;
  parameter FRSEVTCF_RESET    = 32'h0 << 20;



