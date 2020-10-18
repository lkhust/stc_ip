
module apb_ucpd_bmc_filter (
  input            ic_clk       , // peripherial clock
  input            ic_rst_n     , // ic reset signal active low
  input            ic_cc_in     , // Input CC rxd signal
  input            bit_clk_red  ,
  input            hbit_clk_red ,
  input            ucpd_clk     ,
  input      [1:0] rxfilte      ,
  input            hrst_vld     ,
  input            crst_vld     ,
  input            rx_idle_en   ,
  input            rx_pre_en    ,
  input            rx_sop_en    ,
  input            rx_data_en   ,
  input            rx_wait_en   ,
  input            phy_rx_en    ,
  input            eop_ok       ,
  input            bmc_en       ,
  input            tx_bit       ,
  output reg       decode_bmc   , // decode input cc bmc
  output           ic_cc_out    ,
  output           rx_bit_cmplt ,
  output           rx_bit_sample,
  output           rx_pre_cmplt ,
  output           rx_bit5_cmplt,
  output           rx_wait_cmplt,
  output reg       receive_en
);
  // `include "parameter_def.v"
  // ----------------------------------------------------------
  // -- local registers and wires
  // ----------------------------------------------------------
  //regs
  reg        training_en     ;
  reg [ 1:0] simple_cnt      ;
  reg [ 2:0] cc_in_edg_cnt   ;
  reg [10:0] UI_cntA         ;
  reg [10:0] UI_cntB         ;
  reg [10:0] UI_cntC         ;
  reg [10:0] th_1UI          ;
  reg        rx_bmc          ;
  reg [10:0] data_cnt        ;
  reg        data1_flag      ;
  reg        tx_bmc          ;
  reg [10:0] pre_rxbit_cnt   ;
  reg        cc_int          ;
  reg        cc_data_int_nxt ;
  reg [10:0] UI_ave          ;
  reg [19:0] UI_sum          ;
  reg [ 3:0] ave_cnt         ;
  reg [10:0] rx_pre_hbit_cnt ;
  reg [10:0] rx_pre_lbit_cnt ;
  reg [10:0] rx_pre_hbit_time;
  reg [10:0] rx_pre_lbit_time;
  reg [10:0] rx_hbit_cnt     ;
  reg [10:0] rx_lbit_cnt     ;
  reg [ 2:0] rxbit_cnt       ;
  reg        cc_in_vld       ;
  reg [10:0] UI_H_cnt        ;
  reg [10:0] UI_L_cnt        ;
  reg [10:0] wait_cc_h_cnt   ;
  reg        first_2bit_end  ;
  reg [ 1:0] training_en_r   ;
  reg [ 1:0] rx_pre_type     ;
  reg        training_dis    ;

  //wires
  wire cc_in_edg     ;
  wire rxfilt_2n3    ;
  wire rxfilt_dis    ;
  wire rx_hbit_cmplt ;
  wire rx_lbit_cmplt ;
  wire rx_hbit_sample;
  wire rx_lbit_sample;
  wire rx_bit_edg    ;
  wire cc_data_int   ;
  wire ic_cc_in_sync ;


  assign dec_rxbit_en  = rx_sop_en | rx_data_en;
  assign rx_wait_cmplt = (wait_cc_h_cnt == UI_ave);

  assign rx_pre_cmplt  = rx_pre_en && (pre_rxbit_cnt == `RX_PRE_EDG);

  assign rx_bit_cmplt  = rx_bit_sample;

  assign rx_bit_sample = rx_hbit_sample | rx_lbit_sample;

  assign cc_int_nxt    = rxfilt_dis ? ic_cc_in_sync : cc_data_int;

  assign rx_hbit_cmplt = (rx_hbit_cnt == rx_pre_hbit_time);
  assign rx_lbit_cmplt = (rx_lbit_cnt == rx_pre_lbit_time);

  assign rx_hbit_sample = dec_rxbit_en & (rx_hbit_cnt == rx_pre_hbit_time>>1);
  assign rx_lbit_sample = dec_rxbit_en & (rx_lbit_cnt == rx_pre_lbit_time>>1);

  assign rx_bit5_cmplt = rx_bit_cmplt && (rxbit_cnt == `RX_BIT5_NUM);
  assign rx_cc_in_bit = training_en & (cc_in_edg_cnt == 3);
  assign training_en_falledg = training_en_r[1] & ~training_en_r[0]; // falling edge

  assign ic_cc_out    = tx_bmc;
  assign rxfilt_2n3   = rxfilte[1];
  assign rxfilt_dis   = rxfilte[0];

  digital_filter u_digital_filter (
    .clk     (ucpd_clk     ),
    .rst_n   (ic_rst_n     ),
    .mode    (rxfilt_2n3   ),
    .s_in    (ic_cc_in_sync),
    .s_filter(cc_data_int  )
  );

  /*------------------------------------------------------------------------------
  --  Wait for 2/3 consistent samples before considering it to be a new level
  --  ic_cc_in synchronization to ucpd_clk
  --  Sync the ic_cc_in bus signals to internal ic_clk, ic_cc_in synchronization
  ------------------------------------------------------------------------------*/
  apb_ucpd_bcm21 #(.WIDTH(1)) ic_cc_in_psyzr (
    .clk_d   (ucpd_clk     ),
    .rst_d_n (ic_rst_n     ),
    .init_d_n(1'b1         ),
    .test    (1'b0         ),
    .data_s  (ic_cc_in     ),
    .data_d  (ic_cc_in_sync)
  );

  /*------------------------------------------------------------------------------
  --  generator Biphase Mark Coding (BMC) Signaling
  --  biphase mark coding rules:
  --  1. a transition always occurs at the beginning of bit whatever its value is (0 or 1)
  --  2. for logical 1,a transition occurs in the middle of the bit.
  --  3. for logical 0, there is no transiton in the middle of the bit.
  ------------------------------------------------------------------------------*/
  /*------------------------------------------------------------------------------
  --  bmc encode
  ------------------------------------------------------------------------------*/
  always @(posedge ic_clk or negedge ic_rst_n)
    begin : tx_bmc_proc
      if(~ic_rst_n)
        tx_bmc <= 1'b0;
      else if(bmc_en) begin
        if(tx_bit) begin
          if(hbit_clk_red)
            tx_bmc <= ~tx_bmc;
        end
        else if(bit_clk_red)
          tx_bmc <= ~tx_bmc;
      end
      else
        tx_bmc <= 1'b0;
    end

  /*------------------------------------------------------------------------------
  --  bmc decode
  ------------------------------------------------------------------------------*/
  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : cc_in_d_proc
      if(~ic_rst_n)
        cc_int <= 1'b0;
      else
        cc_int <= cc_int_nxt; // for generate edg
    end

  assign cc_in_edg = (cc_int ^ cc_int_nxt);

  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : cc_in_vld_proc
      if(~ic_rst_n)
        cc_in_vld <= 1'b0;
      else if(rx_sop_en | rx_data_en)
        cc_in_vld <= 1'b0;
      else if((rx_idle_en | rx_pre_en) & cc_in_edg & phy_rx_en)
        cc_in_vld <= 1'b1;
    end

  /*------------------------------------------------------------------------------
  --  detect rx wait 3bits recive complete
  ------------------------------------------------------------------------------*/
  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : wait_cc_h_cnt_proc
      if(~ic_rst_n)
        wait_cc_h_cnt <= 11'b0;
      else if(rx_wait_cmplt)
        wait_cc_h_cnt <= 11'b0;
      else if(rx_wait_en & cc_int)
        wait_cc_h_cnt <= wait_cc_h_cnt+1;
      else
        wait_cc_h_cnt <= 11'b0;
    end

  // begin preamble use 2 bit to count edge, get 3 counter
  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : UI_H_cnt_proc
      if(~ic_rst_n)
        UI_H_cnt <= 11'b0;
      else if(cc_in_vld & cc_int)
        UI_H_cnt <= UI_H_cnt+1;
      else
        UI_H_cnt <= 11'b0;
    end

  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : UI_L_cnt_proc
      if(~ic_rst_n)
        UI_L_cnt <= 11'b0;
      else if(cc_in_vld & (~cc_int))
        UI_L_cnt <= UI_L_cnt+1;
      else
        UI_L_cnt <= 11'b0;
    end

  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : first_2bit_end_proc
      if(~ic_rst_n) begin
        simple_cnt     <= 2'b0;
        first_2bit_end <= 1'b0;
      end
      else if(dec_rxbit_en) begin
        simple_cnt     <= 2'b0;
        first_2bit_end <= 1'b0;
      end
      else if(cc_in_vld && cc_in_edg) begin
        if(simple_cnt == 2'd2) begin
          simple_cnt     <= 2'b0;
          first_2bit_end <= 1'b1;
        end
        else
          simple_cnt <= simple_cnt+1;
      end
    end

  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : UI_cntA_B_C_proc
      if(~ic_rst_n) begin
        UI_cntA <= 11'b0;
        UI_cntB <= 11'b0;
        UI_cntC <= 11'b0;
      end
      else if(cc_in_vld && cc_in_edg) begin
        case(simple_cnt)
          2'd0 :
            begin
              if(cc_int)
                UI_cntA <= UI_H_cnt;
              else
                UI_cntA <= UI_L_cnt;
            end
          2'd1 :
            begin
              if(cc_int)
                UI_cntB <= UI_H_cnt;
              else
                UI_cntB <= UI_L_cnt;
            end
          2'd2 :
            begin
              if(cc_int)
                UI_cntC <= UI_H_cnt;
              else
                UI_cntC <= UI_L_cnt;
            end
        endcase
      end
    end

  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : UI_cnt_proc
      if(~ic_rst_n)
        cc_in_edg_cnt <= 3'b0;
      else if(rx_cc_in_bit)
        cc_in_edg_cnt <= 3'b0;
      else if(training_en & cc_in_edg)
        cc_in_edg_cnt <= cc_in_edg_cnt+1;
    end

  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : UI_ave_proc
      if(~ic_rst_n)
        UI_ave <= 11'b0;
      else if(rx_idle_en)
        UI_ave <= 11'b0;
      else if(training_en) begin
        // if(ave_cnt == 4'd0)
        //   UI_ave <= th_1UI*3>>2;
        if(ave_cnt == 4'd15)
          UI_ave <= UI_sum*3>>6; //sum/16*3/4
        // else
        //   UI_ave <= th_1UI*3>>2;
      end
    end

  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : ave_cnt_proc
      if(~ic_rst_n) begin
        UI_sum  <= 20'b0;
        ave_cnt <= 4'b0;
      end
      // else if(training_en && (rx_cc_in_bit || ((cc_in_edg_cnt == 'd0) && cc_in_edg))) begin
      else if(training_en && cc_in_edg) begin
        if(ave_cnt == 4'd15) begin
          ave_cnt <= 4'b0;
          UI_sum  <= 20'b0;
        end
        else begin
          ave_cnt <= ave_cnt + 1;
          UI_sum  <= UI_sum + th_1UI;
        end
      end
      else if(~rx_pre_en) begin
        UI_sum  <= 20'b0;
        ave_cnt <= 4'b0;
      end
    end

  // wire [19:0] avg_th_1UI;
  // fir_gaussian_lowpass u_fir_gaussian_lowpass (
  //   .clk     (ucpd_clk),
  //   .rst_n   (ic_rst_n),
  //   .data_in (th_1UI),
  //   .data_out(avg_th_1UI)
  //   );

  // according to sum ,to get 1UI for a bit duty at preamble, 1UI = sum/2*3/4
  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : training_en_r_proc
      if(ic_rst_n == 1'b0)
        training_en_r <= 2'b0;
      else
        training_en_r <= {training_en_r[0], training_en};
    end

  // according to sum ,to get 1UI for a bit duty at preamble, 1UI = sum/2*3/4
  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : training_en_proc
      if(~ic_rst_n) begin
        rx_pre_type <= 2'b00;
        training_en <= 1'b0;
        th_1UI      <= 11'b0;
      end
      else if(dec_rxbit_en) begin
        rx_pre_type <= 2'b00;
        training_en <= 1'b0;
        th_1UI      <= 11'b0;
      end
      else if(first_2bit_end) begin
        if((UI_cntA < UI_cntC) && (UI_cntB < UI_cntC)) begin
          rx_pre_type <= 2'b01;
          training_en <= 1'b1;
          th_1UI      <= (UI_cntA+UI_cntB+UI_cntC)>>1; // (a+b+c)/2
        end
        else if((UI_cntA > UI_cntB) && (UI_cntA > UI_cntC)) begin
          rx_pre_type <= 2'b11;
          training_en <= 1'b1;
          th_1UI      <= (UI_cntA+UI_cntB+UI_cntC)>>1; // (a+b+c)/2
        end
        else if((UI_cntB > UI_cntC) && (UI_cntB > UI_cntA)) begin // b>c,b>a, standing for lost begin 1
          rx_pre_type <= 2'b00;
          training_en <= 1'b0;
          th_1UI      <= 11'b0;
        end
      end
    end

  /*------------------------------------------------------------------------------
  --  generate recrice bit
  ------------------------------------------------------------------------------*/
  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : rx_bmc_proc
      if(~ic_rst_n) begin
        rx_bmc <= 1'b0;
      end
      else if(rx_idle_en)
        rx_bmc <= 1'b0;
      else if(cc_in_edg) begin
        if(data_cnt >= UI_ave)
          rx_bmc <= 1'b0;
        else if(data1_flag)
          rx_bmc <= 1'b1;
      end
    end

  /*------------------------------------------------------------------------------
  --  decode a bit need counter
  ------------------------------------------------------------------------------*/
  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : data_cnt_flag_proc
      if(~ic_rst_n) begin
        data_cnt   <= 11'b0;
        data1_flag <= 1'b0;
      end
      else if(rx_idle_en) begin
        data_cnt   <= 11'b0;
        data1_flag <= 1'b0;
      end
      else if(cc_in_edg) begin
        if(data_cnt < UI_ave)
          data1_flag <= 1'b1;
        else
          data1_flag <= 1'b0;
        data_cnt <= 11'b0;
      end
      else
        data_cnt <= data_cnt+1;
    end

  /*------------------------------------------------------------------------------
  --  for decode bmc bit generate poseedge
  ------------------------------------------------------------------------------*/
  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : decode_bmc_proc
      if(~ic_rst_n)
        decode_bmc <= 1'b0;
      else
        decode_bmc <= rx_bmc;
    end

  assign rx_bit_edg = (decode_bmc ^ rx_bmc);

  /*------------------------------------------------------------------------------
  --  calculate receive bit edge counter in preamable, tottle 192
  ------------------------------------------------------------------------------*/

  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : pre_rxbit_cnt_proc
      if(~ic_rst_n)
        pre_rxbit_cnt <= 11'b0;
      else if(rx_pre_cmplt)
        pre_rxbit_cnt <= 11'b0;
      else if(cc_in_vld && cc_in_edg)
        pre_rxbit_cnt <= pre_rxbit_cnt+1;
    end

  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : training_dis_proc
      if(~ic_rst_n)
        training_dis <= 1'b0;
      else if(rx_idle_en)
        training_dis <= 1'b0;
      else if(training_en_falledg)
        training_dis <= 1'b1;
    end

  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : receive_en_proc
      if(~ic_rst_n)
        receive_en <= 1'b0;
      else if(training_dis | dec_rxbit_en)
        receive_en <= 1'b0;
      else if(training_en & phy_rx_en)
        receive_en <= 1'b1;
    end

  /*------------------------------------------------------------------------------
  --  calculate a receive bit time, to get one bit received complete signal
  ------------------------------------------------------------------------------*/
  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : rx_pre_h_lbit_cnt_proc
      if(~ic_rst_n) begin
        rx_pre_hbit_cnt <= 11'b0;
        rx_pre_lbit_cnt <= 11'b0;
      end
      else if(rx_pre_en) begin
        if(decode_bmc) begin
          rx_pre_hbit_cnt <= rx_pre_hbit_cnt+1;
          rx_pre_lbit_cnt <= 11'b0;
        end
        else begin
          rx_pre_lbit_cnt <= rx_pre_lbit_cnt+1;
          rx_pre_hbit_cnt <= 11'b0;
        end
      end
      else begin
        rx_pre_hbit_cnt <= 11'b0;
        rx_pre_lbit_cnt <= 11'b0;
      end
    end

  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : rx_pre_h_lbit_time_proc
      if(~ic_rst_n) begin
        rx_pre_hbit_time <= 11'b0;
        rx_pre_lbit_time <= 11'b0;
      end
      else if(rx_bit_edg & rx_pre_en) begin
        if(decode_bmc)
          rx_pre_hbit_time <= rx_pre_hbit_cnt;
        else
          rx_pre_lbit_time <= rx_pre_lbit_cnt;
      end
    end

  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : rx_h_lbit_cnt_proc
      if(~ic_rst_n) begin
        rx_hbit_cnt <= 11'b0;
        rx_lbit_cnt <= 11'b0;
      end
      else if(dec_rxbit_en) begin
        if(decode_bmc) begin
          if(rx_hbit_cmplt | rx_bit_edg)
            rx_hbit_cnt <= 11'b0;
          else begin
            rx_hbit_cnt <= rx_hbit_cnt+1;
            rx_lbit_cnt <= 11'b0;
          end
        end
        else begin
          if(rx_lbit_cmplt | rx_bit_edg)
            rx_lbit_cnt <= 11'b0;
          else begin
            rx_lbit_cnt <= rx_lbit_cnt+1;
            rx_hbit_cnt <= 11'b0;
          end
        end
      end
      else begin
        rx_hbit_cnt <= 11'b0;
        rx_lbit_cnt <= 11'b0;
      end
    end

  /*------------------------------------------------------------------------------
  --  detect sop, data, crc, eop half byte(5bits) recive complete
  ------------------------------------------------------------------------------*/
  always @(posedge ucpd_clk or negedge ic_rst_n)
    begin : rxbit_cnt_proc
      if(~ic_rst_n)
        rxbit_cnt <= 3'b0;
      else if(rx_bit5_cmplt)
        rxbit_cnt <= 3'b0;
      else if(dec_rxbit_en & rx_bit_cmplt)
        rxbit_cnt <= rxbit_cnt+1;
    end

endmodule

module digital_filter (
  input  clk     ,
  input  rst_n   ,
  input  mode    ,
  input  s_in    ,
  output s_filter
);

  reg s_in_d1;
  reg s_in_d2;
  reg s_in_d3;
  reg s_in_d4;

  always@(posedge clk or negedge rst_n)
    begin
      if(~rst_n)
        begin
          s_in_d1 <= 1'b1;
          s_in_d2 <= 1'b1;
          s_in_d3 <= 1'b1;
          s_in_d4 <= 1'b1;
        end
      else
        begin
          s_in_d1 <= s_in;
          s_in_d2 <= s_in_d1;
          s_in_d3 <= s_in_d2;
          s_in_d4 <= s_in_d3;
        end
    end

  assign filter_1 = s_in_d1 | s_in_d2; // 滤掉小于1个周期glitch
  assign filter_2 = s_in_d1 | s_in_d2 | s_in_d3; //滤掉大于1个周期且小于2个周期glitch
  assign filter_3 = s_in_d1 | s_in_d2 | s_in_d3 | s_in_d4; //滤掉大于2个周期且小于3个周期glitch
  assign s_filter = mode ? filter_1 : filter_2;

endmodule

// module fir_gaussian_lowpass #(
//   parameter ORDER    = 8    ,
//   parameter SIZE_IN  = 8    ,
//   parameter SIZE_OUT = 20   ,
//   parameter COEF0    = 8'd1 ,
//   parameter COEF1    = 8'd1,
//   parameter COEF2    = 8'd1,
//   parameter COEF3    = 8'd1,
//   parameter COEF4    = 8'd1,
//   parameter COEF5    = 8'd1,
//   parameter COEF6    = 8'd1,
//   parameter COEF7    = 8'd1,
//   parameter COEF8    = 8'd1
// ) (
//   input               clk    , // Clock
//   input               rst_n  , // Asynchronous reset active low
//   input [SIZE_IN-1:0] data_in,
//   output reg [SIZE_OUT-1:0] data_out
// );

//   reg [SIZE_IN-1:0] samples[1:ORDER];
//   integer           k               ;
//   wire [SIZE_OUT-1:0] data_out_nxt  ;

//   assign data_out_nxt = COEF0*data_in + COEF1*samples[1] + COEF2*samples[2]
//                                       + COEF3*samples[3] + COEF4*samples[4]
//                                       + COEF5*samples[5] + COEF6*samples[6]
//                                       + COEF7*samples[7] + COEF8*samples[8];

//   always @(posedge clk or negedge rst_n) begin
//     if(~rst_n)
//       data_out <= 20'b0;
//     else
//       data_out <= data_out_nxt>>3;
//   end

//   always @(posedge clk or negedge rst_n) begin
//     if(~rst_n) begin
//       for(k=1; k<= ORDER; k=k+1)
//         samples[k] <= 0;
//     end
//     else begin
//       samples[1] <= data_in;
//       for(k=2; k<= ORDER; k=k+1)
//         samples[k] <= samples[k-1];
//     end
//   end
// endmodule


