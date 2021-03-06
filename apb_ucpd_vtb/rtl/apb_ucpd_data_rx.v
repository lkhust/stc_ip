/*
------------------------------------------------------------------------
--
-- File :                       apb_ucpd_data_rx.v
-- Author:                      luo kun
-- Date :                       $Date: 2020/07/12 $
-- Abstract: This module is used to process SW send data, and trans 4b5b Symbol Encoding,
             finially bmc encode output bit.
-- Modification History:
-- Date                 By      Version Change  Description
-- =====================================================================
-- See CVS log
-- =====================================================================
*/
module apb_ucpd_data_rx (
  input            ic_clk        , // processor clock
  input            ucpd_clk      ,
  input            ic_rst_n      , // asynchronous reset, active low
  input            rx_bit5_cmplt ,
  input            rx_bit_cmplt  ,
  input            rx_idle_en    ,
  input            rx_pre_en     ,
  input            rx_sop_en     ,
  input            rx_data_en    ,
  input            rxdr_rd       ,
  input            decode_bmc    ,
  input            crc_ok        ,
  input      [8:0] rx_ordset_en  ,
  output           rx_sop_cmplt  ,
  output     [5:0] rx_status     ,
  output     [6:0] rx_ordset     ,
  output           rxfifo_wr_en  ,
  output     [9:0] rx_paysize    ,
  output reg       hrst_vld      ,
  output reg       crst_vld      ,
  output           rx_ordset_vld ,
  output reg       eop_ok        ,
  output reg       rx_data_err   ,
  output     [7:0] rx_byte_no_crc,
  output     [7:0] rx_byte_to_crc
);

  // ----------------------------------------------------------
  // -- local registers and wires
  // ----------------------------------------------------------
  //registers
  reg [ 3:0] decode_4b           ;
  reg [ 4:0] bmc_rx_shift        ;
  reg [ 4:0] sop_k1_code         ;
  reg [ 4:0] sop_k2_code         ;
  reg [ 4:0] sop_k3_code         ;
  reg [ 4:0] sop_k4_code         ;
  reg [ 2:0] rx_sop_invld_num    ;
  reg [ 2:0] rx_ordset_det       ;
  reg [ 4:0] rx_5bits            ;
  reg [10:0] rx_5bits_cnt        ;
  reg        rx_sop_3of4         ;
  reg        rxfifo_full         ;
  reg        sop_1st_ok          ;
  reg        sop_2st_ok          ;
  reg        sop_3st_ok          ;
  reg        sop_4st_ok          ;
  reg        eop_ok_nxt          ;
  reg        sop0_vld            ;
  reg        sop1_vld            ;
  reg        sop1_deg_vld        ;
  reg        sop2_vld            ;
  reg        sop2_deg_vld        ;
  reg        sop0_vld_nxt        ;
  reg        sop1_vld_nxt        ;
  reg        sop1_deg_vld_nxt    ;
  reg        sop2_vld_nxt        ;
  reg        sop2_deg_vld_nxt    ;
  reg        crst_vld_nxt        ;
  reg        hrst_vld_nxt        ;
  reg [ 1:0] rx_sop_half_byte_cnt;
  reg [ 7:0] rx_data             ;
  reg        rx_1byte_cmplt      ;
  reg        rx_1byte_cmplt_d    ;
  reg [ 1:0] rx_hafbyte_cnt      ;
  reg [ 7:0] rx_byte_r1          ;
  reg [ 7:0] rx_byte_r2          ;
  reg [ 7:0] rx_byte_r3          ;
  reg [ 7:0] rx_byte_r4          ;
  reg [ 7:0] rx_byte             ;
  reg        rx_byte_vld         ;
  reg        rx_1byte_cmplt_red_d;
  reg        rx_bit5_cmplt_d     ;
  reg        rx_sop_en_d         ;
  reg        rx_data_en_d        ;
  reg [ 9:0] rx_byte_cnt         ;

  // wire
  wire       rx_msg_end        ;
  wire       rx_err            ;
  wire       rx_hrst_det       ;
  wire       rx_full           ;
  wire       sop_ex1_vld       ;
  wire       sop_ex2_vld       ;
  wire [7:0] rx_byte_nxt       ;
  wire [3:0] sop_num_ok_nxt    ;
  wire [7:0] rx_ordset_vld_ord ;
  wire [9:0] rx_byte_no_crc_cnt;

  // todo
  assign sop_ex1_vld = 1'b0;
  assign sop_ex2_vld = 1'b0;

  assign dec_rxbit_en       = rx_sop_en | rx_data_en;
  assign rxfifo_wr_data     = rxfifo_wr_en & rx_byte_vld;
  assign rx_paysize         = rx_byte_no_crc_cnt;
  assign rx_byte_to_crc     = rx_byte;
  assign rx_byte_no_crc_cnt = rx_byte_vld ? rx_byte_cnt-4 : 10'd0;
  assign rx_byte_no_crc     = rx_byte_vld ? rx_byte_r4 : 8'd0;
  assign rx_ovrflow         = rxfifo_full & rxfifo_wr_data & rx_data_en;
  assign rx_err             = rx_idle_en & eop_ok & ~crc_ok;
  assign rx_msg_end         = rx_idle_en & eop_ok;
  assign rx_hrst_det        = hrst_vld;
  assign rx_ordset_vld      = sop0_vld | sop1_vld | sop2_vld | sop1_deg_vld | sop2_deg_vld | crst_vld;
  assign rx_full            = rxfifo_full & rx_data_en;
  assign rx_status          = {rx_err,rx_msg_end,rx_ovrflow,rx_hrst_det,rx_ordset_vld,rx_full};
  assign rx_ordset          = {rx_sop_invld_num,rx_sop_3of4,rx_ordset_det};
  assign rx_sop_cmplt       = rx_bit5_cmplt && (rx_sop_half_byte_cnt == `SOP_HBYTE_NUM-1);
  assign rxfifo_wr_en       = rx_1byte_cmplt_d & ~rx_1byte_cmplt;
  assign rx_1byte_cmplt_red = ~rx_1byte_cmplt_d & rx_1byte_cmplt;
  assign rx_byte_nxt        = ~rx_5bits_cnt[0] ? rx_data : rx_byte;
  assign sop_num_ok_nxt     = {sop_1st_ok,sop_2st_ok,sop_3st_ok,sop_4st_ok};
  assign rx_ordset_vld_ord  = {sop_ex2_vld,sop_ex1_vld,crst_vld,sop2_deg_vld,
                               sop1_deg_vld,sop2_vld,sop1_vld,sop0_vld};

  always @(posedge ic_clk or negedge ic_rst_n)
    begin : rx_byte_dly_proc
      if(~ic_rst_n) begin
        rx_byte_r1 <= 8'b0;
        rx_byte_r2 <= 8'b0;
        rx_byte_r3 <= 8'b0;
        rx_byte_r4 <= 8'b0;
      end
      else if(rx_1byte_cmplt_red) begin
        rx_byte_r1 <= rx_byte;
        rx_byte_r2 <= rx_byte_r1;
        rx_byte_r3 <= rx_byte_r2;
        rx_byte_r4 <= rx_byte_r3;
      end
    end

  always @(posedge ic_clk or negedge ic_rst_n)
    begin : rx_byte_proc
      if(~ic_rst_n)
        rx_byte <= 8'b0;
      else
        rx_byte <= rx_byte_nxt;
    end

  always @(posedge ic_clk or negedge ic_rst_n)
    begin : rx_1byte_cmplt_d_proc
      if(~ic_rst_n)
        rx_1byte_cmplt_d <= 1'b0;
      else
        rx_1byte_cmplt_d <= rx_1byte_cmplt;
    end

  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : rx_bit5_cmplt_d_proc
      if(~ic_rst_n)
        rx_bit5_cmplt_d <= 1'b0;
      else
        rx_bit5_cmplt_d <= rx_bit5_cmplt;
    end

  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : rx_sop_en_d_proc
      if(~ic_rst_n)
        rx_sop_en_d <= 1'b0;
      else
        rx_sop_en_d <= rx_sop_en;
    end

  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : rx_data_en_d_proc
      if(~ic_rst_n)
        rx_data_en_d <= 1'b0;
      else
        rx_data_en_d <= rx_data_en;
    end

  /*------------------------------------------------------------------------------
  --  use rxfifo_wr_en signal in the rx_data phase to count the number receive data
  --  the rx_byte_cnt sent to SW means RX_PAYSZ register
  ------------------------------------------------------------------------------*/
  always @(posedge ic_clk or negedge ic_rst_n)
    begin : rx_byte_cnt_proc
      if(~ic_rst_n)
        rx_byte_cnt <= 10'b0;
      else if(rx_sop_en)
        rx_byte_cnt <= 10'b0;
      else if(rxfifo_wr_en && rx_data_en)
        rx_byte_cnt <= rx_byte_cnt+1;
    end

  always @(posedge ic_clk or negedge ic_rst_n)
    begin : rx_byte_vld_proc
      if(~ic_rst_n)
        rx_byte_vld <= 1'b0;
      else if(rx_byte_cnt >= 'd4)
        rx_byte_vld <= 1'b1;
      else
        rx_byte_vld <= 1'b0;
    end

  always @(posedge ic_clk or negedge ic_rst_n)
    begin : rx_1byte_cmplt_red_d_proc
      if(~ic_rst_n)
        rx_1byte_cmplt_red_d <= 1'b0;
      else
        rx_1byte_cmplt_red_d <= rx_1byte_cmplt_red;
    end

  /*------------------------------------------------------------------------------
  --  according rxdr read and txfifo write to generate rxfifo's status
  --  0: rxfifo empty, 1: rxfifo is not empty (RXNE)
  ------------------------------------------------------------------------------*/
  always @(posedge ic_clk or negedge ic_rst_n)
    begin : rxfifo_full_proc
      if(~ic_rst_n)
        rxfifo_full <= 1'b0;
      else if(rx_idle_en)
        rxfifo_full <= 1'b0;
      else if(rxdr_rd)
        rxfifo_full <= 1'b0;
      else if(rxfifo_wr_data)
        rxfifo_full <= 1'b1;
    end

  /*------------------------------------------------------------------------------
  --  The header is considered to be part of the payload, but CRC is not counted
  --  rx_data send to SW as rxdr value
  ------------------------------------------------------------------------------*/
  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : rx_data_proc
      if(~ic_rst_n)
        rx_data = 8'b0;
      else if(rx_data_en)
        begin
          if(rx_5bits_cnt[0])
            rx_data[3:0] = decode_4b;
          else
            rx_data[7:4] = decode_4b;
        end
    end

  /*------------------------------------------------------------------------------
  --  receive half byte data(message data, crc, `EOP) get latest from 5 bits fifo
  ------------------------------------------------------------------------------*/
  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : rx_5bits_proc
      if(~ic_rst_n)
        rx_5bits     <= 5'b0;
      else if(rx_idle_en)
        rx_5bits     <= 5'b0;
      else if(rx_data_en & rx_bit5_cmplt_d)
        rx_5bits     <= bmc_rx_shift;
    end

  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : rx_5bits_cnt_proc
      if(~ic_rst_n)
        rx_5bits_cnt <= 10'b0;
      else if(rx_idle_en)
        rx_5bits_cnt <= 10'b0;
      else if(rx_data_en & rx_bit5_cmplt)
        rx_5bits_cnt <= rx_5bits_cnt+1;
    end

  /*------------------------------------------------------------------------------
  --  count 2 half byte means one byte received, use one byte received complete to
  --  generate wrfifo status singal to infrom SW need read RXDR register
  ------------------------------------------------------------------------------*/
  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : rx_hafbyte_cnt_proc
      if(~ic_rst_n) begin
        rx_1byte_cmplt <= 1'b0;
        rx_hafbyte_cnt <= 2'b0;
      end
      else if(rx_idle_en) begin
        rx_1byte_cmplt <= 1'b0;
        rx_hafbyte_cnt <= 2'b0;
      end
      else if(rx_data_en & rx_bit5_cmplt) begin
        if(rx_hafbyte_cnt == 2'd1) begin
          rx_hafbyte_cnt <= 2'b0;
          rx_1byte_cmplt <= 1'b1;
        end
        else begin
          rx_hafbyte_cnt <= rx_hafbyte_cnt+1;
          rx_1byte_cmplt <= 1'b0;
        end
      end
    end

  /*------------------------------------------------------------------------------
  --  when rx_sop_cmplt valid registe RX_ORDSET
  ------------------------------------------------------------------------------*/
  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : rx_sop_3of4_proc
      if(~ic_rst_n) begin
        rx_sop_invld_num <= 3'd0;
        rx_sop_3of4      <= 1'd0;
      end
      else if(rx_pre_en) begin
        rx_sop_invld_num <= 3'd0;
        rx_sop_3of4      <= 1'd0;
      end
      else if(rx_data_en & rx_bit_cmplt) begin
        case(sop_num_ok_nxt)
          4'b1111 : // 0x0: No K-codes were corrupted
            begin
              rx_sop_invld_num <= 3'd0;
              rx_sop_3of4      <= 1'd0;
            end
          4'b0111 : // 0x1: First K-code was corrupted
            begin
              rx_sop_invld_num <= 3'd1;
              rx_sop_3of4      <= 1'd1;
            end
          4'b1011 : // 0x2: Second K-code was corrupted
            begin
              rx_sop_invld_num <= 3'd2;
              rx_sop_3of4      <= 1'd1;
            end
          4'b1101 : // 0x3: Third K-code was corrupted
            begin
              rx_sop_invld_num <= 3'd3;
              rx_sop_3of4      <= 1'd1;
            end
          4'b1110 : // 0x4: Fourth K-code was corrupted
            begin
              rx_sop_invld_num <= 3'd4;
              rx_sop_3of4      <= 1'd1;
            end
          default : ; // Other values: Invalid
        endcase
      end
    end

  /*------------------------------------------------------------------------------
  --  when rx_sop_cmplt valid registe RX_ORDSET(RXORDSET[2:0])
  ------------------------------------------------------------------------------*/
  wire [7:0] rx_ordset_ord;
  assign rx_ordset_ord = rx_ordset_vld_ord & rx_ordset_en;
  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : rx_ordset_det_proc
      if(~ic_rst_n)
        rx_ordset_det <= 3'd0;
      else if(rx_pre_en)
        rx_ordset_det <= 3'd0;
      else begin
        case(1'b1)
          rx_ordset_ord[0] : rx_ordset_det <= 3'd0; // 0x0: 0bxxxxxxxx1: SOP detect enabled
          rx_ordset_ord[1] : rx_ordset_det <= 3'd1; // 0x1: 0bxxxxxxx1x: SOP' detect enabled
          rx_ordset_ord[2] : rx_ordset_det <= 3'd2; // 0x2: 0bxxxxxx1xx: SOP'' detect enabled
          rx_ordset_ord[3] : rx_ordset_det <= 3'd3; // 0x3: 0bxxxxx1xxx: SOP'_Debug enabled
          rx_ordset_ord[4] : rx_ordset_det <= 3'd4; // 0x4: 0bxxxx1xxxx: SOP'_Debug enabled
          rx_ordset_ord[5] : rx_ordset_det <= 3'd5; // 0x5: 0bxxx1xxxxx: Cable Detect reset enabled
          rx_ordset_ord[6] : rx_ordset_det <= 3'd6; // 0x6: 0bx1xxxxxxx: SOP extension#1 enabled
          rx_ordset_ord[7] : rx_ordset_det <= 3'd7; // 0x7: 0b1xxxxxxxx: SOP extension#2 enabled
          default          : ;
        endcase
      end
    end

  /*------------------------------------------------------------------------------
  --   when sop received complete, we need 4 sop k code to check it
  ------------------------------------------------------------------------------*/
  always @ (posedge ucpd_clk or negedge ic_rst_n)
    begin : sop_k_code_proc
      if(~ic_rst_n) begin
        sop_k1_code <= 5'b0;
        sop_k2_code <= 5'b0;
        sop_k3_code <= 5'b0;
        sop_k4_code <= 5'b0;
      end
      else if(rx_idle_en) begin
        sop_k1_code <= 5'b0;
        sop_k2_code <= 5'b0;
        sop_k3_code <= 5'b0;
        sop_k4_code <= 5'b0;
      end
      else if(rx_bit5_cmplt_d && rx_sop_en_d) begin
        case(rx_sop_half_byte_cnt)
          2'b00 : sop_k1_code <= bmc_rx_shift;
          2'b01 : sop_k2_code <= bmc_rx_shift;
          2'b10 : sop_k3_code <= bmc_rx_shift;
          2'b11 : sop_k4_code <= bmc_rx_shift;
        endcase
      end
    end

  /*------------------------------------------------------------------------------
  --   wheather ordered set detect and Invalid number, `EOP K code detect
  ------------------------------------------------------------------------------*/
  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : sop_eop_ok_proc
      if(~ic_rst_n) begin
        sop_1st_ok <= 1'b0;
        sop_2st_ok <= 1'b0;
        sop_3st_ok <= 1'b0;
        sop_4st_ok <= 1'b0;
        eop_ok     <= 1'b0;
      end
      else if(rx_idle_en) begin
        sop_1st_ok <= 1'b0;
        sop_2st_ok <= 1'b0;
        sop_3st_ok <= 1'b0;
        sop_4st_ok <= 1'b0;
        eop_ok     <= 1'b0;
      end
      else if(rx_sop_en | rx_data_en) begin
        if(rx_5bits == `EOP)
          eop_ok <= 1'b1;
        else
          eop_ok <= 1'b0;

        case(sop_k1_code)
          `SYNC_1, `SYNC_2, `SYNC_3, `RST_1, `RST_2 : sop_1st_ok <= 1'b1;
          `EOP    : eop_ok <= 1'b1;
          default :
            begin
              sop_1st_ok <= 1'b0;
              eop_ok     <= 1'b0;
            end
        endcase

        case(sop_k2_code)
          `SYNC_1, `SYNC_2, `SYNC_3, `RST_1, `RST_2 : sop_2st_ok <= 1'b1;
          `EOP    : eop_ok <= 1'b1;
          default :
            begin
              sop_2st_ok <= 1'b0;
              eop_ok     <= 1'b0;
            end
        endcase

        case(sop_k3_code)
          `SYNC_1, `SYNC_2, `SYNC_3, `RST_1, `RST_2 : sop_3st_ok <= 1'b1;
          `EOP    : eop_ok <= 1'b1;
          default :
            begin
              sop_3st_ok <= 1'b0;
              eop_ok     <= 1'b0;
            end
        endcase

        case(sop_k4_code)
          `SYNC_1, `SYNC_2, `SYNC_3, `RST_1, `RST_2 : sop_4st_ok <= 1'b1;
          `EOP    : eop_ok <= 1'b1;
          default :
            begin
              sop_4st_ok <= 1'b0;
              eop_ok     <= 1'b0;
            end
        endcase
      end
    end

  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : rx_data_err_proc
      if(~ic_rst_n)
        rx_data_err <= 1'b0;
      else if(rx_idle_en)
        rx_data_err <= 1'b0;
      else if(rx_data_en_d) begin
        if(rx_5bits == 5'd0)
          rx_data_err <= 1'b1;
        else
          rx_data_err <= 1'b0;
      end
    end

  /*------------------------------------------------------------------------------
  --  Rx ordered set code detected
  ------------------------------------------------------------------------------*/
  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : sop_vld_prc
      if(~ic_rst_n) begin
        sop0_vld     <= 1'b0; // SOP code detected in receiver
        sop1_vld     <= 1'b0; // SOP' code detected in receiver
        sop1_deg_vld <= 1'b0; // SOP'_Debug detected in receiver
        sop2_vld     <= 1'b0; // SOP'' code detected in receiver
        sop2_deg_vld <= 1'b0; // SOP''_Debug detected in receiver
        crst_vld     <= 1'b0; // Cable Reset detected in receiver
        hrst_vld     <= 1'b0; // Hard Reset detected in receiver
      end
      else begin
        if(((sop_k1_code == `SYNC_1) & (sop_k2_code == `SYNC_1) & (sop_k3_code == `SYNC_1)) |
          ((sop_k1_code == `SYNC_1) & (sop_k2_code == `SYNC_1) & (sop_k4_code == `SYNC_2)) |
          ((sop_k1_code == `SYNC_1) & (sop_k3_code == `SYNC_1) & (sop_k4_code == `SYNC_2)) |
          ((sop_k2_code == `SYNC_1) & (sop_k3_code == `SYNC_1) & (sop_k4_code == `SYNC_2)))
        sop0_vld <= 1'b1;
        else
          sop0_vld <= 1'b0;

        if(((sop_k1_code == `SYNC_1) & (sop_k2_code == `SYNC_1) & (sop_k3_code == `SYNC_3)) |
          ((sop_k1_code == `SYNC_1) & (sop_k2_code == `SYNC_1) & (sop_k4_code == `SYNC_3)) |
          ((sop_k1_code == `SYNC_1) & (sop_k3_code == `SYNC_3) & (sop_k4_code == `SYNC_3)) |
          ((sop_k2_code == `SYNC_1) & (sop_k3_code == `SYNC_3) & (sop_k4_code == `SYNC_3)))
        sop1_vld <= 1'b1;
        else
          sop1_vld <= 1'b0;

        if(((sop_k1_code == `SYNC_1) & (sop_k2_code == `RST_2) & (sop_k3_code == `RST_2 )) |
          ((sop_k1_code == `SYNC_1) & (sop_k2_code == `RST_2) & (sop_k4_code == `SYNC_3)) |
          ((sop_k1_code == `SYNC_1) & (sop_k3_code == `RST_2) & (sop_k4_code == `SYNC_3)) |
          ((sop_k2_code == `RST_2 ) & (sop_k3_code == `RST_2) & (sop_k4_code == `SYNC_3)))
        sop1_deg_vld <= 1'b1;
        else
          sop1_deg_vld <= 1'b0;

        if(((sop_k1_code == `SYNC_1) & (sop_k2_code == `SYNC_3) & (sop_k3_code == `SYNC_1)) |
          ((sop_k1_code == `SYNC_1) & (sop_k2_code == `SYNC_3) & (sop_k4_code == `SYNC_3)) |
          ((sop_k1_code == `SYNC_1) & (sop_k3_code == `SYNC_1) & (sop_k4_code == `SYNC_3)) |
          ((sop_k2_code == `SYNC_3) & (sop_k3_code == `SYNC_1) & (sop_k4_code == `SYNC_3)))
        sop2_vld <= 1'b1;
        else
          sop2_vld <= 1'b0;

        if(((sop_k1_code == `SYNC_1) & (sop_k2_code == `RST_2 ) & (sop_k3_code == `SYNC_3)) |
          ((sop_k1_code == `SYNC_1) & (sop_k2_code == `RST_2 ) & (sop_k4_code == `SYNC_2)) |
          ((sop_k1_code == `SYNC_1) & (sop_k3_code == `SYNC_3) & (sop_k4_code == `SYNC_2)) |
          ((sop_k2_code == `SYNC_1) & (sop_k3_code == `SYNC_3) & (sop_k4_code == `SYNC_2)))
        sop2_deg_vld <= 1'b1;
        else
          sop2_deg_vld <= 1'b0;

        if(((sop_k1_code == `RST_1 )  & (sop_k2_code == `SYNC_1) & (sop_k3_code == `RST_1 )) |
          ((sop_k1_code == `RST_1 ) & (sop_k2_code == `SYNC_1) & (sop_k4_code == `SYNC_3)) |
          ((sop_k1_code == `RST_1 ) & (sop_k3_code == `RST_1 ) & (sop_k4_code == `SYNC_3)) |
          ((sop_k2_code == `SYNC_1) & (sop_k3_code == `RST_1 ) & (sop_k4_code == `SYNC_3)))
        crst_vld <= 1'b1;
        else
          crst_vld <= 1'b0;

        if(((sop_k1_code == `RST_1 ) & (sop_k2_code == `RST_1) & (sop_k3_code == `RST_1)) |
          ((sop_k1_code == `RST_1 ) & (sop_k2_code == `RST_1) & (sop_k4_code == `RST_2)) |
          ((sop_k1_code == `RST_1 ) & (sop_k3_code == `RST_1) & (sop_k4_code == `RST_2)) |
          ((sop_k2_code == `RST_1 ) & (sop_k3_code == `RST_1) & (sop_k4_code == `RST_2)) &
          rx_ordset_en[3])
        hrst_vld <= 1'b1;
        else
          hrst_vld <= 1'b0;
      end
    end

  /*------------------------------------------------------------------------------
  --  5 bit fifo receive BMC data, when sop, data, `EOP phase
  ------------------------------------------------------------------------------*/
  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : bmc_rx_shift_proc
      if(~ic_rst_n)
        bmc_rx_shift <= 5'b0;
      else if(rx_idle_en)
        bmc_rx_shift <= 5'b0;
      else if(dec_rxbit_en & rx_bit_cmplt)
        bmc_rx_shift <= {decode_bmc, bmc_rx_shift[4:1]};
    end

  /*------------------------------------------------------------------------------
  --  count sop, data, crc, `EOP half byte(5bits) recive number
  ------------------------------------------------------------------------------*/
  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : rx_sop_half_byte_cnt_proc
      if(~ic_rst_n)
        rx_sop_half_byte_cnt <= 2'b0;
      else if(rx_idle_en)
        rx_sop_half_byte_cnt <= 2'b0;
      else if(rx_sop_en_d & rx_bit5_cmplt_d)
        rx_sop_half_byte_cnt <= rx_sop_half_byte_cnt+1;
    end

  /*------------------------------------------------------------------------------
  --  according received 5bits data decode 4bits data (message, crc)
  ------------------------------------------------------------------------------*/
  always @(*)
    begin : decode_4b_comb
      decode_4b = 4'b0000;
      case (rx_5bits)
        5'b11110 : decode_4b = 4'b0000; // 0
        5'b01001 : decode_4b = 4'b0001; // 1
        5'b10100 : decode_4b = 4'b0010; // 2
        5'b10101 : decode_4b = 4'b0011; // 3
        5'b01010 : decode_4b = 4'b0100; // 4
        5'b01011 : decode_4b = 4'b0101; // 5
        5'b01110 : decode_4b = 4'b0110; // 6
        5'b01111 : decode_4b = 4'b0111; // 7
        5'b10010 : decode_4b = 4'b1000; // 8
        5'b10011 : decode_4b = 4'b1001; // 9
        5'b10110 : decode_4b = 4'b1010; // A
        5'b10111 : decode_4b = 4'b1011; // B
        5'b11010 : decode_4b = 4'b1100; // C
        5'b11011 : decode_4b = 4'b1101; // D
        5'b11100 : decode_4b = 4'b1110; // E
        5'b11101 : decode_4b = 4'b1111; // F
        default  : decode_4b = 4'b0000;
      endcase
    end

endmodule // apb_ucpd_data_rx
