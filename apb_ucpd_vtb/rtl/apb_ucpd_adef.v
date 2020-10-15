`ifndef __APB_UCPD_DEF_H__
  `define __APB_UCPD_DEF_H__

  `define TX_PREAMBLE    32
  `define RX_PRE_EDG     97
  `define PRE_BIT_NUM    63
  `define SOP_BIT_NUM    19
  `define CRC_BIT_NUM    39
  `define SOP_HBYTE_NUM  4
  `define TX_BIT5_NUM    4
  `define RX_BIT5_NUM    4
  `define TX_BIT10_NUM   9
  `define SYNC_1         5'b11000
  `define SYNC_2         5'b10001
  `define SYNC_3         5'b00110
  `define RST_1          5'b00111
  `define RST_2          5'b11001
  `define EOP            5'b01101

`endif

