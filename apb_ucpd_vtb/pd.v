
`define RX_PRE_EDG     192
`define PRE_BIT_NUM    127
`define SOP_BIT_NUM    19
`define CRC_BIT_NUM    39
`define SOP_HBYTE_NUM  4        // unit is 5bit (totle 20bits)
`define TX_BIT5_NUM    4
`define TX_BIT10_NUM   9
`define RX_BIT5_NUM    4
`define SYNC_1         5'b11000
`define SYNC_2         5'b10001
`define SYNC_3         5'b00110
`define RST_1          5'b00111
`define RST_2          5'b11001
`define EOP            5'b01101
/*
------------------------------------------------------------------------
--
-- File :                       apb_ucpd_bcm21.v
-- Author:                      luo kun
-- Date :                       $Date: 2019/09/19 $
-- Abstract     :               Verilog module for DWbb
--
--
-- Modification History:
-- Date                 By      Version Change  Description
-- =====================================================================
-- See CVS log
-- =====================================================================
*/

module apb_ucpd_bcm21
  (
    clk_d,
    rst_d_n,
    init_d_n,
    data_s,
    test,
    data_d
  );

  parameter WIDTH       = 1; // RANGE 1 to 1024
  parameter F_SYNC_TYPE = 2; // RANGE 0 to 4
  parameter TST_MODE    = 0; // RANGE 0 to 2
  parameter VERIF_EN    = 1; // RANGE 0 to 5
  parameter SVA_TYPE    = 1;

  input              clk_d   ; // clock input from destination domain
  input              rst_d_n ; // active low asynchronous reset from destination domain
  input              init_d_n; // active low synchronous reset from destination domain
  input  [WIDTH-1:0] data_s  ; // data to be synchronized from source domain
  input              test    ; // test input

  output [WIDTH-1:0] data_d  ; // data synchronized to destination domain

  wire [WIDTH-1:0] data_s_int;

`ifndef SYNTHESIS
  `ifndef DWC_DISABLE_CDC_METHOD_REPORTING
    initial begin
      if ((F_SYNC_TYPE > 0)&&(F_SYNC_TYPE < 8))
        $display("Information: *** Instance %m module is using the <Double Register Synchronizer (1)> Clock Domain Crossing Method ***");
    end

    `ifdef DW_REPORT_SYNC_PARAMS
      initial begin
        if ((F_SYNC_TYPE & 7) > 0)
          $display("Information: *** Instance %m is configured as follows: WIDTH is: %0d, F_SYNC_TYPE is: %0d, TST_MODE is: %0d ***", WIDTH, (F_SYNC_TYPE & 7), TST_MODE);
      end
    `endif
  `endif
`endif

`ifdef SYNTHESIS
  assign data_s_int = data_s;
`else
  `ifdef DW_MODEL_MISSAMPLES
    initial begin
      $display("Information: %m: *** Running with DW_MODEL_MISSAMPLES defined, VERIF_EN is: %0d ***",
        VERIF_EN);
    end

    reg  [WIDTH-1:0] test_hold_ms ;
    wire             hclk_odd     ;
    reg  [WIDTH-1:0] last_data_dyn, data_s_delta_t;
    reg  [WIDTH-1:0] last_data_s, last_data_s_q, last_data_s_qq;
    wire [WIDTH-1:0] data_s_sel_0, data_s_sel_1;
    reg  [WIDTH-1:0] data_select  ; initial data_select = 0;
    reg  [WIDTH-1:0] data_select_2; initial data_select_2 = 0;

    always @ (negedge clk_d or negedge rst_d_n) begin : PROC_test_hold_ms_registers
      if (rst_d_n == 1'b0) begin
        test_hold_ms <= {WIDTH{1'b0}};
      end else if (init_d_n == 1'b0) begin
        test_hold_ms <= {WIDTH{1'b0}};
      end else begin
        test_hold_ms <= data_s;
      end
    end

    reg init_dly_n;

    always @ (posedge hclk_odd or data_s or rst_d_n) begin : PROC_catch_last_data
      data_s_delta_t <= data_s & {WIDTH{rst_d_n}} & {WIDTH{init_dly_n}};
      last_data_dyn  <= data_s_delta_t & {WIDTH{rst_d_n}} & {WIDTH{init_dly_n}};
    end // PROC_catch_last_data

    generate if ((VERIF_EN % 2) == 1) begin : GEN_HO_VE_EVEN
        assign hclk_odd = clk_d;
      end else begin : GEN_HO_VE_ODD
        assign hclk_odd = ~clk_d;
      end
    endgenerate

    always @ (posedge clk_d or negedge rst_d_n) begin : PROC_missample_hist_even
      if (rst_d_n == 1'b0) begin
        last_data_s_q <= {WIDTH{1'b0}};
        init_dly_n    <= 1'b1;
      end else if (init_d_n == 1'b0) begin
        last_data_s_q <= {WIDTH{1'b0}};
        init_dly_n    <= 1'b0;
      end else begin
        last_data_s_q <= last_data_s;
        init_dly_n    <= 1'b1;
      end
    end // PROC_missample_hist_even

    always @ (posedge hclk_odd or negedge rst_d_n) begin : PROC_missample_hist_odd
      if (rst_d_n == 1'b0) begin
        last_data_s    <= {WIDTH{1'b0}};
        last_data_s_qq <= {WIDTH{1'b0}};
      end else if (init_d_n == 1'b0) begin
        last_data_s    <= {WIDTH{1'b0}};
        last_data_s_qq <= {WIDTH{1'b0}};
      end else begin
        last_data_s    <= data_s;
        last_data_s_qq <= last_data_s_q;
      end
    end // PROC_missample_hist_odd

    always @ (data_s or last_data_s) begin : PROC_mk_next_data_select
      if (data_s != last_data_s) begin
        data_select = wide_random(WIDTH);

        if ((VERIF_EN == 2) || (VERIF_EN == 3))
          data_select_2 = wide_random(WIDTH);
        else
          data_select_2 = {WIDTH{1'b0}};
      end
    end  // PROC_mk_next_data_select

    assign data_s_sel_0 = (VERIF_EN < 1)? data_s : ((data_s & ~data_select) | (last_data_dyn & data_select));
    assign data_s_sel_1 = (VERIF_EN < 2)? {WIDTH{1'b0}} : ((last_data_s_q & ~data_select) | (last_data_s_qq & data_select));
    assign data_s_int   = ((data_s_sel_0 & ~data_select_2) | (data_s_sel_1 & data_select_2));

    `ifndef DWC_SYNCHRONIZER_TECH_MAP
      // { START Latency Accurate modeling
      initial begin : set_setup_hold_delay_PROC
        `ifndef DW_HOLD_MUX_DELAY
          `define DW_HOLD_MUX_DELAY  1
          if (((F_SYNC_TYPE & 7) == 2) && (VERIF_EN == 5))
            $display("Information: %m: *** Warning: `DW_HOLD_MUX_DELAY is not defined so it is being set to: %0d ***", `DW_HOLD_MUX_DELAY);
        `endif

        `ifndef DW_SETUP_MUX_DELAY
          `define DW_SETUP_MUX_DELAY  1
          if (((F_SYNC_TYPE & 7) == 2) && (VERIF_EN == 5))
            $display("Information: %m: *** Warning: `DW_SETUP_MUX_DELAY is not defined so it is being set to: %0d ***", `DW_SETUP_MUX_DELAY);
        `endif
      end // set_setup_hold_delay_PROC

      initial begin
        if (((F_SYNC_TYPE & 7) == 2) && (VERIF_EN == 5))
          $display("Information: %m: *** Running with Latency Accurate MISSAMPLES defined, VERIF_EN is: %0d ***", VERIF_EN);
      end

      reg [WIDTH-1:0] setup_mux_ctrl, hold_mux_ctrl;
      initial         setup_mux_ctrl = {WIDTH{1'b0}};
      initial         hold_mux_ctrl  = {WIDTH{1'b0}};

      wire [WIDTH-1:0] data_s_q            ;
      reg              clk_d_q             ;
      initial          clk_d_q       = 1'b0;
      reg  [WIDTH-1:0] setup_mux_out, d_muxout;
      reg  [WIDTH-1:0] d_ff1, d_ff2;
      integer          i,j,k;

      //Delay the destination clock
      always @ (posedge clk_d)
        #`DW_HOLD_MUX_DELAY clk_d_q = 1'b1;

        always @ (negedge clk_d)
        #`DW_HOLD_MUX_DELAY clk_d_q = 1'b0;

        //Delay the source data
        assign #`DW_SETUP_MUX_DELAY data_s_q = (!rst_d_n) ? {WIDTH{1'b0}}:data_s;

        //setup_mux_ctrl controls the data entering the flip flop
        always @ (data_s or data_s_q or setup_mux_ctrl) begin
          for (i=0;i<=WIDTH-1;i=i+1) begin
            if (setup_mux_ctrl[i])
              setup_mux_out[i] = data_s_q[i];
            else
              setup_mux_out[i] = data_s[i];
          end
        end

        always @ (posedge clk_d_q or negedge rst_d_n) begin
          if (rst_d_n == 1'b0)
            d_ff2 <= {WIDTH{1'b0}};
          else if (init_d_n == 1'b0)
            d_ff2 <= {WIDTH{1'b0}};
          else if (test == 1'b1)
            d_ff2 <= (TST_MODE == 1) ? test_hold_ms : data_s;
          else
            d_ff2 <= setup_mux_out;
        end

        always @ (posedge clk_d or negedge rst_d_n) begin
          if (rst_d_n == 1'b0) begin
            d_ff1          <= {WIDTH{1'b0}};
            setup_mux_ctrl <= {WIDTH{1'b0}};
            hold_mux_ctrl  <= {WIDTH{1'b0}};
          end
          else if (init_d_n == 1'b0) begin
            d_ff1          <= {WIDTH{1'b0}};
            setup_mux_ctrl <= {WIDTH{1'b0}};
            hold_mux_ctrl  <= {WIDTH{1'b0}};
          end
          else begin
            if (test == 1'b1)
              d_ff1 <= (TST_MODE == 1) ? test_hold_ms : data_s;
            else
              d_ff1 <= setup_mux_out;
            setup_mux_ctrl <= wide_random(WIDTH);  //randomize mux_ctrl
            hold_mux_ctrl  <= wide_random(WIDTH);  //randomize mux_ctrl
          end
        end


        //hold_mux_ctrl decides the clock triggering the flip-flop
        always @(hold_mux_ctrl or d_ff2 or d_ff1) begin
          for (k=0;k<=WIDTH-1;k=k+1) begin
            if (hold_mux_ctrl[k])
              d_muxout[k] = d_ff2[k];
            else
              d_muxout[k] = d_ff1[k];
          end
        end
        // END Latency Accurate modeling }


        //Assertions
        `ifdef DWC_BCM_SNPS_ASSERT_ON
          `ifndef SYNTHESIS
            generate if ((F_SYNC_TYPE == 2) && (VERIF_EN == 5)) begin : GEN_ASSERT_FST2_VE5
                sequence p_num_d_chng;
                  @ (posedge clk_d) 1'b1 ##0 (data_s != d_ff1); //Number of times input data changed
                endsequence

                sequence p_num_d_chng_hmux1;
                  @ (posedge clk_d) 1'b1 ##0 ((data_s != d_ff1) && (|(hold_mux_ctrl & (data_s ^ d_ff1)))); //Number of times hold_mux_ctrl was asserted when the input data changed
                endsequence

                sequence p_num_d_chng_smux1;
                  @ (posedge clk_d) 1'b1 ##0 ((data_s != d_ff1) && (|(setup_mux_ctrl & (data_s ^ d_ff1)))); //Number of times setup_mux_ctrl was asserted when the input data changed
                endsequence

                sequence p_hold_vio;
                  reg [WIDTH-1:0]temp_var, temp_var1;
                  @ (posedge clk_d) (((data_s != d_ff1) && (|(hold_mux_ctrl & (data_s ^ d_ff1)))), temp_var = data_s, temp_var1 =(hold_mux_ctrl & (data_s ^ d_ff1))) ##1 ((data_d & temp_var1) == (temp_var & temp_var1));
                  //Number of times output data was advanced due to hold violation
                endsequence

                sequence p_setup_vio;
                  reg [WIDTH-1:0]temp_var, temp_var1;
                  @ (posedge clk_d) (((data_s != d_ff1) && (|(setup_mux_ctrl & (data_s ^ d_ff1)))), temp_var = data_s, temp_var1 =(setup_mux_ctrl & (data_s ^ d_ff1))) ##2 ((data_d & temp_var1) != (temp_var & temp_var1));
                  //Number of times output data was delayed due to setup violation
                endsequence

                cp_num_d_chng           : cover property  (p_num_d_chng);
                cp_num_d_chng_hld_mux1  : cover property  (p_num_d_chng_hmux1);
                cp_num_d_chng_set_mux1  : cover property  (p_num_d_chng_smux1);
                cp_hold_vio             : cover property  (p_hold_vio);
                cp_setup_vio            : cover property  (p_setup_vio);
              end
            endgenerate
          `endif // SYNTHESIS
        `endif // DWC_BCM_SNPS_ASSERT_ON
      `endif // DWC_SYNCHRONIZER_TECH_MAP

      function [WIDTH-1:0] wide_random;
        input [31:0]        in_width;   // should match "WIDTH" parameter -- need one input to satisfy Verilog function requirement

        reg   [WIDTH-1:0]   temp_result;
        reg   [31:0]        rand_slice;
        integer             i, j, base;
        begin
          `ifdef DWC_BCM_SV
            temp_result = $urandom;
          `else
            temp_result = $random;
          `endif
          if (((WIDTH / 32) + 1) > 1) begin
            for (i=1 ; i < ((WIDTH / 32) + 1) ; i=i+1) begin
              base = i << 5;
              `ifdef DWC_BCM_SV
                rand_slice = $urandom;
              `else
                rand_slice = $random;
              `endif
              for (j=0 ; ((j < 32) && (base+j < in_width)) ; j=j+1) begin
                temp_result[base+j] = rand_slice[j];
              end
            end
          end

          wide_random = temp_result;
        end
      endfunction  // wide_random

      initial begin : seed_random_PROC
        integer seed, init_rand;
        `ifdef DW_MISSAMPLE_SEED
          if (`DW_MISSAMPLE_SEED != 0)
            seed = `DW_MISSAMPLE_SEED;
          else
            seed = 32'h0badbeef;
        `else
          seed = 32'h0badbeef;
        `endif

        `ifdef DWC_BCM_SV
          init_rand = $urandom(seed);
        `else
          init_rand = $random(seed);
        `endif
      end // seed_random_PROC

    `else
      assign data_s_int = data_s;
    `endif
  `endif

  reg  [WIDTH-1:0] sample_meta       ;
  reg  [WIDTH-1:0] sample_syncm1     ;
  reg  [WIDTH-1:0] sample_syncm2     ;
  reg  [WIDTH-1:0] sample_syncl      ;
  reg  [WIDTH-1:0] sample_meta_n     ;
  wire [WIDTH-1:0] next_sample_meta  ;
  wire [WIDTH-1:0] next_sample_syncm1;
  wire [WIDTH-1:0] next_sample_syncm2;
  wire [WIDTH-1:0] next_sample_syncl ;
  reg  [WIDTH-1:0] test_hold         ;

// spyglass disable_block Ac_conv04
// SMD: Checks all the control-bus clock domain crossings which do not follow gray encoding
// SJ: The bus being synchronized (sample_meta_n/sample_meta) is a memory array that is within a dual clock FIFO CDC method.  As such, the FIFO controller guarantees that the bits of the synchronized memory array will be selected at a given time have been written and sustained in the memory array long enough to be safely synchronized, selected and captured. Thus, no Gray code sequencing is necessary.

generate
  if ((F_SYNC_TYPE & 7) == 0) begin : GEN_FST0
    if (TST_MODE == 1) begin : GEN_DATAD_FST0_TM1
      //   reg    [WIDTH-1:0]      test_hold;
      always @ (negedge clk_d or negedge rst_d_n) begin : test_hold_registers_PROC
        if (rst_d_n == 1'b0) begin
          test_hold        <= {WIDTH{1'b0}};
        end else if (init_d_n == 1'b0) begin
          test_hold        <= {WIDTH{1'b0}};
        end else begin
// spyglass disable_block W391
// SMD: Design has a clock driving it on both edges
// SJ: This module is configured so that the following asynch signals are clocked by 2 flip-flops with different clock edges of the same clock.  So, disable SpyGlass from reporting this error.
// spyglass disable_block Ac_unsync02
// SMD: Checks unsynchronized crossing for vector signals
// SJ: The SpyGlass Ac_unsync02 rule reports asynchronous clock domain crossings for vector signals that have at least one unsynchronized source. This rule also reports the reason for unsynchronized crossings.
          test_hold        <= data_s;
// spyglass enable_block W391
// spyglass enable_block Ac_unsync02
        end
      end

      assign data_d = (test == 1'b1) ? test_hold : data_s;
    end else begin : GEN_DATAD_FST0_TM_NE_1
      assign data_d = data_s;
    end
  end
  if ((F_SYNC_TYPE & 7) == 1) begin : GEN_FST1
    //  reg    [WIDTH-1:0]      sample_meta_n;
    //  reg    [WIDTH-1:0]      sample_syncl;
    //  wire   [WIDTH-1:0]      next_sample_syncm1;
    //  wire   [WIDTH-1:0]      next_sample_syncl;

    always @ (negedge clk_d or negedge rst_d_n) begin : negedge_registers_PROC
// spyglass disable_block STARC05-1.3.1.3
// SMD: Asynchronous reset/preset signals must not be used as non-reset/preset or synchronous reset/preset signals
// SJ: Synchronizer FFs required to have reset to initialize system, so, disable SpyGlass from reporting this error.
      if (rst_d_n == 1'b0) begin
// spyglass enable_block STARC05-1.3.1.3
        sample_meta_n    <= {WIDTH{1'b0}};
      end else if (init_d_n == 1'b0) begin
        sample_meta_n    <= {WIDTH{1'b0}};
      end else begin
// spyglass disable_block W391
// SMD: Design has a clock driving it on both edges
// SJ: This module is configured so that the following asynch signals are clocked by 2 flip-flops with different clock edges of the same clock.  So, disable SpyGlass from reporting this error.
        sample_meta_n    <= data_s_int;
// spyglass enable_block W391
      end
    end

    assign next_sample_syncm1 = sample_meta_n;
    assign next_sample_syncl  = next_sample_syncm1;

    always @ (posedge clk_d or negedge rst_d_n) begin : posedge_registers_PROC
// spyglass disable_block STARC05-1.3.1.3
// SMD: Asynchronous reset/preset signals must not be used as non-reset/preset or synchronous reset/preset signals
// SJ: Synchronizer FFs required to have reset to initialize system, so, disable SpyGlass from reporting this error.
      if (rst_d_n == 1'b0) begin
// spyglass enable_block STARC05-1.3.1.3
        sample_syncl     <= {WIDTH{1'b0}};
      end else if (init_d_n == 1'b0) begin
        sample_syncl     <= {WIDTH{1'b0}};
      end else begin
// spyglass disable_block W391
// SMD: Design has a clock driving it on both edges
// SJ: This module is configured so that the following asynch signals are clocked by 2 flip-flops with different clock edges of the same clock.  So, disable SpyGlass from reporting this error.
        sample_syncl     <= next_sample_syncl;
// spyglass enable_block W391
      end
    end

    assign data_d = sample_syncl;
  end
  if ((F_SYNC_TYPE & 7) == 2) begin : GEN_FST2
    //  reg    [WIDTH-1:0]      sample_meta;
    //  reg    [WIDTH-1:0]      sample_syncl;
    //  wire   [WIDTH-1:0]      next_sample_meta;
    //  wire   [WIDTH-1:0]      next_sample_syncm1;
    //  wire   [WIDTH-1:0]      next_sample_syncl;

    if (TST_MODE == 1) begin : GEN_TST_MODE1
      //  reg    [WIDTH-1:0]      test_hold;

      assign next_sample_meta      = (test == 1'b0) ? data_s_int : test_hold;

      always @ (negedge clk_d or negedge rst_d_n) begin : test_hold_registers_PROC1
        if (rst_d_n == 1'b0) begin
          test_hold        <= {WIDTH{1'b0}};
        end else if (init_d_n == 1'b0) begin
          test_hold        <= {WIDTH{1'b0}};
        end else begin
// spyglass disable_block W391
// SMD: Design has a clock driving it on both edges
// SJ: This module is configured so that the following asynch signals are clocked by 2 flip-flops with different clock edges of the same clock.  So, disable SpyGlass from reporting this error.
// spyglass disable_block Ac_unsync02
// SMD: Checks unsynchronized crossing for vector signals
// SJ: The SpyGlass Ac_unsync02 rule reports asynchronous clock domain crossings for vector signals that have at least one unsynchronized source. This rule also reports the reason for unsynchronized crossings.
          test_hold        <= data_s;
// spyglass enable_block W391
// spyglass enable_block Ac_unsync02
        end
      end
    end else begin : GEN_TST_MODE0
      assign next_sample_meta      = (test == 1'b0) ? data_s_int : data_s;
    end


    `ifdef SYNTHESIS
      assign next_sample_syncm1 = sample_meta;
    `else
      `ifdef DW_MODEL_MISSAMPLES
        if (((F_SYNC_TYPE & 7) == 2) && (VERIF_EN == 5)) begin : GEN_NXT_SMPL_SM1_FST2_VE5
          assign next_sample_syncm1 = d_muxout;
        end else begin : GEN_NXT_SMPL_SM1_ELSE
          assign next_sample_syncm1 = sample_meta;
        end
      `else
        assign next_sample_syncm1 = sample_meta;
      `endif
    `endif
    assign next_sample_syncl = next_sample_syncm1;
    always @ (posedge clk_d or negedge rst_d_n) begin : posedge_registers_PROC
// spyglass disable_block STARC05-1.3.1.3
// SMD: Asynchronous reset/preset signals must not be used as non-reset/preset or synchronous reset/preset signals
// SJ: Synchronizer FFs required to have reset to initialize system, so, disable SpyGlass from reporting this error.
      if (rst_d_n == 1'b0) begin
// spyglass enable_block STARC05-1.3.1.3
        sample_meta     <= {WIDTH{1'b0}};
        sample_syncl     <= {WIDTH{1'b0}};
      end else if (init_d_n == 1'b0) begin
        sample_meta     <= {WIDTH{1'b0}};
        sample_syncl     <= {WIDTH{1'b0}};
      end else begin
// spyglass disable_block W391
// SMD: Design has a clock driving it on both edges
// SJ: This module is configured so that the following asynch signals are clocked by 2 flip-flops with different clock edges of the same clock.  So, disable SpyGlass from reporting this error.
// spyglass disable_block Ac_glitch03
// SMD: Reports clock domain crossings subject to glitches
// SJ: The SpyGlass Ac_glitch03 rule checks glitch-prone combinational logic in the crossings synchronized by one of the following synchronizing schemes: Conventional Multi-Flop Synchronization Scheme; Synchronizing Cell Synchronization Scheme; Qualifier Synchronization Scheme Using qualifier -crossing.
        sample_meta     <= next_sample_meta;
        sample_syncl     <= next_sample_syncl;
// spyglass enable_block W391
// spyglass enable_block Ac_glitch03
      end
    end

    assign data_d = sample_syncl;
  end
  if ((F_SYNC_TYPE & 7) == 3) begin : GEN_FST3
    //   reg    [WIDTH-1:0]      sample_meta;
    //   reg    [WIDTH-1:0]      sample_syncm1;
    //   reg    [WIDTH-1:0]      sample_syncl;
    //   wire   [WIDTH-1:0]      next_sample_meta;
    //   wire   [WIDTH-1:0]      next_sample_syncm1;
    //   wire   [WIDTH-1:0]      next_sample_syncl;

    if (TST_MODE == 1) begin : GEN_TST_MODE1
      // reg    [WIDTH-1:0]      test_hold;

      assign next_sample_meta      = (test == 1'b0) ? data_s_int : test_hold;

      always @ (negedge clk_d or negedge rst_d_n) begin : test_hold_registers_PROC2
        if (rst_d_n == 1'b0) begin
          test_hold        <= {WIDTH{1'b0}};
        end else if (init_d_n == 1'b0) begin
          test_hold        <= {WIDTH{1'b0}};
        end else begin
// spyglass disable_block W391
// SMD: Design has a clock driving it on both edges
// SJ: This module is configured so that the following asynch signals are clocked by 2 flip-flops with different clock edges of the same clock.  So, disable SpyGlass from reporting this error.
// spyglass disable_block Ac_unsync02
// SMD: Checks unsynchronized crossing for vector signals
// SJ: The SpyGlass Ac_unsync02 rule reports asynchronous clock domain crossings for vector signals that have at least one unsynchronized source. This rule also reports the reason for unsynchronized crossings.
          test_hold        <= data_s;
// spyglass enable_block W391
// spyglass enable_block Ac_unsync02
        end
      end
    end else begin : GEN_TST_MODE0
      assign next_sample_meta      = (test == 1'b0) ? data_s_int : data_s;
    end

    assign next_sample_syncm1 = sample_meta;
    assign next_sample_syncl  = sample_syncm1;
    always @ (posedge clk_d or negedge rst_d_n) begin : posedge_registers_PROC
// spyglass disable_block STARC05-1.3.1.3
// SMD: Asynchronous reset/preset signals must not be used as non-reset/preset or synchronous reset/preset signals
// SJ: Synchronizer FFs required to have reset to initialize system, so, disable SpyGlass from reporting this error.
      if (rst_d_n == 1'b0) begin
// spyglass enable_block STARC05-1.3.1.3
        sample_meta     <= {WIDTH{1'b0}};
        sample_syncm1    <= {WIDTH{1'b0}};
        sample_syncl     <= {WIDTH{1'b0}};
      end else if (init_d_n == 1'b0) begin
        sample_meta     <= {WIDTH{1'b0}};
        sample_syncm1    <= {WIDTH{1'b0}};
        sample_syncl     <= {WIDTH{1'b0}};
      end else begin
// spyglass disable_block W391
// SMD: Design has a clock driving it on both edges
// SJ: This module is configured so that the following asynch signals are clocked by 2 flip-flops with different clock edges of the same clock.  So, disable SpyGlass from reporting this error.
// spyglass disable_block Ac_glitch03
// SMD: Reports clock domain crossings subject to glitches
// SJ: The SpyGlass Ac_glitch03 rule checks glitch-prone combinational logic in the crossings synchronized by one of the following synchronizing schemes: Conventional Multi-Flop Synchronization Scheme; Synchronizing Cell Synchronization Scheme; Qualifier Synchronization Scheme Using qualifier -crossing.
        sample_meta     <= next_sample_meta;
        sample_syncm1    <= next_sample_syncm1;
        sample_syncl     <= next_sample_syncl;
// spyglass enable_block W391
// spyglass enable_block Ac_glitch03
      end
    end

    assign data_d = sample_syncl;
  end
  if ((F_SYNC_TYPE & 7) == 4) begin : GEN_FST4
    //  reg    [WIDTH-1:0]      sample_meta;
    //  reg    [WIDTH-1:0]      sample_syncm1;
    //  reg    [WIDTH-1:0]      sample_syncm2;
    //  reg    [WIDTH-1:0]      sample_syncl;
    //  wire   [WIDTH-1:0]      next_sample_meta;
    //  wire   [WIDTH-1:0]      next_sample_syncm1;
    //  wire   [WIDTH-1:0]      next_sample_syncm2;
    //  wire   [WIDTH-1:0]      next_sample_syncl;

    if (TST_MODE == 1) begin : GEN_TST_MODE1
      // reg    [WIDTH-1:0]      test_hold;

      assign next_sample_meta      = (test == 1'b0) ? data_s_int : test_hold;

      always @ (negedge clk_d or negedge rst_d_n) begin : test_hold_registers_PROC3
        if (rst_d_n == 1'b0) begin
          test_hold        <= {WIDTH{1'b0}};
        end else if (init_d_n == 1'b0) begin
          test_hold        <= {WIDTH{1'b0}};
        end else begin
// spyglass disable_block W391
// SMD: Design has a clock driving it on both edges
// SJ: This module is configured so that the following asynch signals are clocked by 2 flip-flops with different clock edges of the same clock.  So, disable SpyGlass from reporting this error.
// spyglass disable_block Ac_unsync02
// SMD: Checks unsynchronized crossing for vector signals
// SJ: The SpyGlass Ac_unsync02 rule reports asynchronous clock domain crossings for vector signals that have at least one unsynchronized source. This rule also reports the reason for unsynchronized crossings.
          test_hold        <= data_s;
// spyglass enable_block W391
// spyglass enable_block Ac_unsync02
        end
      end
    end else begin : GEN_TST_MODE0
      assign next_sample_meta      = (test == 1'b0) ? data_s_int : data_s;
    end

    assign next_sample_syncm1 = sample_meta;
    assign next_sample_syncm2 = sample_syncm1;
    assign next_sample_syncl  = sample_syncm2;
    always @ (posedge clk_d or negedge rst_d_n) begin : posedge_registers_PROC
// spyglass disable_block STARC05-1.3.1.3
// SMD: Asynchronous reset/preset signals must not be used as non-reset/preset or synchronous reset/preset signals
// SJ: Synchronizer FFs required to have reset to initialize system, so, disable SpyGlass from reporting this error.
      if (rst_d_n == 1'b0) begin
// spyglass enable_block STARC05-1.3.1.3
        sample_meta     <= {WIDTH{1'b0}};
        sample_syncm1    <= {WIDTH{1'b0}};
        sample_syncm2    <= {WIDTH{1'b0}};
        sample_syncl     <= {WIDTH{1'b0}};
      end else if (init_d_n == 1'b0) begin
        sample_meta     <= {WIDTH{1'b0}};
        sample_syncm1    <= {WIDTH{1'b0}};
        sample_syncm2    <= {WIDTH{1'b0}};
        sample_syncl     <= {WIDTH{1'b0}};
      end else begin
// spyglass disable_block W391
// SMD: Design has a clock driving it on both edges
// SJ: This module is configured so that the following asynch signals are clocked by 2 flip-flops with different clock edges of the same clock.  So, disable SpyGlass from reporting this error.
// spyglass disable_block Ac_glitch03
// SMD: Reports clock domain crossings subject to glitches
// SJ: The SpyGlass Ac_glitch03 rule checks glitch-prone combinational logic in the crossings synchronized by one of the following synchronizing schemes: Conventional Multi-Flop Synchronization Scheme; Synchronizing Cell Synchronization Scheme; Qualifier Synchronization Scheme Using qualifier -crossing.
        sample_meta     <= next_sample_meta;
        sample_syncm1    <= next_sample_syncm1;
        sample_syncm2    <= next_sample_syncm2;
        sample_syncl     <= next_sample_syncl;
// spyglass enable_block W391
// spyglass enable_block Ac_glitch03
      end
    end

    assign data_d = sample_syncl;
  end
endgenerate

// spyglass enable_block Ac_conv04

`ifdef DWC_BCM_SNPS_ASSERT_ON
  `ifndef SYNTHESIS

    `ifdef DWC_BCM_CDC_COVERAGE_REPORT
      generate if (SVA_TYPE == 0) begin : CDC_COVERAGE_REPORT

          reg clk_d_mod;
          reg rst_n_mod;

          assign clk_d_mod = (F_SYNC_TYPE==1) ? ~clk_d : clk_d;
          assign rst_n_mod = rst_d_n`ifndef DWC_NO_CDC_INIT & init_d_n`endif;

          genvar i;
          for (i=0; i<WIDTH; i=i+1) begin : DATA_S
            property LtoHMonitor;
              @(posedge clk_d_mod) disable iff (!rst_n_mod `ifndef DWC_NO_TST_MODE `ifndef DWC_CDC_TST_MODE_2 || test`endif `endif)
                $rose(data_s[i]);
            endproperty
            COVER_LOW_TO_HIGH_TRANSITION: cover property (LtoHMonitor);

            property HtoLMonitor;
              @(posedge clk_d_mod) disable iff (!rst_n_mod `ifndef DWC_NO_TST_MODE `ifndef DWC_CDC_TST_MODE_2 || test`endif `endif)
                $fell(data_s[i]);
            endproperty
            COVER_HIGH_TO_LOW_TRANSITION: cover property (HtoLMonitor);
          end
        end endgenerate
    `endif
    generate
      if (SVA_TYPE == 1) begin : GEN_SVATP_EQ_1
        DW_apb_i2c_sva01 #(WIDTH, (F_SYNC_TYPE & 7)) P_SYNC_HS (.*);
      end
      if (SVA_TYPE == 2) begin : GEN_SVATP_EQ_2
        DW_apb_i2c_sva05 #(WIDTH, (F_SYNC_TYPE & 7)) P_SYNC_GC (.*);
      end
    endgenerate
  `endif // SYNTHESIS
`endif // DWC_BCM_SNPS_ASSERT_ON

endmodule
/*
------------------------------------------------------------------------
--
-- File :                       apb_ucpd_bcm41.v
-- Author:                      luo kun
-- Date :                       $Date: 2019/09/19 $
-- Abstract     :               Verilog module for DWbb
--
--
-- Modification History:
-- Date                 By      Version Change  Description
-- =====================================================================
-- See CVS log
-- =====================================================================
*/
module apb_ucpd_bcm41 (
  clk_d,
  rst_d_n,
  init_d_n,
  data_s,
  test,
  data_d
);

parameter WIDTH       = 1 ; // RANGE 1 to 1024
parameter RST_VAL     = -1; // RANGE -1 to 2147483647
parameter F_SYNC_TYPE = 2 ; // RANGE 0 to 4
parameter TST_MODE    = 0 ; // RANGE 0 to 2
parameter VERIF_EN    = 1 ; // RANGE 0 to 5
parameter SVA_TYPE    = 1 ; // RANGE 0 to 2

// spyglass disable_block ParamWidthMismatch-ML
// SMD: Parameter width does not match with the value assigned
// SJ: Although there is mismatch between parameters, the legal value of RHS parameter can not exceed the range that the LHS parameter can represent. In regards to SpyGlass complaining about LHS not equal RHS when assigning a sized localparam to a value calculated from parameters (which are most likely considered 32-bit signed integers), the messages around this type of assignment could be turned off.
// spyglass disable_block W163
// SMD: Truncation of bits in constant integer conversion
// SJ: The W163 rule flags constant integer assignments to signals when the width of the signal is narrower than the width of the constant integer. When assigning a constant integer value to a LHS operand, the width specification for RHS should match LHS operand width. If the signal is wider than the constant integer, the extra bits are padded with zeros. If the signal is narrower than the constant integer, the extra high-order non-zero bits are discarded.
localparam [WIDTH-1 : 0] RST_POLARITY = RST_VAL;
// spyglass enable_block ParamWidthMismatch-ML
// spyglass enable_block W163

input              clk_d   ; // clock input from destination domain
input              rst_d_n ; // active low asynchronous reset from destination domain
input              init_d_n; // active low synchronous reset from destination domain
input  [WIDTH-1:0] data_s  ; // data to be synchronized from source domain
input              test    ; // test input
output [WIDTH-1:0] data_d  ; // data synchronized to destination domain

wire [WIDTH-1:0] data_s_int;
wire [WIDTH-1:0] data_d_int;

  assign data_s_int = data_s ^ RST_POLARITY;

  apb_ucpd_bcm21 #(WIDTH,F_SYNC_TYPE+8,TST_MODE,VERIF_EN,SVA_TYPE) U_SYNC (
    .clk_d   (clk_d     ),
    .rst_d_n (rst_d_n   ),
    .init_d_n(init_d_n  ),
    .data_s  (data_s_int),
    .test    (test      ),
    .data_d  (data_d_int)
  );

  assign data_d = data_d_int ^ RST_POLARITY;

endmodule

/*
------------------------------------------------------------------------
--
-- File :                       apb_ucpd_biu.v
-- Author:                      luo kun
-- Date :                       $Date: 2020/07/12 $
// Abstract: Apb bus interface module.
//           This module is intended for use with APB slave
//           macrocells.  The module generates output signals
//           from the APB bus interface that are intended for use in
//           the register block of the macrocell.
//
//        1: Generates the write enable (wr_en) and read
//           enable (rd_en) for register accesses to the macrocell.
//
//        2: Decodes the address bus (paddr) to generate the active
//           byte lane signal (byte_en).
//
//        3: Strips the APB address bus (paddr) to generate the
//           register offset address output (reg_addr).
//
//        4: Registers APB read data (prdata) onto the APB data bus.
//           The read data is routed to the correct byte lane in this
//           module.
--
--
-- Modification History:
-- Date                 By      Version Change  Description
-- =====================================================================
-- See CVS log
-- =====================================================================
*/
module apb_ucpd_biu (
   input             pclk    , // APB clock
   input             presetn , // APB reset
   input             psel    , // APB slave select
   input             pwrite  , // APB write/read
   input             penable , // APB enable
   input      [ 7:0] paddr   , // APB address
   input      [31:0] pwdata  , // APB write data bus
   input      [31:0] iprdata , // Internal read data bus
   output            wr_en   , // Write enable signal
   output            rd_en   , // Read enable signal
   output reg [ 3:0] byte_en , // Active byte lane signal
   output     [ 5:0] reg_addr, // Register address offset
   output reg [31:0] ipwdata , // Internal write data bus
   output reg [31:0] prdata    // APB read data bus
);

   // --------------------------------------------
   // -- write/read enable
   //
   // -- Generate write/read enable signals from
   // -- psel, penable and pwrite inputs
   // --------------------------------------------
   assign wr_en = psel &  penable &  pwrite;
   assign rd_en = psel & (!penable) & (!pwrite);
   // --------------------------------------------
   // -- Register address
   //
   // -- Strips register offset address from the
   // -- APB address bus
   // --------------------------------------------
   assign reg_addr = paddr[7:2];

   // --------------------------------------------
   // -- APB write data
   //
   // -- ipwdata is zero padded before being
   // -- passed through this block
   // --------------------------------------------
   always @(pwdata) begin : IPWDATA_PROC
      ipwdata = 32'b0;
      ipwdata = pwdata;
   end

   // --------------------------------------------
   // -- Set active byte lane
   //
   // -- This bit vector is used to set the active
   // -- byte lanes for write/read accesses to the
   // -- registers
   // --------------------------------------------
   always @(paddr) begin : BYTE_EN_PROC
      byte_en = 4'b1111;
   end

   // --------------------------------------------
   // -- APB read data.
   //
   // -- Register data enters this block on a
   // -- 32-bit bus (iprdata). The upper unused
   // -- bit(s) have been zero padded before entering
   // -- this block.  The process below strips the
   // -- active byte lane(s) from the 32-bit bus
   // -- and registers the data out to the APB
   // -- read data bus (prdata).
   // --------------------------------------------
   always @(posedge pclk or negedge presetn) begin : PRDATA_PROC
      if(presetn == 1'b0)
         prdata <= 32'b0;
      else if(rd_en)
         prdata <= iprdata;
   end

endmodule // apb_i2c_biu


module apb_ucpd_bmc_filter (
  input            ic_clk          , // peripherial clock
  input            ic_rst_n        , // ic reset signal active low
  input            ucpden          ,
  input            ic_cc_in        , // Input CC rxd signal
  input            bit_clk_red     ,
  input            hbit_clk_red    ,
  input            ucpd_clk        ,
  input            ucpd_clk_red    ,
  input            bypass_prescaler,
  input      [1:0] rxfilte         ,
  input            hrst_vld        ,
  input            crst_vld        ,
  input            rx_pre_en       ,
  input            rx_sop_en       ,
  input            rx_data_en      ,
  input            tx_eop_cmplt,
  input            eop_ok          ,
  input            pre_en          ,
  input            sop_en          ,
  input            bmc_en          ,
  input            dec_rxbit_en    ,
  input            tx_bit          ,
  output reg       decode_bmc      , // decode input cc bmc
  output           ic_cc_out       ,
  output           rx_bit_cmplt    ,
  output           rx_pre_cmplt    ,
  output           rx_bit5_cmplt   ,
  output reg       receive_en
);
  // `include "parameter_def.v"
  // ----------------------------------------------------------
  // -- local registers and wires
  // ----------------------------------------------------------
  //regs
  reg        cc_data_int     ;
  reg        training_en     ;
  reg [ 1:0] simple_cnt      ;
  reg [10:0] UI_cntA         ;
  reg [10:0] UI_cntB         ;
  reg [10:0] UI_cntC         ;
  reg [10:0] th_1UI          ;
  reg        rx_bmc          ;
  reg [10:0] data_cnt        ;
  reg        data1_flag      ;
  reg        tx_bmc          ;
  reg [ 10:0] pre_rxbit_cnt   ;
  reg        cc_in_d         ;
  reg        cc_data_int_nxt ;
  reg [10:0] UI_ave          ;
  reg [11:0] UI_sum          ;
  reg [ 2:0] ave_cnt         ;
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

  //wires
  wire cc_in_edg     ;
  reg  first_2bit_end;
  reg  cc_in_sync    ;
  wire rxfilt_2n3    ;
  wire rxfilt_dis    ;
  wire cc_in_sync_nxt;
  wire rx_hbit_cmplt ;
  wire rx_lbit_cmplt ;
  wire pre_rxbit_edg ;

  assign rx_pre_cmplt  = rx_pre_en && (pre_rxbit_cnt == `RX_PRE_EDG);
  assign rx_bit_cmplt  = decode_bmc ? rx_hbit_cmplt : rx_lbit_cmplt;
  assign cc_int        = rxfilt_dis ? cc_in_sync : cc_data_int;
  assign cc_int_nxt    = rxfilt_dis ? cc_in_sync_nxt : cc_data_int_nxt;
  assign rx_hbit_cmplt = (rx_hbit_cnt == rx_pre_hbit_time);
  assign rx_lbit_cmplt = (rx_lbit_cnt == rx_pre_lbit_time);

  assign rx_bit5_cmplt = rx_bit_cmplt && (rxbit_cnt == `RX_BIT5_NUM);

  // assign decode_bmc   = rx_bmc;
  assign ic_cc_out    = tx_bmc & ucpden;
  assign rxfilt_2n3   = rxfilte[1];
  assign rxfilt_dis   = rxfilte[0];


  /*------------------------------------------------------------------------------
  --  ic_cc_in synchronization to ucpd_clk
  --  Sync the ic_cc_in bus signals to internal ic_clk, ic_cc_in synchronization
  ------------------------------------------------------------------------------*/
  wire asyn_cc_in_a;
  wire asyn_cc_sync;

  assign asyn_cc_in_a = ic_cc_in & ucpden;
  assign cc_in_sync_nxt   = asyn_cc_sync;
  apb_ucpd_bcm41 #(.RST_VAL(1), .VERIF_EN(0)) u_cc_in_icsyzr (
    .clk_d   (ucpd_clk    ),
    .rst_d_n (ic_rst_n    ),
    .init_d_n(1'b1        ),
    .test    (1'b0        ),
    .data_s  (asyn_cc_in_a),
    .data_d  (asyn_cc_sync)
  );

  /*------------------------------------------------------------------------------
  --  ic_cc_in filtering, filter the inputs from the cc bus
  ------------------------------------------------------------------------------*/
  reg [2:0] cc_in_ored;
  reg cc_in_sync_d0;
  reg cc_in_sync_d1;

  always @(*) begin
    cc_in_ored = {cc_in_sync,cc_in_sync_d0,cc_in_sync_d1};
    if(rxfilt_2n3) // Wait for 2 consistent samples before considering it to be a new level
      case(cc_in_ored[2:1])
        2'b00 : cc_data_int_nxt = 1'b0;
        2'b01 : cc_data_int_nxt = 1'b0;
        2'b10 : cc_data_int_nxt = 1'b0;
        2'b11 : cc_data_int_nxt = 1'b1;
      endcase
    else
      case(cc_in_ored)
        3'b000 : cc_data_int_nxt = 1'b0;
        3'b001 : cc_data_int_nxt = 1'b0;
        3'b010 : cc_data_int_nxt = 1'b0;
        3'b011 : cc_data_int_nxt = 1'b0;
        3'b100 : cc_data_int_nxt = 1'b0;
        3'b101 : cc_data_int_nxt = 1'b0;
        3'b110 : cc_data_int_nxt = 1'b0;
        3'b111 : cc_data_int_nxt = 1'b1;
      endcase
  end

  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(ic_rst_n == 1'b0) begin
      cc_data_int <= 1'b0;
      cc_in_sync <= 1'b0;
    end
    else begin
      cc_data_int <= cc_data_int_nxt;
      cc_in_sync <= cc_in_sync_nxt;
    end
  end

  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(ic_rst_n == 1'b0) begin
      cc_in_sync_d0 <= 1'b0;
      cc_in_sync_d1 <= 1'b0;
    end
    else begin
      cc_in_sync_d0 <= cc_in_sync;
      cc_in_sync_d1 <= cc_in_sync_d0;
    end
  end

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
  always @(posedge ic_clk or negedge ic_rst_n) begin
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
  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      cc_in_d <= 1'b0;
    else
      cc_in_d <= cc_int_nxt; // for generate edg
  end
  assign cc_in_edg = cc_in_d ^ cc_int_nxt;

  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      cc_in_vld <= 1'b0;
    else if(rx_sop_en | rx_data_en)
      cc_in_vld <= 1'b0;
    else if(cc_in_edg)
      cc_in_vld <= 1'b1;
  end

  // begin preamble use 2 bit to count edge, get 3 counter
  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      UI_H_cnt <= 11'b0;
    else if(dec_rxbit_en) begin
      UI_H_cnt <= 11'b0;
    end
    else if(cc_in_vld) begin
      if(cc_int)
        UI_H_cnt <= UI_H_cnt+1;
      else
        UI_H_cnt <= 11'b0;
    end
  end

  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      UI_L_cnt <= 11'b0;
    else if(dec_rxbit_en) begin
      UI_L_cnt <= 11'b0;
    end
    else if(cc_in_vld) begin
      if(~cc_int)
        UI_L_cnt <= UI_L_cnt+1;
      else
        UI_L_cnt <= 11'b0;
    end
  end

  always @(posedge ucpd_clk or negedge ic_rst_n) begin
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


  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(~ic_rst_n) begin
      UI_cntA <= 11'b0;
      UI_cntB <= 11'b0;
      UI_cntC <= 11'b0;
    end
    else if(dec_rxbit_en) begin
      UI_cntA <= 11'b0;
      UI_cntB <= 11'b0;
      UI_cntC <= 11'b0;
    end
    else if(cc_in_vld && cc_in_edg) begin
      case(simple_cnt)
        2'd0 : begin
          if(cc_int)
            UI_cntA <= UI_H_cnt;
          else
            UI_cntA <= UI_L_cnt;
        end
        2'd1 : begin
          if(cc_int)
            UI_cntB <= UI_H_cnt;
          else
            UI_cntB <= UI_L_cnt;
        end
        2'd2 : begin
          if(cc_int)
            UI_cntC <= UI_H_cnt;
          else
            UI_cntC <= UI_L_cnt;
        end
      endcase
    end
  end


  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(~ic_rst_n) begin
      UI_ave  <= 11'b0;
      UI_sum  <= 12'b0;
      ave_cnt <= 3'b0;
    end
    else if(training_en && cc_in_edg) begin
      if(ave_cnt == 3'd7 ) begin
        ave_cnt <= 3'b0;
        UI_ave  <= UI_sum >> 3;
        UI_sum  <= 12'b0;
      end
      else begin
        ave_cnt <= ave_cnt + 1;
        UI_sum  <= UI_sum + th_1UI;
      end
    end
    else if(~training_en) begin
      UI_sum  <= 12'b0;
      ave_cnt <= 3'b0;
    end
   if(~receive_en)
      UI_ave  <= 11'b0;
  end

  // wire [19:0] avg_th_1UI;
  // fir_gaussian_lowpass u_fir_gaussian_lowpass (
  //   .clk     (ucpd_clk),
  //   .rst_n   (ic_rst_n),
  //   .data_in (th_1UI),
  //   .data_out(avg_th_1UI)
  //   );

  // according to sum ,to get 1UI for a bit duty at preamble, 1UI = sum/2*3/4
  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(~ic_rst_n) begin
      training_en <= 1'b0;
      th_1UI      <= 11'b0;
    end
    else if(dec_rxbit_en) begin
      training_en <= 1'b0;
      th_1UI      <= 11'b0;
    end
    else if(first_2bit_end) begin
      if((UI_cntA < UI_cntC) && (UI_cntB < UI_cntC)) begin
        training_en <= 1'b1;
        th_1UI      <= ((UI_cntA+UI_cntB+UI_cntC)*3)>>3; // (a+b+c)/2*3/4
      end
      else if((UI_cntA > UI_cntB) && (UI_cntA > UI_cntC)) begin
        training_en <= 1'b1;
        th_1UI      <= ((UI_cntA+UI_cntB+UI_cntC)*3)>>3; // (a+b+c)/2*3/4
      end
      else if((UI_cntB > UI_cntC) && (UI_cntB > UI_cntA)) begin // b>c,b>a, standing for lost begin 1
        training_en <= 1'b0;
        th_1UI      <= 11'b0;
      end
    end
  end

  /*------------------------------------------------------------------------------
  --  generate recrice bit
  ------------------------------------------------------------------------------*/
  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(~ic_rst_n) begin
      rx_bmc <= 1'b0;
    end
    else if(eop_ok | hrst_vld | crst_vld)
      rx_bmc <= 1'b0;
    else if(cc_in_edg) begin
      if(data_cnt > UI_ave)
        rx_bmc <= 1'b0;
      else if(data1_flag)
        rx_bmc <= 1'b1;
    end
  end

  /*------------------------------------------------------------------------------
  --  decode a bit need counter
  ------------------------------------------------------------------------------*/
  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(~ic_rst_n) begin
      data_cnt   <= 11'b0;
      data1_flag <= 1'b0;
    end
    else if(eop_ok) begin
      data_cnt   <= 11'b0;
      data1_flag <= 1'b0;
    end
    else if(~receive_en) begin
      data_cnt   <= 11'b0;
      data1_flag <= 1'b0;
    end
    else if(cc_in_edg) begin
      if(data_cnt <= UI_ave)
        data1_flag <= 1'b1;
      else
        data1_flag <= 1'b0;
      data_cnt <= 11'b0;
    end
    else if(rx_pre_en | rx_sop_en | rx_data_en)
      data_cnt <= data_cnt+1;
  end

  /*------------------------------------------------------------------------------
  --  for decode bmc bit generate poseedge
  ------------------------------------------------------------------------------*/

  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      decode_bmc <= 1'b0;
    else
      decode_bmc <= rx_bmc;
  end

  assign pre_rxbit_edg = rx_pre_en & (decode_bmc ^ rx_bmc);

  /*------------------------------------------------------------------------------
  --  calculate receive bit edge counter in preamable, tottle 192
  ------------------------------------------------------------------------------*/

  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      pre_rxbit_cnt <= 11'b0;
    else if(rx_pre_cmplt)
      pre_rxbit_cnt <= 11'b0;
    else if(cc_in_vld && cc_in_edg)
      pre_rxbit_cnt <= pre_rxbit_cnt+1;

  end

  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      receive_en <= 1'b0;
    else if(training_en)
      receive_en <= 1'b1;
    else if(receive_en & (eop_ok | (hrst_vld | crst_vld)))
      receive_en <= 1'b0;
  end

  /*------------------------------------------------------------------------------
  --  calculate a receive bit time, to get one bit received complete signal
  ------------------------------------------------------------------------------*/

  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(~ic_rst_n) begin
      rx_pre_hbit_cnt <= 11'b0;
      rx_pre_lbit_cnt <= 11'b0;
    end
    else if(training_en) begin
      if(decode_bmc) begin
        rx_pre_hbit_cnt <= rx_pre_hbit_cnt+1;
        rx_pre_lbit_cnt <= 11'b0;
      end
      else begin
        rx_pre_lbit_cnt <= rx_pre_lbit_cnt+1;
        rx_pre_hbit_cnt <= 11'b0;
      end
    end
  end

  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(~ic_rst_n) begin
      rx_pre_hbit_time <= 11'b0;
      rx_pre_lbit_time <= 11'b0;
    end
    else if(pre_rxbit_edg) begin
      if(decode_bmc)
        rx_pre_hbit_time <= rx_pre_hbit_cnt;
      else
        rx_pre_lbit_time <= rx_pre_lbit_cnt;
    end
  end

  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(~ic_rst_n) begin
      rx_hbit_cnt <= 11'b0;
      rx_lbit_cnt <= 11'b0;
    end
    else if(dec_rxbit_en) begin
      if(decode_bmc) begin
        if(rx_hbit_cmplt)
          rx_hbit_cnt <= 11'b0;
        else begin
          rx_hbit_cnt <= rx_hbit_cnt+1;
          rx_lbit_cnt <= 11'b0;
        end
      end
      else begin
        if(rx_lbit_cmplt)
          rx_lbit_cnt <= 11'b0;
        else begin
          rx_lbit_cnt <= rx_lbit_cnt+1;
          rx_hbit_cnt <= 11'b0;
        end
      end
    end
  end

  /*------------------------------------------------------------------------------
  --  detect sop, data, crc, eop half byte(5bits) recive complete
  ------------------------------------------------------------------------------*/
  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      rxbit_cnt <= 3'b0;
    else if(rx_bit5_cmplt)
      rxbit_cnt <= 3'b0;
    else if(dec_rxbit_en & rx_bit_cmplt)
      rxbit_cnt <= rxbit_cnt+1;
  end



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




















module apb_ucpd_clk_div (
  input        clk_in ,
  input        rst_n  ,
  input  [6:0] divisor, // 分频常数
  output       clk_out
);

  //上升沿和下降沿生成的分频时钟，占空比为（divisor>>1）/divisor，相或操作后可以得到占空比50%的奇分频
  reg        clk_p,clk_n;
  reg        clk_even; //偶分频时钟
  reg  [6:0] cnt     ;
  wire       odd     ;

  assign odd = divisor[0] & 1'b1; //奇数odd判断

  always @(posedge clk_in or negedge rst_n)
    if (!rst_n)
      cnt <= 7'd0;
    else if(cnt >= (divisor - 1))
      cnt <= 7'd0;
    else
      cnt <= cnt + 1'b1;

  //奇分频
  always @( posedge clk_in or negedge rst_n)
    if (!rst_n )
      clk_p <= 1'b0;
    else if(cnt == 7'd0)
      clk_p <= 1'b1;
    else if(cnt == (divisor >> 1))
      clk_p <= 1'b0;

  always @(negedge clk_in or negedge rst_n)
    if (!rst_n )
      clk_n <= 1'b0;
    else if(cnt == 7'd0)
      clk_n <= 1'b1;
    else if(cnt == (divisor >> 1))
      clk_n <= 1'b0;

  //偶分频
  always @(posedge clk_in or negedge rst_n)
    if (!rst_n )
      clk_even <= 1'b0;
    else if(cnt == 7'd0)
      clk_even <= 1'b1;
    else if(cnt == (divisor >> 1))
      clk_even <= 1'b0;

  assign clk_out = (odd) ? (clk_p | clk_n) : clk_even;

endmodule

/*
------------------------------------------------------------------------
--
-- File :                       apb_ucpd_clk_gen.v
-- Author:                      luo kun
-- Date :                       $Date: 2020/07/12 $
// Abstract: This module is used to calculate the required timing and
//           to create the HALF BIT clock when configured as MASTER mode.
-- Modification History:
-- Date                 By      Version Change  Description
-- =====================================================================
-- See CVS log
-- =====================================================================
*/
module apb_ucpd_clk_gen (
  input            ic_clk          , // processor clock
  input            ic_rst_n        , // asynchronous reset, active low
  input            tx_eop_cmplt    ,
  input            tx_sop_rst_cmplt,
  input            transmit_en     ,
  input            bmc_en          ,
  input            wait_en         ,
  input      [4:0] transwin        , // use half bit clock to achieve a legal tTransitionWindow
  input      [4:0] ifrgap          , // Interframe gap
  input      [2:0] psc_usbpdclk    , // Pre-scaler for UCPD_CLK
  input      [5:0] hbitclkdiv      , // Clock divider values to generate a half-bit clock
  output           bit_clk_red     ,
  output           hbit_clk_red    ,
  output           ucpd_clk_red    ,
  output           ucpd_clk        ,
  output           bypass_prescaler,
  output reg       transwin_en     ,
  output reg       ifrgap_en
);

  // ----------------------------------------------------------
  // -- local registers and wires
  // ----------------------------------------------------------
  //registers
  reg [6:0] pre_scaler_cnt;
  reg [6:0] pre_scaler_div;
  reg [5:0] hbit_clk_cnt  ;
  reg [4:0] ifrgap_cnt    ;
  reg [4:0] transwin_cnt  ;
  reg       pre_scaler_clk;
  reg       bit_clk       ;
  reg       bit_clk_r     ;
  reg       hbit_clk_r    ;
  reg       ucpd_clk_r    ;
  reg       transmit_en_d;

  //wires
  wire       hbit_clk_a       ; // half-bit clock
  wire       hbit_clk         ;
  wire       hbit_clk_sync    ;
  wire       hbit_clk_out     ;
  wire [2:0] pre_scaler       ;
  wire [6:0] hbit_div         ;
  wire       bypass_hbitclkdiv;
  wire       transmit_en_edg  ;

  assign hbit_div          = hbitclkdiv+1;
  assign pre_scaler        = psc_usbpdclk;
  assign bypass_prescaler  = (pre_scaler == 3'b0);

  assign bit_clk_red  = ~bit_clk_r & bit_clk;
  assign hbit_clk_red = ~hbit_clk_r & hbit_clk_sync;
  assign ucpd_clk_red = ~ucpd_clk_r & ucpd_clk;
  assign transmit_en_edg = transmit_en_d ^ transmit_en;

  always @(*) begin
    pre_scaler_div = 7'h0;
    case (pre_scaler)
      3'd1 : pre_scaler_div = 7'h1;  // divide by 2
      3'd2 : pre_scaler_div = 7'h2;  // divide by 4
      3'd3 : pre_scaler_div = 7'h4;  // divide by 8
      3'd4 : pre_scaler_div = 7'h8;  // divide by 16
      3'd5 : pre_scaler_div = 7'h10; // divide by 32
      3'd6 : pre_scaler_div = 7'h20; // divide by 64
      3'd7 : pre_scaler_div = 7'h40; // divide by 128
    endcase
  end

  // PSC_USBPDCLK[2:0] = 0x0: Bypass pre-scaling / divide by 1
  assign ucpd_clk = (pre_scaler == 3'b0) ? ic_clk : pre_scaler_clk;

  // HBITCLKDIV[5:0] = 0x0: Divide by 1 to produce HBITCLK
  assign hbit_clk = (hbitclkdiv == 6'b0) ? ucpd_clk : hbit_clk_out;
  // assign hbit_clk_sync = transmit_en_d ? hbit_clk : 1'b0;
  assign hbit_clk_sync = hbit_clk;

  // ----------------------------------------------------------
  // -- Synchronization registers
  // -- transmit_en_red from ic_clk domain Synchroniz to hbit_clk domain
  // ----------------------------------------------------------

  apb_ucpd_clk_div u_hbit_clk (
    .clk_in (ucpd_clk    ),
    .rst_n  (ic_rst_n    ),
    .divisor(hbit_div    ),
    .clk_out(hbit_clk_out)
  );

  /*------------------------------------------------------------------------------
  --  normal package eop and hard_rest or cable reset end at sop, need interframe
  ------------------------------------------------------------------------------*/
  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(ic_rst_n == 1'b0) begin
      ifrgap_cnt <= 5'b0;
      ifrgap_en  <= 1'b0;
    end
    else begin
      if(tx_eop_cmplt || tx_sop_rst_cmplt) begin
        ifrgap_cnt <= 5'b0;
        ifrgap_en  <= 1'b0;
      end
      else if((ucpd_clk_red || bypass_prescaler) && wait_en) begin
        if(ifrgap_cnt < ifrgap) begin
          ifrgap_cnt <= ifrgap_cnt+1;
          ifrgap_en  <= 1'b0;
        end
        else begin
          ifrgap_cnt <= 5'b0;
          ifrgap_en  <= 1'b1;
        end
      end
      else
        ifrgap_en  <= 1'b0;
    end
  end

  always @(posedge hbit_clk_sync or negedge ic_rst_n) begin
    if(ic_rst_n == 1'b0) begin
      transwin_cnt <= 5'b0;
      transwin_en  <= 1'b0;
    end
    else begin
      if(transmit_en_edg) begin
        transwin_cnt <= 5'b0;
        transwin_en  <= 1'b0;
      end
      else if(~bmc_en && ~wait_en) begin
        if(transwin_cnt <= transwin) begin
          transwin_cnt <= transwin_cnt+1;
          transwin_en  <= 1'b0;
        end
        else begin
          transwin_cnt <= 5'b0;
          transwin_en  <= 1'b1;
        end
      end
      else
        transwin_en  <= 1'b0;
    end
  end

  /*------------------------------------------------------------------------------
  --  generate tx bit clk by half bit clk div 2
  ------------------------------------------------------------------------------*/
  always @(posedge hbit_clk_sync or negedge ic_rst_n) begin
    if(~ic_rst_n)
      bit_clk <= 1'b0;
    else
      bit_clk <= ~bit_clk;
  end

  always @(posedge hbit_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      transmit_en_d <= 1'b0;
    else
      transmit_en_d <= transmit_en;
  end

  /*------------------------------------------------------------------------------
  --  generate Clock division by PSC_USBPDCLK[2:0] bits
  ------------------------------------------------------------------------------*/
  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(ic_rst_n == 1'b0) begin
      pre_scaler_cnt <= 7'b0;
      pre_scaler_clk <= 1'b0;
    end
    else if(pre_scaler_div > 0)begin
      if(pre_scaler_cnt == 64)
        pre_scaler_cnt <= 7'b0;
      else if(pre_scaler_cnt < pre_scaler_div-1) begin
        pre_scaler_cnt <= pre_scaler_cnt+1;
      end
      else begin
        pre_scaler_cnt <= 7'b0;
        pre_scaler_clk <= ~pre_scaler_clk;
      end
    end
    else
      pre_scaler_cnt <= 7'b0;
  end

  /*------------------------------------------------------------------------------
  --  generate clk delay for get its postive edge
  ------------------------------------------------------------------------------*/
  always @ (posedge ic_clk or negedge ic_rst_n) begin
    if (~ic_rst_n) begin
      ucpd_clk_r <= 1'b0;
      hbit_clk_r <= 1'b0;
      bit_clk_r  <= 1'b0;
    end
    else begin
      ucpd_clk_r <= ucpd_clk;
      hbit_clk_r <= hbit_clk_sync;
      bit_clk_r  <= bit_clk;
    end
  end

endmodule

  /*------------------------------------------------------------------------------
  --  The modue use to switch clk without glitch
  ------------------------------------------------------------------------------*/
  // module clk_switch (
  //   input  clk_a  , // Clock
  //   input  clk_b  ,
  //   input  select ,
  //   output out_clk
  // );
  //   reg  q1,q2,q3,q4;
  //   wire or_one,or_two,or_three,or_four;

  //   always @(posedge clk_a) begin
  //     if(clk_a == 1'b1) begin
  //       q1 <= q4;
  //       q3 <= or_one;
  //     end
  //   end

  //   always @(posedge clk_b) begin
  //     if(clk_b == 1'b1) begin
  //       q2 <= q3;
  //       q4 <= or_two;
  //     end
  //   end

  //   assign or_one   = (!q1) | (!select);
  //   assign or_two   = (!q2) | (select);
  //   assign or_three = (q3) | (clk_a);
  //   assign or_four  = (q4) | (clk_b);
  //   assign out_clk  = or_three & or_four;
  // endmodule


module apb_ucpd_core (
  input         ic_clk      , //usbpd clock(HSI16)
  input         ic_rst_n    ,
  input         ucpden      ,
  input  [ 4:0] transwin    , // use half bit clock to achieve a legal tTransitionWindow
  input  [ 4:0] ifrgap      , // Interframe gap
  input  [ 2:0] psc_usbpdclk, // Pre-scaler for UCPD_CLK
  input  [ 5:0] hbitclkdiv  , // Clock divider values to generate a half-bit clock
  input         tx_hrst     ,
  input         cc_in       ,
  input         transmit_en ,
  input         rxdr_rd     ,
  input         tx_ordset_we,
  input         txdr_we     ,
  input  [ 8:0] rx_ordset_en,
  input  [ 1:0] tx_mode     ,
  input  [ 1:0] rxfilte     ,
  input  [19:0] tx_ordset   ,
  input  [ 7:0] ic_txdr     ,
  input  [ 9:0] tx_paysize  ,
  output        txhrst_clr  ,
  output        txsend_clr  ,
  output [ 6:0] tx_status   ,
  output [ 5:0] rx_status   ,
  output [ 6:0] rx_ordset   ,
  output [ 9:0] rx_byte_cnt ,
  output [ 7:0] rx_byte     ,
  output        hrst_vld    ,
  output        ic_cc_out   ,
  output        cc_oen
);

  wire        eop_ok          ;
  wire        bit_clk_red     ;
  wire        hbit_clk_red    ;
  wire        ucpd_clk_red    ;
  wire        transwin_en     ;
  wire        ifrgap_en       ;
  wire        drain           ;
  wire        ld_crc_n        ;
  wire [ 7:0] data_in         ;
  wire [31:0] crc_in          ;
  wire        draining        ;
  wire        drain_done      ;
  wire [ 7:0] data_out        ;
  wire [31:0] crc_tx_out      ;
  wire [31:0] crc_tx_in       ;
  wire        tx_hrst_flag    ;
  wire        tx_crst_flag    ;
  wire        pre_en          ;
  wire        bmc_en          ;
  wire        sop_en          ;
  wire        data_en         ;
  wire        crc_en          ;
  wire        eop_en          ;
  wire        bist_en         ;
  wire        txfifo_ld_en    ;
  wire        tx_msg_disc     ;
  wire        tx_hrst_disc    ;
  wire        tx_hrst_red     ;
  wire        tx_crst_red     ;
  wire        tx_bit          ;
  wire        hard_rst        ;
  wire        rx_bit_cmplt    ;
  wire        decode_bmc      ;
  wire        crc_ok          ;
  wire        receive_en      ;
  wire        ic_cc_in        ;
  wire        crst_vld        ;
  wire        dec_rxbit_en    ;
  wire        tx_sop_cmplt    ;
  wire        tx_crc_cmplt    ;
  wire        txdr_req        ;
  wire        rx_bit5_cmplt   ;
  wire        rx_sop_cmplt    ;
  wire        init_n          ;
  wire        enable          ;
  wire        bypass_prescaler;
  wire        pre_rxbit_edg   ;
  wire        rx_pre_cmplt    ;
  wire        tx_wait_cmplt   ;
  wire        tx_sop_rst_cmplt;
  wire        wait_en         ;
  wire        rxfifo_wr_en    ;
  wire        rx_pre_en       ;
  wire        tx_eop_cmplt    ;
  wire        hrst_tx_en      ;

  assign ic_cc_in  = cc_in;
  assign data_in   = receive_en ? rx_byte : ic_txdr;
  assign enable    = receive_en ? rxfifo_wr_en : txfifo_ld_en;
  assign init_n    = receive_en ? ~rx_pre_en : ~pre_en;
  assign crc_tx_in = crc_tx_out;

  apb_ucpd_clk_gen u_apb_ucpd_clk_gen (
    .ic_clk          (ic_clk          ),
    .ic_rst_n        (ic_rst_n        ),
    .tx_eop_cmplt    (tx_eop_cmplt    ),
    .tx_sop_rst_cmplt(tx_sop_rst_cmplt),
    .transmit_en     (transmit_en     ),
    .bmc_en          (bmc_en          ),
    .wait_en         (wait_en         ),
    .transwin        (transwin        ),
    .ifrgap          (ifrgap          ),
    .psc_usbpdclk    (psc_usbpdclk    ),
    .hbitclkdiv      (hbitclkdiv      ),
    .bit_clk_red     (bit_clk_red     ),
    .hbit_clk_red    (hbit_clk_red    ),
    .ucpd_clk_red    (ucpd_clk_red    ),
    .ucpd_clk        (ucpd_clk        ),
    .bypass_prescaler(bypass_prescaler),
    .transwin_en     (transwin_en     ),
    .ifrgap_en       (ifrgap_en       )
  );

  apb_ucpd_bmc_filter u_apb_ucpd_bmc_filter (
    .ic_clk          (ic_clk          ),
    .ic_rst_n        (ic_rst_n        ),
    .ucpden          (ucpden          ),
    .ic_cc_in        (ic_cc_in        ),
    .bit_clk_red     (bit_clk_red     ),
    .hbit_clk_red    (hbit_clk_red    ),
    .ucpd_clk        (ucpd_clk_red    ),
    .ucpd_clk_red    (ucpd_clk_red    ),
    .bypass_prescaler(bypass_prescaler),
    .rxfilte         (rxfilte         ),
    .hrst_vld        (hrst_vld        ),
    .crst_vld        (crst_vld        ),
    .rx_pre_en       (rx_pre_en       ),
    .rx_sop_en       (rx_sop_en       ),
    .rx_data_en      (rx_data_en      ),
    .tx_eop_cmplt    (tx_eop_cmplt    ),
    .eop_ok          (eop_ok          ),
    .pre_en          (pre_en          ),
    .sop_en          (sop_en          ),
    .bmc_en          (bmc_en          ),
    .dec_rxbit_en    (dec_rxbit_en    ),
    .tx_bit          (tx_bit          ),
    .decode_bmc      (decode_bmc      ),
    .ic_cc_out       (ic_cc_out       ),
    .rx_bit_cmplt    (rx_bit_cmplt    ),
    .rx_pre_cmplt    (rx_pre_cmplt    ),
    .rx_bit5_cmplt   (rx_bit5_cmplt   ),
    .receive_en      (receive_en      )
  );

  apb_ucpd_pcrc u_apb_ucpd_pcrc (
    .ic_clk    (ic_clk    ),
    .ic_rst_n  (ic_rst_n  ),
    .init_n    (init_n    ),
    .enable    (enable    ),
    .drain     (drain     ),
    .ld_crc_n  (ld_crc_n  ),
    .data_in   (data_in   ),
    .crc_in    (crc_in    ),
    .draining  (draining  ),
    .drain_done(drain_done),
    .crc_ok    (crc_ok    ),
    .data_out  (data_out  ),
    .crc_out   (crc_tx_out)
  );

  apb_ucpd_data_tx u_apb_ucpd_data_tx (
    .ic_clk       (ic_clk       ),
    .ic_rst_n     (ic_rst_n     ),
    .tx_hrst      (tx_hrst      ),
    .bit_clk_red  (bit_clk_red  ),
    .transmit_en  (transmit_en  ),
    .tx_sop_cmplt (tx_sop_cmplt ),
    .tx_crc_cmplt (tx_crc_cmplt ),
    .tx_wait_cmplt(tx_wait_cmplt),
    .tx_data_cmplt(tx_data_cmplt),
    .tx_eop_cmplt (tx_eop_cmplt ),
    .tx_hrst_flag (tx_hrst_flag ),
    .tx_crst_flag (tx_crst_flag ),
    .txhrst_clr   (txhrst_clr   ),
    .txsend_clr   (txsend_clr   ),
    .hrst_tx_en   (hrst_tx_en   ),
    .txdr_req     (txdr_req     ),
    .pre_en       (pre_en       ),
    .bmc_en       (bmc_en       ),
    .sop_en       (sop_en       ),
    .data_en      (data_en      ),
    .crc_en       (crc_en       ),
    .eop_en       (eop_en       ),
    .bist_en      (bist_en      ),
    .tx_ordset_we (tx_ordset_we ),
    .txfifo_ld_en (txfifo_ld_en ),
    .txdr_we      (txdr_we      ),
    .tx_mode      (tx_mode      ),
    .tx_msg_disc  (tx_msg_disc  ),
    .tx_hrst_disc (tx_hrst_disc ),
    .ic_txdr      (ic_txdr      ),
    .crc_in       (crc_tx_in    ),
    .tx_ordset    (tx_ordset    ),
    .tx_status    (tx_status    ),
    .tx_hrst_red  (tx_hrst_red  ),
    .tx_crst_red  (tx_crst_red  ),
    .tx_bit       (tx_bit       )
  );

  apb_ucpd_data_rx u_apb_ucpd_data_rx (
    .ic_clk       (ic_clk       ),
    .ucpd_clk     (ucpd_clk     ),
    .ic_rst_n     (ic_rst_n     ),
    .hard_rst     (hard_rst     ),
    .rx_bit5_cmplt(rx_bit5_cmplt),
    .rx_bit_cmplt (rx_bit_cmplt ),
    .rx_pre_en    (rx_pre_en    ),
    .rx_sop_en    (rx_sop_en    ),
    .rx_data_en   (rx_data_en   ),
    .rxdr_rd      (rxdr_rd      ),
    .decode_bmc   (decode_bmc   ),
    .crc_ok       (crc_ok       ),
    .dec_rxbit_en (dec_rxbit_en ),
    .rx_ordset_en (rx_ordset_en ),
    .rx_status    (rx_status    ),
    .rx_ordset    (rx_ordset    ),
    .rxfifo_wr_en (rxfifo_wr_en ),
    .rx_sop_cmplt (rx_sop_cmplt ),
    .rx_byte_cnt  (rx_byte_cnt  ),
    .hrst_vld     (hrst_vld     ),
    .crst_vld     (crst_vld     ),
    .eop_ok       (eop_ok       ),
    .rx_byte      (rx_byte      )
  );

  apb_ucpd_fsm u_apb_ucpd_fsm (
    .ic_clk          (ic_clk          ),
    .ucpd_clk        (ucpd_clk        ),
    .ic_rst_n        (ic_rst_n        ),
    .ucpden          (ucpden          ),
    .tx_hrst         (tx_hrst         ),
    .transmit_en     (transmit_en     ),
    .receive_en      (receive_en      ),
    .eop_ok          (eop_ok          ),
    .bit_clk_red     (bit_clk_red     ),
    .tx_paysize      (tx_paysize      ),
    .crc_ok          (crc_ok          ),
    .rx_bit_cmplt    (rx_bit_cmplt    ),
    .rx_sop_cmplt    (rx_sop_cmplt    ),
    .pre_rxbit_edg   (pre_rxbit_edg   ),
    .tx_mode         (tx_mode         ),
    .tx_status       (tx_status       ),
    .transwin_en     (transwin_en     ),
    .ifrgap_en       (ifrgap_en       ),
    .tx_hrst_red     (tx_hrst_red     ),
    .tx_crst_red     (tx_crst_red     ),
    .rx_pre_cmplt    (rx_pre_cmplt    ),
    .hrst_vld        (hrst_vld        ),
    .crst_vld        (crst_vld        ),
    .tx_hrst_flag    (tx_hrst_flag    ),
    .tx_crst_flag    (tx_crst_flag    ),
    .hrst_tx_en      (hrst_tx_en      ),
    .bmc_en          (bmc_en          ),
    .tx_sop_cmplt    (tx_sop_cmplt    ),
    .tx_wait_cmplt   (tx_wait_cmplt   ),
    .tx_crc_cmplt    (tx_crc_cmplt    ),
    .tx_data_cmplt   (tx_data_cmplt   ),
    .tx_sop_rst_cmplt(tx_sop_rst_cmplt),
    .tx_eop_cmplt    (tx_eop_cmplt    ),
    .tx_msg_disc     (tx_msg_disc     ),
    .tx_hrst_disc    (tx_hrst_disc    ),
    .txfifo_ld_en    (txfifo_ld_en    ),
    .cc_oen          (cc_oen          ),
    .dec_rxbit_en    (dec_rxbit_en    ),
    .txdr_req        (txdr_req        ),
    .rx_pre_en       (rx_pre_en       ),
    .rx_sop_en       (rx_sop_en       ),
    .rx_data_en      (rx_data_en      ),
    .pre_en          (pre_en          ),
    .sop_en          (sop_en          ),
    .data_en         (data_en         ),
    .crc_en          (crc_en          ),
    .eop_en          (eop_en          ),
    .wait_en         (wait_en         ),
    .bist_en         (bist_en         )
  );


endmodule
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
  input            ic_clk       , // processor clock
  input            ucpd_clk     ,
  input            ic_rst_n     , // asynchronous reset, active low
  input            hard_rst     ,
  input            rx_bit5_cmplt,
  input            rx_bit_cmplt ,
  input            rx_pre_en    ,
  input            rx_sop_en    ,
  input            rx_data_en   ,
  input            rxdr_rd      ,
  input            decode_bmc   ,
  input            crc_ok       ,
  input            dec_rxbit_en ,
  input      [8:0] rx_ordset_en ,
  output           rx_sop_cmplt ,
  output     [5:0] rx_status    ,
  output     [6:0] rx_ordset    ,
  output           rxfifo_wr_en ,
  output reg [9:0] rx_byte_cnt  ,
  output reg       hrst_vld     ,
  output reg       crst_vld     ,
  output reg       eop_ok       ,
  output reg [7:0] rx_byte
);

  // `include "parameter_def.v"

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
  reg        rx_bit5_cmplt_d     ;
  reg        rx_sop_en_d         ;
  reg [ 1:0] rx_sop_half_byte_cnt;
  reg [ 7:0] rx_data             ;
  reg        rx_1byte_cmplt      ;
  reg        rx_data_en_d        ;
  reg        rx_1byte_cmplt_d    ;
  reg        rx_sop_cmplt_d      ;
  reg [ 1:0] rx_hafbyte_cnt      ;

  // wire
  wire       rx_msg_end       ;
  wire       rx_err           ;
  wire       rx_hrst_det      ;
  wire       rx_ordset_vld    ;
  wire       rx_full          ;
  wire       sop_ex1_vld      ;
  wire       sop_ex2_vld      ;
  wire [7:0] rx_byte_nxt      ;
  wire [3:0] sop_num_ok_nxt   ;
  wire [7:0] rx_ordset_vld_nxt;

  // todo
  assign sop_ex1_vld = 1'b0;
  assign sop_ex2_vld = 1'b0;

  assign rx_ovrflow        = rxfifo_full & rxfifo_wr_en & rx_data_en;
  assign rx_err            = eop_ok & ~crc_ok;
  assign rx_msg_end        = eop_ok;
  assign rx_hrst_det       = hrst_vld;
  assign rx_ordset_vld     = sop0_vld | sop1_vld | sop2_vld | sop1_deg_vld | sop2_deg_vld | crst_vld;
  assign rx_full           = rxfifo_full & rx_data_en;
  assign rx_status         = {rx_err,rx_msg_end,rx_ovrflow,rx_hrst_det,rx_ordset_vld,rx_full};
  assign rx_ordset         = {rx_sop_invld_num,rx_sop_3of4,rx_ordset_det};
  assign rx_sop_cmplt      = rx_bit5_cmplt && (rx_sop_half_byte_cnt == `SOP_HBYTE_NUM-1);
  assign rxfifo_wr_en      = rx_1byte_cmplt_d & ~rx_1byte_cmplt;
  assign rx_byte_nxt       = ~rx_5bits_cnt[0] ? rx_data : rx_byte;
  assign sop_num_ok_nxt    = {sop_1st_ok,sop_2st_ok,sop_3st_ok,sop_4st_ok};
  assign rx_ordset_vld_nxt = {sop_ex2_vld,sop_ex1_vld,crst_vld,sop2_deg_vld,sop1_deg_vld,sop2_vld,sop1_vld,sop0_vld};

  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      rx_byte <= 8'b0;
    else
      rx_byte <= rx_byte_nxt;
  end

  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      rx_1byte_cmplt_d <= 1'b0;
    else
      rx_1byte_cmplt_d <= rx_1byte_cmplt;
  end

  /*------------------------------------------------------------------------------
  --  use rxfifo_wr_en signal in the rx_data phase to count the number receive data
  --  the rx_byte_cnt sent to SW means RX_PAYSZ register
  ------------------------------------------------------------------------------*/
  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      rx_byte_cnt  <= 10'b0;
    else if(rx_sop_en)
       rx_byte_cnt  <= 10'b0;
    else if(rxfifo_wr_en && rx_data_en)
      rx_byte_cnt  <= rx_byte_cnt+1;
  end

  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      rx_data_en_d <= 1'b0;
    else
      rx_data_en_d <= rx_data_en;
  end

  /*------------------------------------------------------------------------------
  --  according rxdr read and txfifo write to generate rxfifo's status
  --  0: rxfifo empty, 1: rxfifo is not empty (RXNE)
  ------------------------------------------------------------------------------*/
  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      rxfifo_full <= 1'b0;
    else if(rxdr_rd)
      rxfifo_full <= 1'b0;
    else if(rxfifo_wr_en)
      rxfifo_full <= 1'b1;
  end
  /*------------------------------------------------------------------------------
  --  The header is considered to be part of the payload, but CRC is not counted
  --  rx_data send to SW as rxdr value
  ------------------------------------------------------------------------------*/
  always @(*) begin
    if(~ic_rst_n)
      rx_data = 8'b0;
    else if(eop_ok)
      rx_data = 8'b0;
    else if(rx_5bits_cnt[0] & rx_data_en)
      rx_data[3:0] = decode_4b;
    else
      rx_data[7:4] = decode_4b;
  end

  /*------------------------------------------------------------------------------
  --  receive half byte data(message data, crc, `EOP) get latest from 5 bits fifo
  ------------------------------------------------------------------------------*/
  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(~ic_rst_n) begin
      rx_5bits     <= 5'b0;
      rx_5bits_cnt <= 10'b0;
    end
    else if(rx_pre_en) begin
      rx_5bits     <= 5'b0;
      rx_5bits_cnt <= 10'b0;
    end
    else if(rx_data_en_d & rx_bit5_cmplt_d) begin
      rx_5bits     <= bmc_rx_shift;
      rx_5bits_cnt <= rx_5bits_cnt+1;
    end
  end

  /*------------------------------------------------------------------------------
  --  count 2 half byte means one byte received, use one byte received complete to
  --  generate wrfifo status singal to infrom SW need read RXDR register
  ------------------------------------------------------------------------------*/
  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(~ic_rst_n) begin
      rx_1byte_cmplt <= 1'b0;
      rx_hafbyte_cnt <= 2'b0;
    end
    else if(eop_ok) begin
      rx_1byte_cmplt <= 1'b0;
      rx_hafbyte_cnt <= 2'b0;
    end
    else if(rx_data_en_d & rx_bit5_cmplt_d) begin
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
  --  when rx_sop_cmplt_d valid registe RX_ORDSET
  ------------------------------------------------------------------------------*/
  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(~ic_rst_n) begin
      rx_sop_invld_num <= 3'd0;
      rx_sop_3of4      <= 1'd0;
    end
    // else if(eop_ok) begin
    //   rx_sop_invld_num <= 3'd0;
    //   rx_sop_3of4      <= 1'd0;
    // end
    else if(rx_sop_cmplt_d && rx_data_en_d) begin
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
        default : rx_sop_invld_num <= 3'd7; // Other values: Invalid
      endcase
    end
  end

  /*------------------------------------------------------------------------------
  --  when rx_sop_cmplt_d valid registe RX_ORDSET(RXORDSET[2:0])
  ------------------------------------------------------------------------------*/
  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      rx_ordset_det <= 3'd0;
    // else if(eop_ok)
    //   rx_ordset_det <= 3'd0;
    else if(rx_sop_cmplt_d) begin
      case(rx_ordset_vld_nxt & rx_ordset_en)
        8'b0000_0001 : rx_ordset_det <= 3'd0; // 0x0: SOP code detected in receiver
        8'b0000_0010 : rx_ordset_det <= 3'd1; // 0x1: SOP' code detected in receiver
        8'b0000_0100 : rx_ordset_det <= 3'd2; // 0x2: SOP'' code detected in receiver
        8'b0000_1000 : rx_ordset_det <= 3'd3; // 0x3: SOP'_Debug detected in receiver
        8'b0001_0000 : rx_ordset_det <= 3'd4; // 0x4: SOP''_Debug detected in receiver
        8'b0010_0000 : rx_ordset_det <= 3'd5; // 0x5: Cable Reset detected in receiver
        8'b0100_0000 : rx_ordset_det <= 3'd6; // 0x6: SOP extension#1 detected in receiver
        8'b1000_0000 : rx_ordset_det <= 3'd7; // 0x7: SOP extension#2 detected in receiver
        default : rx_ordset_det <= 3'd0;
      endcase
    end
  end

  /*------------------------------------------------------------------------------
  --   when sop received complete, we need 4 sop k code to check it
  ------------------------------------------------------------------------------*/
  reg [4:0] sop_k1_code_nxt;
  reg [4:0] sop_k2_code_nxt;
  reg [4:0] sop_k3_code_nxt;
  reg [4:0] sop_k4_code_nxt;
  reg sop_k1_rd;
  reg sop_k2_rd;
  reg sop_k3_rd;
  reg sop_k4_rd;
  always @(*) begin
    sop_k1_code_nxt = 5'b0;
    sop_k2_code_nxt = 5'b0;
    sop_k3_code_nxt = 5'b0;
    sop_k4_code_nxt = 5'b0;
    sop_k1_rd       = 1'b0;
    sop_k2_rd       = 1'b0;
    sop_k3_rd       = 1'b0;
    sop_k4_rd       = 1'b0;
    if(rx_bit5_cmplt_d && rx_sop_en_d) begin
      case(rx_sop_half_byte_cnt)
        2'b00 : begin
          sop_k1_code_nxt = bmc_rx_shift;
          sop_k1_rd       = 1'b1;
        end
        2'b01 : begin
          sop_k2_code_nxt = bmc_rx_shift;
          sop_k2_rd       = 1'b1;
        end
        2'b10 : begin
          sop_k3_code_nxt = bmc_rx_shift;
          sop_k3_rd       = 1'b1;
        end
        2'b11 : begin
          sop_k4_code_nxt = bmc_rx_shift;
          sop_k4_rd       = 1'b1;
        end
      endcase
    end
  end

  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(~ic_rst_n) begin
      sop_k1_code <= 5'b0;
      sop_k2_code <= 5'b0;
      sop_k3_code <= 5'b0;
      sop_k4_code <= 5'b0;
    end
    // else if(rx_hrst_det) begin
    //   sop_k1_code <= 5'b0;
    //   sop_k2_code <= 5'b0;
    //   sop_k3_code <= 5'b0;
    //   sop_k4_code <= 5'b0;
    // end
    else if(sop_k1_rd)
      sop_k1_code <= sop_k1_code_nxt;
    else if(sop_k2_rd)
      sop_k2_code <= sop_k2_code_nxt;
    else if(sop_k3_rd)
      sop_k3_code <= sop_k3_code_nxt;
    else if(sop_k4_rd)
      sop_k4_code <= sop_k4_code_nxt;
  end


  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      eop_ok <= 1'b0;
    // else if(rx_hrst_det | eop_ok)
    //   eop_ok <= 1'b0;
    else
      eop_ok <= eop_ok_nxt;
  end

  /*------------------------------------------------------------------------------
  --   wheather ordered set detect and Invalid number, `EOP K code detect
  ------------------------------------------------------------------------------*/
  always @(*) begin
    sop_1st_ok = 1'b0;
    sop_2st_ok = 1'b0;
    sop_3st_ok = 1'b0;
    sop_4st_ok = 1'b0;
    eop_ok_nxt = 1'b0;
    if(rx_sop_en_d && rx_data_en_d) begin
      case(sop_k1_code)
        `SYNC_1, `SYNC_2, `SYNC_3, `RST_1, `RST_2 : sop_1st_ok = 1'b1;
        `EOP     : eop_ok_nxt = 1'b1;
        default : begin
          sop_1st_ok = 1'b0;
          eop_ok_nxt = 1'b0;
        end
      endcase

      case(sop_k2_code)
        `SYNC_1, `SYNC_2, `SYNC_3, `RST_1, `RST_2 : sop_2st_ok = 1'b1;
        `EOP     : eop_ok_nxt = 1'b1;
        default : begin
          sop_2st_ok = 1'b0;
          eop_ok_nxt = 1'b0;
        end
      endcase

      case(sop_k3_code)
        `SYNC_1, `SYNC_2, `SYNC_3, `RST_1, `RST_2 : sop_3st_ok = 1'b1;
        `EOP     : eop_ok_nxt = 1'b1;
        default : begin
          sop_3st_ok = 1'b0;
          eop_ok_nxt = 1'b0;
        end
      endcase

      case(sop_k4_code)
        `SYNC_1, `SYNC_2, `SYNC_3, `RST_1, `RST_2 : sop_4st_ok = 1'b1;
        `EOP     : eop_ok_nxt = 1'b1;
        default : begin
          sop_4st_ok = 1'b0;
          eop_ok_nxt = 1'b0;
        end
      endcase
    end
    else if(rx_data_en) begin
      if(rx_5bits == `EOP)
        eop_ok_nxt = 1'b1;
      else
        eop_ok_nxt = 1'b0;
    end
  end

  /*------------------------------------------------------------------------------
  --  Rx ordered set code detected
  ------------------------------------------------------------------------------*/
  always @(*) begin
    sop0_vld     = 1'b0; // SOP code detected in receiver
    sop1_vld     = 1'b0; // SOP' code detected in receiver
    sop1_deg_vld = 1'b0; // SOP'_Debug detected in receiver
    sop2_vld     = 1'b0; // SOP'' code detected in receiver
    sop2_deg_vld = 1'b0; // SOP''_Debug detected in receiver
    crst_vld     = 1'b0; // Cable Reset detected in receiver
    hrst_vld     = 1'b0; // Hard Reset detected in receiver
    if(rx_sop_en_d && rx_sop_cmplt_d) begin
      if(((sop_k1_code == `SYNC_1) & (sop_k2_code == `SYNC_1) & (sop_k3_code == `SYNC_1)) |
        ((sop_k1_code == `SYNC_1) & (sop_k2_code == `SYNC_1) & (sop_k4_code == `SYNC_2)) |
        ((sop_k1_code == `SYNC_1) & (sop_k3_code == `SYNC_1) & (sop_k4_code == `SYNC_2)) |
        ((sop_k2_code == `SYNC_1) & (sop_k3_code == `SYNC_1) & (sop_k4_code == `SYNC_2)))
        sop0_vld = 1'b1;
      else
        sop0_vld = 1'b0;

      if(((sop_k1_code == `SYNC_1) & (sop_k2_code == `SYNC_1) & (sop_k3_code == `SYNC_3)) |
        ((sop_k1_code == `SYNC_1) & (sop_k2_code == `SYNC_1) & (sop_k4_code == `SYNC_3)) |
        ((sop_k1_code == `SYNC_1) & (sop_k3_code == `SYNC_3) & (sop_k4_code == `SYNC_3)) |
        ((sop_k2_code == `SYNC_1) & (sop_k3_code == `SYNC_3) & (sop_k4_code == `SYNC_3)))
        sop1_vld = 1'b1;
      else
        sop1_vld = 1'b0;

      if(((sop_k1_code == `SYNC_1) & (sop_k2_code == `RST_2) & (sop_k3_code == `RST_2 )) |
        ((sop_k1_code == `SYNC_1) & (sop_k2_code == `RST_2) & (sop_k4_code == `SYNC_3)) |
        ((sop_k1_code == `SYNC_1) & (sop_k3_code == `RST_2) & (sop_k4_code == `SYNC_3)) |
        ((sop_k2_code == `RST_2 ) & (sop_k3_code == `RST_2) & (sop_k4_code == `SYNC_3)))
        sop1_deg_vld = 1'b1;
      else
        sop1_deg_vld = 1'b0;

      if(((sop_k1_code == `SYNC_1) & (sop_k2_code == `SYNC_3) & (sop_k3_code == `SYNC_1)) |
        ((sop_k1_code == `SYNC_1) & (sop_k2_code == `SYNC_3) & (sop_k4_code == `SYNC_3)) |
        ((sop_k1_code == `SYNC_1) & (sop_k3_code == `SYNC_1) & (sop_k4_code == `SYNC_3)) |
        ((sop_k2_code == `SYNC_3) & (sop_k3_code == `SYNC_1) & (sop_k4_code == `SYNC_3)))
        sop2_vld = 1'b1;
      else
        sop2_vld = 1'b0;

      if(((sop_k1_code == `SYNC_1) & (sop_k2_code == `RST_2 ) & (sop_k3_code == `SYNC_3)) |
        ((sop_k1_code == `SYNC_1) & (sop_k2_code == `RST_2 ) & (sop_k4_code == `SYNC_2)) |
        ((sop_k1_code == `SYNC_1) & (sop_k3_code == `SYNC_3) & (sop_k4_code == `SYNC_2)) |
        ((sop_k2_code == `SYNC_1) & (sop_k3_code == `SYNC_3) & (sop_k4_code == `SYNC_2)))
        sop2_deg_vld = 1'b1;
      else
        sop2_deg_vld = 1'b0;

      if(((sop_k1_code == `RST_1 )  & (sop_k2_code == `SYNC_1) & (sop_k3_code == `RST_1 )) |
        ((sop_k1_code == `RST_1 ) & (sop_k2_code == `SYNC_1) & (sop_k4_code == `SYNC_3)) |
        ((sop_k1_code == `RST_1 ) & (sop_k3_code == `RST_1 ) & (sop_k4_code == `SYNC_3)) |
        ((sop_k2_code == `SYNC_1) & (sop_k3_code == `RST_1 ) & (sop_k4_code == `SYNC_3)))
        crst_vld = 1'b1;
      else
        crst_vld = 1'b0;

      if(((sop_k1_code == `RST_1 ) & (sop_k2_code == `RST_1) & (sop_k3_code == `RST_1)) |
        ((sop_k1_code == `RST_1 ) & (sop_k2_code == `RST_1) & (sop_k4_code == `RST_2)) |
        ((sop_k1_code == `RST_1 ) & (sop_k3_code == `RST_1) & (sop_k4_code == `RST_2)) |
        ((sop_k2_code == `RST_1 ) & (sop_k3_code == `RST_1) & (sop_k4_code == `RST_2)))
        hrst_vld = 1'b1;
      else
        hrst_vld = 1'b0;
    end
  end

  /*------------------------------------------------------------------------------
  --  5 bit fifo receive BMC data, when sop, data, `EOP phase
  ------------------------------------------------------------------------------*/
  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      bmc_rx_shift  <= 5'b0;
    else if(dec_rxbit_en & rx_bit_cmplt)
      bmc_rx_shift <= {decode_bmc, bmc_rx_shift[4:1]};
  end

  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(~ic_rst_n) begin
      rx_bit5_cmplt_d <= 1'b0;
      rx_sop_cmplt_d  <= 1'b0;
      rx_sop_en_d     <= 1'b0;
    end
    else begin
      rx_bit5_cmplt_d <= rx_bit5_cmplt;
      rx_sop_cmplt_d  <= rx_sop_cmplt;
      rx_sop_en_d     <= rx_sop_en;
    end
  end

  /*------------------------------------------------------------------------------
  --  count sop, data, crc, `EOP half byte(5bits) recive number
  ------------------------------------------------------------------------------*/
  always @(posedge ucpd_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      rx_sop_half_byte_cnt <= 2'b0;
    else if(rx_sop_cmplt_d)
      rx_sop_half_byte_cnt <= 2'b0;
    else if(rx_sop_en_d & rx_bit5_cmplt_d)
      rx_sop_half_byte_cnt <= rx_sop_half_byte_cnt+1;
  end

  /*------------------------------------------------------------------------------
  --  according received 5bits data decode 4bits data (message, crc)
  ------------------------------------------------------------------------------*/
  always @(*) begin
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

endmodule


/*
------------------------------------------------------------------------
--
-- File :                       apb_ucpd_data_tx.v
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
module apb_ucpd_data_tx (
  input             ic_clk       , // processor clock
  input             ic_rst_n     , // asynchronous reset, active low
  input             tx_hrst      ,
  input             bit_clk_red  ,
  input             transmit_en  ,
  input             tx_sop_cmplt ,
  input             tx_crc_cmplt ,
  input             tx_wait_cmplt,
  input             tx_data_cmplt,
  input             tx_eop_cmplt ,
  input             txdr_req     ,
  input             pre_en       ,
  input             bmc_en       ,
  input             sop_en       ,
  input             data_en      ,
  input             crc_en       ,
  input             eop_en       ,
  input             bist_en      ,
  input             tx_ordset_we ,
  input             txfifo_ld_en ,
  input             txdr_we      ,
  input      [ 1:0] tx_mode      ,
  input             tx_msg_disc  ,
  input             tx_hrst_disc ,
  input      [ 7:0] ic_txdr      ,
  input      [31:0] crc_in       ,
  input      [19:0] tx_ordset    , // consisting of 4 K-codes for sop, from UCPD_TX_ORDSET
  output     [ 6:0] tx_status    ,
  output            tx_hrst_red  ,
  output            tx_crst_red  ,
  output reg        tx_hrst_flag ,
  output reg        tx_crst_flag ,
  output reg        txhrst_clr   ,
  output reg        txsend_clr   ,
  output reg        hrst_tx_en   ,
  output reg        tx_bit
);

  // `include "parameter_def.v"

  // ----------------------------------------------------------
  // -- local registers and wires
  // ----------------------------------------------------------
  //registers
  reg [127:0] pre_shift     ;
  reg [ 39:0] tx_crc_40bits ;
  reg [  9:0] tx_data_10bits;
  reg [ 19:0] sop_shift     ;
  reg [  9:0] data_shift    ;
  reg [ 39:0] crc_shift     ;
  reg [  4:0] eop_shift     ;
  reg         txfifo_full   ;
  reg         txdr_we_d     ;

  //wires nets
  wire tx_und         ;
  wire tx_int_empty   ;
  wire tx_msg_sent    ;
  wire hrst_sent      ;
  wire transmit_en_red;

  assign tx_und       = ~txfifo_full & txfifo_ld_en & data_en;
  assign tx_int_empty = ~txfifo_full & txdr_req & data_en;
  assign tx_msg_abt   = tx_hrst_red & (sop_en | data_en | crc_en);
  assign tx_msg_sent  = tx_wait_cmplt & ~tx_hrst_flag;
  assign hrst_sent    = tx_sop_cmplt & tx_hrst_flag;
  assign tx_crst      = (tx_mode == 2'b01);
  assign tx_bist      = (tx_mode == 2'b10);

  assign tx_status = {tx_und, hrst_sent,tx_hrst_disc,tx_msg_abt,tx_msg_sent,tx_msg_disc,tx_int_empty};

  reg bit_clk_red_d;
  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      bit_clk_red_d <= 1'b0;
    else
      bit_clk_red_d <= bit_clk_red;
  end

  reg transmit_en_r;
  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      transmit_en_r <= 1'b0;
    else
      transmit_en_r <= transmit_en;
  end

  assign transmit_en_red = ~transmit_en_r & transmit_en;

  /*------------------------------------------------------------------------------
  --  generate tx_hrst, tx_crst, tx_bist positive edge
  ------------------------------------------------------------------------------*/
  reg tx_hrst_r;
  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      tx_hrst_r <= 1'b0;
    else
      tx_hrst_r <= tx_hrst;
  end

  assign tx_hrst_red = ~tx_hrst_r & tx_hrst;
  assign tx_hrst_edg = tx_hrst_r ^ tx_hrst;

  reg tx_crst_r;
  always @(posedge ic_clk or posedge ic_rst_n) begin
    if(~ic_rst_n)
      tx_crst_r <= 1'b0;
    else
      tx_crst_r <= tx_crst;
  end
  assign tx_crst_red = ~tx_crst_r & tx_crst;

  reg [1:0] tx_bist_r;
  always @(posedge ic_clk or posedge ic_rst_n) begin
    if(~ic_rst_n)
      tx_bist_r <= 2'b0;
    else
      tx_bist_r <= {tx_bist_r[0], tx_bist};
  end
  assign tx_bist_red = ~tx_bist_r[1] & tx_bist_r[0];
  /*------------------------------------------------------------------------------
  --  according txdr write and txfifo read to generate txfifo's status
  --  0: txfifo empty, 1: txfifo is not empty
  ------------------------------------------------------------------------------*/
  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      txfifo_full <= 1'b0;
    else if(txdr_we_d)
      txfifo_full <= 1'b1;
    else if(txfifo_ld_en)
      txfifo_full <= 1'b0;
  end

  /*------------------------------------------------------------------------------
  --  This fifo is used to store tx data from SW writed, data 4b5b Symbol Encoding
  ------------------------------------------------------------------------------*/
  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      txdr_we_d <= 1'b0;
    else
      txdr_we_d <= txdr_we;
  end

  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      tx_data_10bits <= 10'b0;
    else if(tx_hrst_red)
      tx_data_10bits <= 10'b0;
    else if(txdr_we_d) begin
      tx_data_10bits[9:5] <= enc_4b5b(ic_txdr[7:4]);
      tx_data_10bits[4:0] <= enc_4b5b(ic_txdr[3:0]);
    end
  end

  /*------------------------------------------------------------------------------
  --  generate last tx bit
  ------------------------------------------------------------------------------*/
  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      tx_bit <= 1'b0;
    else if(bit_clk_red_d) begin
      if(pre_en)
        tx_bit <= pre_shift[0];
      else if(sop_en)
        tx_bit <= sop_shift[0];
      else if(data_en)
        tx_bit <= data_shift[0];
      else if(crc_en)
        tx_bit <= crc_shift[0];
      else if(eop_en)
        tx_bit <= eop_shift[0];
    end
  end

  /*------------------------------------------------------------------------------
  --  generate preamble code, bit=1 number is 64, bit=0 number is 64, totle bit is 128
  ------------------------------------------------------------------------------*/
  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      pre_shift <= 128'b0;
    else if(transmit_en_red | tx_hrst_red | tx_crst_red | tx_sop_cmplt)
      pre_shift <= {64{2'b10}};
    else if(pre_en & bit_clk_red)
      pre_shift <= {1'b0, pre_shift[127:1]};
  end

  /*------------------------------------------------------------------------------
  --  according tx order set value to shift sop bit
  --  Hard Reset: Preamle RST-1 RST-1 RST-1 RST-2, transmit RST-2 RST-1 RST-1 RST-1
  --  Cable Reset: Preamble(training for receiver) RST-1 Sync-1 RST-1 Sync-3, transmit
  --  Sync-3 RST-1 Sync-1 RST-1
  ------------------------------------------------------------------------------*/
  reg tx_ordset_we_d;
  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      tx_ordset_we_d <= 1'b0;
    else
      tx_ordset_we_d <= tx_ordset_we;
  end

  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      sop_shift <= 20'b0;
    else if(tx_hrst_red)
      sop_shift <= {`RST_2,`RST_1,`RST_1,`RST_1};
    else if(tx_crst_red || (pre_en && tx_crst))
      sop_shift <= {`SYNC_3,`RST_1,`SYNC_1,`RST_1};
    else if(tx_ordset_we_d)
      sop_shift <= tx_ordset;
    else if(sop_en & bit_clk_red)
      sop_shift <= {1'b0, sop_shift[19:1]};
  end

  /*------------------------------------------------------------------------------
  --  according encode tx data to shift data bit
  ------------------------------------------------------------------------------*/
  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      data_shift <= 10'b0;
    else if(txfifo_ld_en)
      data_shift <= tx_data_10bits;
    else if(data_en & bit_clk_red)
      data_shift <= {1'b0, data_shift[9:1]};
  end

  /*------------------------------------------------------------------------------
  --  according encode tx crc to shift crc bit
  ------------------------------------------------------------------------------*/
  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      crc_shift <= 40'b0;
    else if(tx_data_cmplt)
      crc_shift <= tx_crc_40bits;
    else if(crc_en & bit_clk_red)
      crc_shift <= {1'b0, crc_shift[39:1]};
  end

  /*------------------------------------------------------------------------------
  --  according `EOP to shift `EOP bit
  ------------------------------------------------------------------------------*/
  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      eop_shift <= 5'b0;
    else if(tx_crc_cmplt | tx_hrst_red)
      eop_shift <= `EOP;
    else if(eop_en & bit_clk_red)
      eop_shift <= {1'b0, eop_shift[4:1]};
  end

  /*------------------------------------------------------------------------------
  --  transform crc data(32bits) 4bits to 5bits
  ------------------------------------------------------------------------------*/
  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      tx_crc_40bits <= 40'b0;
    else begin
      tx_crc_40bits[4:0]   <= enc_4b5b(crc_in[ 3: 0]);
      tx_crc_40bits[9:5]   <= enc_4b5b(crc_in[ 7: 4]);
      tx_crc_40bits[14:10] <= enc_4b5b(crc_in[11: 8]);
      tx_crc_40bits[19:15] <= enc_4b5b(crc_in[15:12]);
      tx_crc_40bits[24:20] <= enc_4b5b(crc_in[19:16]);
      tx_crc_40bits[29:25] <= enc_4b5b(crc_in[23:20]);
      tx_crc_40bits[34:30] <= enc_4b5b(crc_in[27:24]);
      tx_crc_40bits[39:35] <= enc_4b5b(crc_in[31:28]);
    end
  end

  /*------------------------------------------------------------------------------
  --  for fsm to generate tx hrst flag tx crst flag ,claer and hrest enable
  ------------------------------------------------------------------------------*/
  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      tx_hrst_flag <= 1'b0;
    else if(tx_hrst_red)
      tx_hrst_flag <= 1'b1;
    else if(tx_hrst_flag & tx_sop_cmplt)
      tx_hrst_flag <= 1'b0;
  end

  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      tx_crst_flag <= 1'b0;
    else if(tx_crst_red || (pre_en && tx_crst))
      tx_crst_flag <= 1'b1;
    else if(tx_crst_flag & tx_sop_cmplt)
      tx_crst_flag <= 1'b0;
  end

  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      txhrst_clr <= 1'b0;
    else if((tx_hrst && (pre_en || sop_en || data_en || crc_en)) || tx_hrst_disc)
      txhrst_clr <= 1'b1;
    else
      txhrst_clr <= 1'b0;
  end

  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      txsend_clr <= 1'b0;
    else if((transmit_en & (tx_eop_cmplt | tx_wait_cmplt)) || tx_msg_disc)
      txsend_clr <= 1'b1;
    else
      txsend_clr <= 1'b0;
  end

  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      hrst_tx_en <= 1'b0;
    else if(tx_hrst_flag & tx_eop_cmplt)
      hrst_tx_en <= 1'b1;
    else if(hrst_tx_en & tx_sop_cmplt)
      hrst_tx_en <= 1'b0;
  end

  function [4:0] enc_4b5b (input [3:0] tx_4bits);
    begin
      case (tx_4bits)
        4'b0000 : enc_4b5b = 5'b11110; // 0
        4'b0001 : enc_4b5b = 5'b01001; // 1
        4'b0010 : enc_4b5b = 5'b10100; // 2
        4'b0011 : enc_4b5b = 5'b10101; // 3
        4'b0100 : enc_4b5b = 5'b01010; // 4
        4'b0101 : enc_4b5b = 5'b01011; // 5
        4'b0110 : enc_4b5b = 5'b01110; // 6
        4'b0111 : enc_4b5b = 5'b01111; // 7
        4'b1000 : enc_4b5b = 5'b10010; // 8
        4'b1001 : enc_4b5b = 5'b10011; // 9
        4'b1010 : enc_4b5b = 5'b10110; // A
        4'b1011 : enc_4b5b = 5'b10111; // B
        4'b1100 : enc_4b5b = 5'b11010; // C
        4'b1101 : enc_4b5b = 5'b11011; // D
        4'b1110 : enc_4b5b = 5'b11100; // E
        4'b1111 : enc_4b5b = 5'b11101; // F
      endcase
    end
  endfunction

endmodule
/*
------------------------------------------------------------------------
--
-- File :                       apb_ucpd_data_trans.v
-- Author:                      luo kun
-- Date :                       $Date: 2020/07/12 $
-- Abstract:                    PD main state machine
-- Modification History:
-- Date                 By      Version Change  Description
-- =====================================================================
-- See CVS log
-- =====================================================================
*/

module apb_ucpd_fsm (
  input        ic_clk          , // usbpd clock(HSI16)
  input        ucpd_clk        ,
  input        ic_rst_n        ,
  input        ucpden          ,
  input        tx_hrst         , // Command to send a Tx Hard Reset
  input        transmit_en     , // Command to send a Tx packet
  input        receive_en      ,
  input        eop_ok          ,
  input        bit_clk_red     ,
  input  [9:0] tx_paysize      , // tx Payload size in bytes, include head and TX_DATA
  input        crc_ok          ,
  input        rx_bit_cmplt    ,
  input        pre_rxbit_edg   ,
  input  [1:0] tx_mode         ,
  input  [6:0] tx_status       ,
  input        transwin_en     ,
  input        ifrgap_en       ,
  input        tx_hrst_red     ,
  input        tx_crst_red     ,
  input        rx_pre_cmplt    ,
  input        rx_sop_cmplt    ,
  input        hrst_vld        ,
  input        crst_vld        ,
  input        tx_hrst_flag    ,
  input        tx_crst_flag    ,
  input        hrst_tx_en      ,
  output       bmc_en          ,
  output       tx_sop_cmplt    ,
  output       tx_wait_cmplt   ,
  output       tx_crc_cmplt    ,
  output       tx_data_cmplt   ,
  output       tx_sop_rst_cmplt,
  output       tx_eop_cmplt    ,
  output       tx_msg_disc     ,
  output       tx_hrst_disc    ,
  output       txfifo_ld_en    ,
  output       cc_oen          ,
  output       dec_rxbit_en    ,
  output       txdr_req        ,
  output       rx_pre_en       ,
  output       rx_sop_en       ,
  output       rx_data_en      ,
  output       pre_en          ,
  output       sop_en          ,
  output       data_en         ,
  output       crc_en          ,
  output       eop_en          ,
  output       wait_en         ,
  output       bist_en
);

  // `include "parameter_def.v"


  /*------------------------------------------------------------------------------
  --  state variables for pd tx main FSM
  ------------------------------------------------------------------------------*/
  localparam TX_IDLE = 3'h0;
  localparam TX_PRE  = 3'h1;
  localparam TX_SOP  = 3'h2;
  localparam TX_DATA = 3'h3;
  localparam TX_CRC  = 3'h4;
  localparam TX_EOP  = 3'h5;
  localparam TX_BIST = 3'h6;
  localparam TX_WAIT = 3'h7;

  /*------------------------------------------------------------------------------
  --  state variables for pd rx main FSM
  ------------------------------------------------------------------------------*/
  localparam RX_IDLE = 2'h0;
  localparam RX_PRE  = 2'h1;
  localparam RX_SOP  = 2'h2;
  localparam RX_DATA = 2'h3;


  // ----------------------------------------------------------
  // -- local registers and wires
  // ----------------------------------------------------------
  //registers
  reg [ 2:0] tx_nxt_state      ;
  reg [ 2:0] tx_cur_state      ;
  reg [ 1:0] rx_nxt_state      ;
  reg [ 1:0] rx_cur_state      ;
  reg [ 3:0] one_data_txbit_cnt;
  reg [ 9:0] txbyte_cnt        ;
  reg [15:0] txbit_cnt         ;

  //wires nets
  wire        trans_cmplt   ;
  wire        enc_txbit_en  ;
  wire [12:0] tx_paybit_size;
  // wire        tx_bit5_cmplt ;
  wire        tx_pre_cmplt  ;
  wire        tx_bit10_cmplt;
  wire        tx_und        ;
  wire        hrst_sent     ;

  assign pre_en  = (tx_cur_state == TX_PRE);
  assign sop_en  = (tx_cur_state == TX_SOP);
  assign data_en = (tx_cur_state == TX_DATA);
  assign crc_en  = (tx_cur_state == TX_CRC);
  assign eop_en  = (tx_cur_state == TX_EOP);
  assign bist_en = (tx_cur_state == TX_BIST);
  assign wait_en = (tx_cur_state == TX_WAIT);

  assign rx_pre_en  = (rx_cur_state == RX_PRE);
  assign rx_sop_en  = (rx_cur_state == RX_SOP);
  assign rx_data_en = (rx_cur_state == RX_DATA);

  assign cc_rx_idle = (tx_cur_state == RX_IDLE);

  assign tx_und    = tx_status[6];
  assign hrst_sent = tx_status[5];

  assign tx_paybit_size = tx_paysize-1;
  assign tx_msg_disc    = receive_en & transmit_en & (tx_cur_state == TX_IDLE);
  assign tx_hrst_disc   = tx_hrst_flag & receive_en & transmit_en & (tx_cur_state == TX_IDLE);

  assign tx_pre_cmplt     = pre_en && bit_clk_red && (txbit_cnt == `PRE_BIT_NUM);
  assign tx_sop_cmplt     = sop_en && bit_clk_red && (txbit_cnt == `SOP_BIT_NUM);
  assign tx_data_cmplt    = data_en && tx_bit10_cmplt && (txbyte_cnt == tx_paybit_size);
  assign tx_crc_cmplt     = crc_en  && bit_clk_red && (txbit_cnt == `CRC_BIT_NUM);
  assign tx_eop_cmplt     = eop_en && bit_clk_red && (txbit_cnt == `TX_BIT5_NUM);
  assign tx_wait_cmplt    = wait_en && ifrgap_en;
  assign tx_sop_rst_cmplt = tx_sop_cmplt && (tx_hrst_flag | tx_crst_flag);
  assign tx_bit10_cmplt   = bit_clk_red && (one_data_txbit_cnt == `TX_BIT10_NUM);
  // assign tx_bit5_cmplt    = bit_clk_red && (txbit_cnt == `TX_BIT5_NUM);
  assign txfifo_ld_en     = tx_sop_cmplt || (data_en && tx_bit10_cmplt && ~tx_data_cmplt);
  assign txdr_req         = data_en && (txbyte_cnt < tx_paybit_size); // reqest in vaild time windows

  assign cc_oen           = bmc_en & ucpden;
  assign trans_cmplt      = tx_pre_cmplt | tx_sop_cmplt | tx_data_cmplt | tx_crc_cmplt | tx_eop_cmplt;
  assign bmc_en           = pre_en| sop_en| data_en | crc_en | eop_en | wait_en;
  assign enc_txbit_en     = sop_en | data_en | crc_en | eop_en;
  assign dec_rxbit_en     = rx_sop_en | rx_data_en;
  // ----------------------------------------------------------
  // -- This combinational process calculates FSM the next state
  // -- and generate the outputs in ic_clk domain for tx data
  // ----------------------------------------------------------
  always @ (posedge ic_clk or negedge ic_rst_n) begin
    if (!ic_rst_n)
      tx_cur_state <= TX_IDLE;
    else if(hrst_sent)
      tx_cur_state <= TX_IDLE;
    else
      tx_cur_state <= tx_nxt_state;
  end

  always @(*) begin
    tx_nxt_state = TX_IDLE;
    case (tx_cur_state)
      TX_IDLE :
        begin
          if(ucpden & transwin_en & (transmit_en | tx_hrst | hrst_tx_en))  // SW send TXSEND cmd
            tx_nxt_state = TX_PRE;
          else
            tx_nxt_state = TX_IDLE;
        end

      TX_PRE :
        begin
          if(trans_cmplt) begin
            tx_nxt_state = TX_SOP;
          end
          else
            tx_nxt_state = TX_PRE;
        end

      TX_SOP :
        begin
          if(tx_hrst)
            tx_nxt_state = TX_EOP;
          else if(trans_cmplt) begin
            if(tx_hrst_flag)
              tx_nxt_state = TX_IDLE;
            else if(tx_crst_flag)
              tx_nxt_state = TX_WAIT;
            else if(bist_en)
              tx_nxt_state = TX_BIST;
            else
              tx_nxt_state = TX_DATA;
          end
          else
            tx_nxt_state = TX_SOP;
        end

      TX_DATA :
        begin
          if(tx_hrst | tx_und)
            tx_nxt_state = TX_EOP;
          else if(transmit_en) begin
            if(trans_cmplt)
              tx_nxt_state = TX_CRC;
             else
              tx_nxt_state = TX_DATA;
          end
          else
            tx_nxt_state = TX_DATA;
        end

      TX_CRC :
        begin
          if(tx_hrst)
            tx_nxt_state = TX_EOP;
          else if(trans_cmplt)
            tx_nxt_state = TX_EOP;
          else
            tx_nxt_state = TX_CRC;
        end

      TX_EOP :
        begin
          if(tx_hrst)
            tx_nxt_state = TX_EOP;
          else if(trans_cmplt)
            tx_nxt_state = TX_WAIT;
          else
            tx_nxt_state = TX_EOP;
        end

      TX_BIST :
        begin
          if(tx_hrst)
            tx_nxt_state = TX_IDLE;
          else if(trans_cmplt) // TX_BIST finish
            tx_nxt_state = TX_IDLE;
          else
            tx_nxt_state = TX_BIST;
        end

      TX_WAIT :
        begin
          if(ifrgap_en)
            tx_nxt_state = TX_IDLE;
          else
            tx_nxt_state = TX_WAIT;
        end

      default : ;
    endcase
  end

  /*------------------------------------------------------------------------------
  --  count totole tx bit, according in each fsm stage
  ------------------------------------------------------------------------------*/
  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      txbit_cnt <= 16'b0;
    else if(trans_cmplt)
      txbit_cnt <= 16'b0;
    else if(bmc_en & bit_clk_red)
      txbit_cnt <= txbit_cnt+1;
  end

  /*------------------------------------------------------------------------------
  --  count totole tx byte need 10 bits, according in data_en
  ------------------------------------------------------------------------------*/
  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      one_data_txbit_cnt <= 4'b0;
    else if(data_en & bit_clk_red) begin
      if(one_data_txbit_cnt == `TX_BIT10_NUM)
        one_data_txbit_cnt <= 4'b0;
      else
        one_data_txbit_cnt <= one_data_txbit_cnt+1;
    end
  end

  /*------------------------------------------------------------------------------
  --  count totole tx byte, according in data_en
  ------------------------------------------------------------------------------*/
  always @(posedge ic_clk or negedge ic_rst_n) begin
    if(~ic_rst_n)
      txbyte_cnt <= 10'b0;
    else if(data_en) begin
      if(txbyte_cnt == tx_paybit_size && tx_bit10_cmplt)
        txbyte_cnt <= 10'b0;
      else if(one_data_txbit_cnt == `TX_BIT10_NUM && bit_clk_red)
        txbyte_cnt <= txbyte_cnt+1;
    end
  end

  // ----------------------------------------------------------
  // -- This combinational process calculates FSM the next state
  // -- and generate the outputs in ucpd_clk domain for rx data
  // ----------------------------------------------------------
  always @ (posedge ucpd_clk or negedge ic_rst_n) begin
    if (!ic_rst_n)
      rx_cur_state <= RX_IDLE;
    else
      rx_cur_state <= rx_nxt_state;
  end

  always @(*) begin
    rx_nxt_state = RX_IDLE;
    case (rx_cur_state)
      RX_IDLE :
        begin
          if(ucpden & receive_en)
            rx_nxt_state = RX_PRE;
          else
            rx_nxt_state = RX_IDLE;
        end

      RX_PRE :
        begin
          if(rx_pre_cmplt)
            rx_nxt_state = RX_SOP;
          else
            rx_nxt_state = RX_PRE;
        end

      RX_SOP :
        begin
          if(eop_ok)
            rx_nxt_state = RX_IDLE;
          else if(rx_sop_cmplt)
            rx_nxt_state = RX_DATA;
          else
            rx_nxt_state = RX_SOP;
        end

      RX_DATA :
        begin
          if(eop_ok | hrst_vld | crst_vld )
            rx_nxt_state = RX_IDLE;
          else
            rx_nxt_state = RX_DATA;
        end

      default : ;

    endcase
  end


endmodule

// -------------------------------------------------------------------
// -------------------------------------------------------------------
// File :                       apb_ucpd_if.v
// Author:                      luo kun
// Date :                       $Date: 2020/07/12 $
//
//
// Abstract:  Register address offset macros
//            All registers are on 32-bit boundaries
//
// -------------------------------------------------------------------


`define IC_CFG1_OS        8'h00
`define IC_CFG2_OS        8'h04
// address 8'h08 is Reserved
`define IC_CR_OS          8'h0c
`define IC_IMR_OS         8'h10
`define IC_SR_OS          8'h14
`define IC_ICR_OS         8'h18
`define IC_TX_ORDSET_OS   8'h1c
`define IC_TX_PAYSZ_OS    8'h20
`define IC_TXDR_OS        8'h24
`define IC_RX_ORDSET_OS   8'h28
`define IC_RX_PAYSZ_OS    8'h2c
`define IC_RXDR_OS        8'h30
`define IC_RX_ORDEXT1_OS  8'h34
`define IC_RX_ORDEXT2_OS  8'h38

module apb_ucpd_if (
  input             pclk        , // APB clock
  input             presetn     , // APB async reset
  input             wr_en       , // write enable
  input             rd_en       , // read enable
  input      [ 5:0] reg_addr    , // register address offset
  input      [31:0] ipwdata     , // internal APB write data
  input             txhrst_clr  ,
  input             txsend_clr  ,
  input             frs_evt     ,
  input      [ 6:0] tx_status   ,
  input      [ 5:0] rx_status   ,
  input      [ 6:0] rx_ordset   ,
  input      [ 9:0] rx_byte_cnt ,
  input      [ 7:0] rx_byte     ,
  input             hrst_vld    ,
  input      [ 2:0] cc1_compout , // SR.17:16  TYPEC_VSTATE_CC1
  input      [ 2:0] cc2_compout , // SR.19:18  TYPEC_VSTATE_CC2
  output     [ 1:0] phy_en      , // CR.11:10 CCENABLE
  output            set_c500    , // CR.8:7 ANASUBMODE
  output            set_c1500   , // CR.8:7 ANASUBMODE
  output            set_c3000   , // CR.8:7 ANASUBMODE
  output            set_pd      , // CR.9 ANAMODE 1
  output            source_en   , // CR.9 ANAMODE 0
  output            phy_rx_en   , // CR.5 PHYRXEN
  output            cc1_det_en  , // CR.20 CC1TCDIS
  output            cc2_det_en  , // CR.21 CC2TCDIS
  output            phy_cc1_com , // CR.6 PHYCCSEL 0
  output            phy_cc2_com , // CR.6 PHYCCSEL 1
  output            ucpden      , // USB Power Delivery Block Enable
  output     [ 4:0] transwin    , // use half bit clock to achieve a legal tTransitionWindow
  output     [ 4:0] ifrgap      , // Interframe gap
  output     [ 5:0] hbitclkdiv  , // Clock divider values is used to generate a half-bit clock
  output     [ 2:0] psc_usbpdclk, // Pre-scaler for UCPD_CLK
  output     [ 8:0] rx_ordset_en,
  output            tx_hrst     ,
  output            rxdr_rd     ,
  output            transmit_en ,
  output     [ 1:0] tx_mode     ,
  output            ucpd_intr   ,
  output            tx_ordset_we,
  output     [ 9:0] tx_paysize  ,
  output            txdr_we     ,
  output     [ 1:0] rxfilte     ,
  output     [19:0] tx_ordset   ,
  output reg [ 7:0] ic_txdr     ,
  output reg [31:0] iprdata       // internal APB read data
);
  // internal registers
  reg [31:0] ic_cfg1;
  reg [31:0] ic_cfg2;
  reg [31:0] ic_cr;
  reg [31:0] ic_imr;
  reg [31:0] ic_icr;
  reg [31:0] ic_sr;
  reg [31:0] ic_tx_ordset;
  reg [31:0] ic_tx_paysz;
  reg [31:0] ic_rx_ordext1;
  reg [31:0] ic_rx_ordext2;
  reg      [ 1:0] vstate_cc1;
  reg      [ 1:0] vstate_cc2;

  // internal wires
  wire [31:0] ic_cfg1_s         ;
  wire [31:0] ic_cfg2_s         ;
  wire [31:0] ic_cr_s           ;
  wire [31:0] ic_imr_s          ;
  wire [31:0] ic_sr_s           ;
  wire [31:0] ic_tx_paysz_s     ;
  wire [31:0] ic_txdr_s         ;
  wire [31:0] ic_rx_ordset_s    ;
  wire [31:0] ic_rx_paysz_s     ;
  wire [31:0] ic_rxdr_s         ;
  wire [31:0] ic_rx_ordext1_s   ;
  wire [31:0] ic_rx_ordext2_s   ;
  wire [ 2:0] evt_intr_en       ;
  wire        ic_cfg1_en        ;
  wire        ic_cfg2_en        ;
  wire        ic_cr_en          ;
  wire        ic_imr_en         ;
  wire        ic_sr_en          ;
  wire        ic_icr_en         ;
  wire        ic_tx_ordset_en   ;
  wire        ic_tx_paysz_en    ;
  wire        ic_txdr_en        ;
  wire        ic_rx_ordset_en   ;
  wire        ic_rx_paysz_en    ;
  wire        ic_rxdr_en        ;
  wire        ic_rx_ordext1_en  ;
  wire        ic_rx_ordext2_en  ;
  wire        ic_cfg1_we        ;
  wire        ic_cfg2_we        ;
  wire        ic_cr_we          ;
  wire        ic_imr_we         ;
  wire        ic_icr_we         ;
  wire        ic_tx_ordset_we   ;
  wire        ic_tx_paysz_we    ;
  wire        ic_txdr_we        ;
  wire        ic_rx_ordext1_we  ;
  wire        ic_rx_ordext2_we  ;
  wire [ 6:0] tx_status_sync_red;
  wire [ 5:0] rx_status_sync_red;
  wire [ 6:0] tx_status_sync    ;
  wire [ 5:0] rx_status_sync    ;
  wire [ 1:0] vstate_cc1_sync   ;
  wire [ 1:0] vstate_cc2_sync   ;
  wire        typec_evt1_red    ;
  wire        typec_evt2_red    ;
  wire        frs_evt_red       ;
  wire        hard_rst          ;

  assign hard_rst       = tx_status[5];
  assign ic_rx_ordset_s = {{25{1'b0}}, rx_ordset};
  assign ic_rx_paysz_s  = {{22{1'b0}}, rx_byte_cnt};
  assign ic_rxdr_s      = {{24{1'b0}}, rx_byte};

  assign ucpd_intr    = |(ic_imr & ic_sr);
  assign txdr_we      = (ic_txdr_we == 1'b1 && ucpden);
  assign tx_ordset_we = (ic_tx_ordset_we == 1'b1 && ucpden);
  assign tx_ordset    = ic_tx_ordset[19:0];
  assign tx_paysize   = ic_tx_paysz[9:0];
  assign rxfilte      = ic_cfg2[1:0];
  assign transmit_en  = ic_cr[2];



  /*------------------------------------------------------------------------------
  --  Address decoder
  --  Decodes the register address offset input(reg_addr)
  --  to produce enable (select) signals for each of the
  --  SW-registers in the macrocell
  ------------------------------------------------------------------------------*/
  assign ic_cfg1_en       = {2'b00, reg_addr} == (`IC_CFG1_OS       >> 2);
  assign ic_cfg2_en       = {2'b00, reg_addr} == (`IC_CFG2_OS       >> 2);
  assign ic_cr_en         = {2'b00, reg_addr} == (`IC_CR_OS         >> 2);
  assign ic_imr_en        = {2'b00, reg_addr} == (`IC_IMR_OS        >> 2);
  assign ic_sr_en         = {2'b00, reg_addr} == (`IC_SR_OS         >> 2);
  assign ic_icr_en        = {2'b00, reg_addr} == (`IC_ICR_OS        >> 2);
  assign ic_tx_ordset_en  = {2'b00, reg_addr} == (`IC_TX_ORDSET_OS  >> 2);
  assign ic_tx_paysz_en   = {2'b00, reg_addr} == (`IC_TX_PAYSZ_OS   >> 2);
  assign ic_txdr_en       = {2'b00, reg_addr} == (`IC_TXDR_OS       >> 2);
  assign ic_rx_ordset_en  = {2'b00, reg_addr} == (`IC_RX_ORDSET_OS  >> 2);
  assign ic_rx_paysz_en   = {2'b00, reg_addr} == (`IC_RX_PAYSZ_OS   >> 2);
  assign ic_rxdr_en       = {2'b00, reg_addr} == (`IC_RXDR_OS       >> 2);
  assign ic_rx_ordext1_en = {2'b00, reg_addr} == (`IC_RX_ORDEXT1_OS >> 2);
  assign ic_rx_ordext2_en = {2'b00, reg_addr} == (`IC_RX_ORDEXT2_OS >> 2);

  /*------------------------------------------------------------------------------
  --   Write enable signals for writeable SW-registers.
  --   rw registers include UCPD_CFG1, UCPD_CFG2, UCPD_CR, UCPD_IMR, UCPD_TX_ORDSET
                            UCPD_TX_PAYSZ, UCPD_TXDR, UCPD_RX_ORDEXT1, UCPD_RX_ORDEXT2
  --   ow registers include UCPD_ICR
  ------------------------------------------------------------------------------*/
  assign ic_cfg1_we       = ic_cfg1_en       & wr_en;
  assign ic_cfg2_we       = ic_cfg2_en       & wr_en;
  assign ic_cr_we         = ic_cr_en         & wr_en;
  assign ic_imr_we        = ic_imr_en        & wr_en;
  assign ic_icr_we        = ic_icr_en        & wr_en;
  assign ic_tx_ordset_we  = ic_tx_ordset_en  & wr_en;
  assign ic_tx_paysz_we   = ic_tx_paysz_en   & wr_en;
  assign ic_txdr_we       = ic_txdr_en       & wr_en;
  assign ic_rx_ordext1_we = ic_rx_ordext1_en & wr_en;
  assign ic_rx_ordext2_we = ic_rx_ordext2_en & wr_en;

  /*------------------------------------------------------------------------------
  --   Control signal generation
  ------------------------------------------------------------------------------*/
  assign rxdr_rd      = ic_rxdr_en & rd_en;
  assign ucpden       = ic_cfg1[31];
  assign rx_ordset_en = ic_cfg1[28:20];
  assign psc_usbpdclk = ic_cfg1[19:17];
  assign transwin     = ic_cfg1[15:11];
  assign ifrgap       = ic_cfg1[10:06];
  assign hbitclkdiv   = ic_cfg1[05:00];

  assign ic_cfg1_s    = ic_cfg1;
  assign ic_cfg2_s    = ic_cfg2;
  assign ic_cr_s      = ic_cr;
  assign ic_sr_s      = ic_sr;
  assign tx_mode      = ic_cr[1:0];
  assign tx_hrst      = ic_cr[3];
  assign transmit_en  = ic_cr[2];

  /*------------------------------------------------------------------------------
  --  analog interface
  ------------------------------------------------------------------------------*/
  always @(*) begin
    case(cc1_compout)
      3'b000 : vstate_cc1 = 2'd0;
      3'b001 : vstate_cc1 = 2'd1;
      3'b010 : vstate_cc1 = 2'd2;
      3'b100 : vstate_cc1 = 2'd3;
      default : vstate_cc1 = 2'd0;
    endcase
  end

  always @(*) begin
    case(cc2_compout)
      3'b000 : vstate_cc2 = 2'd0;
      3'b001 : vstate_cc2 = 2'd1;
      3'b010 : vstate_cc2 = 2'd2;
      3'b100 : vstate_cc2 = 2'd3;
      default : vstate_cc2 = 2'd0;
    endcase
  end

  assign phy_cc1_com = ~ic_cr[6];
  assign phy_cc2_com = ic_cr[6];
  assign cc1_det_en  = ~ic_cr[20];
  assign cc2_det_en  = ~ic_cr[21];
  assign phy_en      = ic_cr[11:10];
  assign set_c500    = (ic_cr[8:7] == 2'b01) ? 1'b1 : 1'b0;
  assign set_c1500   = (ic_cr[8:7] == 2'b10) ? 1'b1 : 1'b0;
  assign set_c3000   = (ic_cr[8:7] == 2'b11) ? 1'b1 : 1'b0;
  assign set_pd      = ic_cr[9];
  assign source_en   = ~ic_cr[9];
  assign phy_rx_en   = ic_cr[5];

  // ----------------------------------------------------------
  // -- Synchronization registers for flags input from ic_clk domain
  // ----------------------------------------------------------
  wire [6:0] tx_status_src     ;
  wire [6:0] tx_status_src_sync;
  assign tx_status_src  = tx_status;
  assign tx_status_sync = tx_status_src_sync;
  apb_ucpd_bcm21 #(.WIDTH(7)) u_tx_status_psyzr (
    .clk_d   (pclk              ),
    .rst_d_n (presetn           ),
    .init_d_n(1'b1              ),
    .test    (1'b0              ),
    .data_s  (tx_status_src     ),
    .data_d  (tx_status_src_sync)
  );

  wire [5:0] rx_status_src     ;
  wire [5:0] rx_status_src_sync;
  assign rx_status_src  = rx_status;
  assign rx_status_sync = rx_status_src_sync;
  apb_ucpd_bcm21 #(.WIDTH(6)) u_rx_status_psyzr (
    .clk_d   (pclk              ),
    .rst_d_n (presetn           ),
    .init_d_n(1'b1              ),
    .test    (1'b0              ),
    .data_s  (rx_status_src     ),
    .data_d  (rx_status_src_sync)
  );

  reg [6:0] tx_status_sync_d;
  reg [5:0] rx_status_sync_d;
  always @(posedge pclk or negedge presetn) begin
    if (presetn == 1'b0) begin
      tx_status_sync_d <= 7'b0;
      rx_status_sync_d <= 6'b0;
    end
    else begin
      tx_status_sync_d <= tx_status_sync;
      rx_status_sync_d <= rx_status_sync;
    end
  end

  assign tx_status_sync_red = (tx_status_sync & ~tx_status_sync_d);
  assign rx_status_sync_red = (rx_status_sync & ~rx_status_sync_d);
  /*------------------------------------------------------------------------------
  --  generate typec_evt1, typec_evt2 and its positive edge for SR
  ------------------------------------------------------------------------------*/
  wire [1:0] vstate_cc1_src     ;
  wire [1:0] vstate_cc1_src_sync;
  assign vstate_cc1_src  = vstate_cc1;
  assign vstate_cc1_sync = vstate_cc1_src_sync;
  apb_ucpd_bcm21 #(.WIDTH(2)) u_vstate_cc1_psyzr (
    .clk_d   (pclk               ),
    .rst_d_n (presetn            ),
    .init_d_n(1'b1               ),
    .test    (1'b0               ),
    .data_s  (vstate_cc1_src     ),
    .data_d  (vstate_cc1_src_sync)
  );

  wire [1:0] vstate_cc2_src     ;
  wire [1:0] vstate_cc2_src_sync;
  assign vstate_cc2_src  = vstate_cc2;
  assign vstate_cc2_sync = vstate_cc2_src_sync;
  apb_ucpd_bcm21 #(.WIDTH(2)) u_vstate_cc2_psyzr (
    .clk_d   (pclk               ),
    .rst_d_n (presetn            ),
    .init_d_n(1'b1               ),
    .test    (1'b0               ),
    .data_s  (vstate_cc2_src     ),
    .data_d  (vstate_cc2_src_sync)
  );

  reg [1:0] vstate_cc1_nxt;
  reg [1:0] vstate_cc2_nxt;
  always @(posedge pclk or negedge presetn) begin
    if (presetn == 1'b0) begin
      vstate_cc1_nxt <= 2'b0;
      vstate_cc2_nxt <= 2'b0;
    end
    else begin
      vstate_cc1_nxt <= vstate_cc1_sync;
      vstate_cc2_nxt <= vstate_cc2_sync;
    end
  end

  assign typec_evt1 = vstate_cc1_nxt != vstate_cc1_sync;
  assign typec_evt2 = vstate_cc2_nxt != vstate_cc2_sync;

  reg [1:0] typec_evt1_r;
  reg [1:0] typec_evt2_r;
  always @(posedge pclk or negedge presetn) begin
    if (presetn == 1'b0) begin
      typec_evt1_r <= 2'b0;
      typec_evt2_r <= 2'b0;
    end
    else begin
      typec_evt1_r <= {typec_evt1_r[0], typec_evt1};
      typec_evt2_r <= {typec_evt2_r[0], typec_evt2};
    end
  end

  assign typec_evt1_red = ~typec_evt1_r[1] & typec_evt1_r[0];
  assign typec_evt2_red = ~typec_evt2_r[1] & typec_evt2_r[0];

  /*------------------------------------------------------------------------------
  --  generate frs_evt positive edge for SR
  ------------------------------------------------------------------------------*/
  reg [1:0] frs_evt_r;
  always @(posedge pclk or negedge presetn) begin
    if (presetn == 1'b0)
      frs_evt_r <= 2'b0;
    else
      frs_evt_r <= {frs_evt_r[0], frs_evt};
  end

  assign frs_evt_red = ~frs_evt_r[1] & frs_evt_r[0];

  /*------------------------------------------------------------------------------
  --  Below is APB BUS write UCPD registers
  ------------------------------------------------------------------------------*/

  // apb write UCPD configuration register 1 (UCPD_CFG1)
  always @(posedge pclk or negedge presetn) begin
    if (presetn == 1'b0)
      ic_cfg1 <= 32'b0;
    // else if(hard_rst)
    //   ic_cfg1[31] <= 1'b0;
    else if (ic_cfg1_we == 1'b1) begin
      if(ipwdata[31])
        ic_cfg1[31] <= ipwdata[31];
      else
        ic_cfg1[30:0] <= ipwdata[30:0];
    end
  end

  // apb write UCPD configuration register 2 (UCPD_CFG2)
  always @(posedge pclk or negedge presetn) begin
    if (presetn == 1'b0)
      ic_cfg2 <= 32'b0;
    else if (ic_cfg2_we == 1'b1 && ucpden == 1'b0)
      ic_cfg2 <= ipwdata;
  end

  // apb write UCPD control register (UCPD_CR)
  always @(posedge pclk or negedge presetn) begin
    if (presetn == 1'b0)
      ic_cr <= 32'b0;
    else if(ucpden) begin
      if (ic_cr_we == 1'b1)
        ic_cr <= ipwdata;
      else if(txhrst_clr)
        ic_cr[3] <= 1'b0;
      else if(txsend_clr)
        ic_cr[2] <= 1'b0;
    end
  end

  // apb write UCPD Interrupt Mask Register (UCPD_IMR)
  always @(posedge pclk or negedge presetn) begin
    if (presetn == 1'b0)
      ic_imr <= 32'b0;
    else if(ic_imr_we == 1'b1 && ucpden)
      ic_imr <= ipwdata;
  end

  // apb write UCPD Interrupt Clear Register (UCPD_ICR)
  always @(posedge pclk or negedge presetn) begin
    if (presetn == 1'b0)
      ic_icr <= 32'b0;
    else if(ic_icr_we == 1'b1 && ucpden)
      ic_icr <= ipwdata;
  end

  // apb write UCPD Tx Ordered Set Type Register (UCPD_TX_ORDSET)
  always @(posedge pclk or negedge presetn) begin
    if (presetn == 1'b0)
      ic_tx_ordset <= 32'b0;
    else if (ic_tx_ordset_we == 1'b1 && ucpden)
      ic_tx_ordset <= ipwdata;
  end

  // apb write UCPD Tx Paysize Register (UCPD_TX_PAYSZ)
  always @(posedge pclk or negedge presetn) begin
    if (presetn == 1'b0)
      ic_tx_paysz <= 32'b0;
    else if (ic_tx_paysz_we == 1'b1 && ucpden)
      ic_tx_paysz <= ipwdata;
  end

  // apb write UCPD Tx Data Register (UCPD_TXDR)
  always @(posedge pclk or negedge presetn) begin
    if (presetn == 1'b0)
      ic_txdr <= 32'b0;
    else if(ic_txdr_we == 1'b1 && ucpden)
      ic_txdr <= ipwdata;
  end

  // apb write UCPD Rx Ordered Set Extension Register #1 (UCPD_RX_ORDEXT1)
  always @(posedge pclk or negedge presetn) begin
    if (presetn == 1'b0)
      ic_rx_ordext1 <= 32'b0;
    else if (ic_rx_ordext1_we == 1'b1 && ucpden == 1'b0)
      ic_rx_ordext1 <= ipwdata;
  end

  // apb write UCPD Rx Ordered Set Extension Register #2 (UCPD_RX_ORDEXT2)
  always @(posedge pclk or negedge presetn) begin
    if (presetn == 1'b0)
      ic_rx_ordext2 <= 32'b0;
    else if (ic_rx_ordext2_we == 1'b1 && ucpden == 1'b0)
      ic_rx_ordext2 <= ipwdata;
  end

  /*------------------------------------------------------------------------------
  --  generate UCPD Status Register (UCPD_SR) read data
  ------------------------------------------------------------------------------*/
  always @(posedge pclk or negedge presetn) begin
    if(presetn == 1'b0)
      ic_sr <= 31'b0;
    else begin
      // TYPEC_VSTATE_CC2[1:0]:This status shows the DC level seen on the CC2 pin
      ic_sr[19:18] <= vstate_cc2;
      // TYPEC_VSTATE_CC1[1:0]:This status shows the DC level seen on the CC1 pin
      ic_sr[17:16] <= vstate_cc1;
      // FRSEVT: Fast Role Swap detection event.
      if(ic_icr[20])
        ic_sr[20] <= 1'b0;
      else if(frs_evt_red)
        ic_sr[20] <= 1'b1;

      // TYPECEVT2: Type C voltage level event on CC2 pin.
      if(ic_icr[15])
        ic_sr[15] <= 1'b0;
      else if(typec_evt2_red)
        ic_sr[15] <= 1'b1;

      // TYPECEVT1: Type C voltage level event on CC1 pin.
      if(ic_icr[14])
        ic_sr[14] <= 1'b0;
      else if(typec_evt1_red)
        ic_sr[14] <= 1'b1;

      // RXERR: Receive message not completed OK
      if(ic_icr[13])
        ic_sr[13] <= 1'b0;
      else if(rx_status_sync_red[5])
        ic_sr[13] <= 1'b1;

      // RXMSGEND: Rx message received
      if(ic_icr[12])
        ic_sr[12] <= 1'b0;
      else if(rx_status_sync_red[4])
        ic_sr[12] <= 1'b1;

      // RXOVR: Rx data overflow interrupt
      if(ic_icr[11])
        ic_sr[11] <= 1'b0;
      else if(rx_status_sync_red[3])
        ic_sr[11] <= 1'b1;

      // RXHRSTDET: Rx Hard Reset detect interrupt
      if(ic_icr[10])
        ic_sr[10] <= 1'b0;
      else if(rx_status_sync_red[2])
        ic_sr[10] <= 1'b1;

      // RXORDDET: Rx ordered set (4 K-codes) detected interrupt
      if(ic_icr[9])
        ic_sr[9] <= 1'b0;
      else if(rx_status_sync_red[1])
        ic_sr[9] <= 1'b1;

      // RXNE: Receive data register not empty interrupt
      if(rxdr_rd)
        ic_sr[8] <= 1'b0;
      else if(rx_status_sync_red[0])
        ic_sr[8] <= 1'b1;

      // TXUND: Tx data underrun condition interrupt
      if(ic_icr[6])
        ic_sr[6] <= 1'b0;
      else if(tx_status_sync_red[6])
        ic_sr[6] <= 1'b1;

      // HRSTSENT: HRST sent interrupt
      if(ic_icr[5])
        ic_sr[5] <= 1'b0;
      else if(tx_status_sync_red[5])
        ic_sr[5] <= 1'b1;

      // HRSTDISC: HRST discarded interrupt
      if(ic_icr[4])
        ic_sr[4] <= 1'b0;
      else if(tx_status_sync_red[4])
        ic_sr[4] <= 1'b1;

      // TXMSGABT: Transmit message abort interrupt
      if(ic_icr[3])
        ic_sr[3] <= 1'b0;
      else if(tx_status_sync_red[3])
        ic_sr[3] <= 1'b1;

      // TXMSGSENT: Transmit message sent interrupt
      if(ic_icr[2])
        ic_sr[2] <= 1'b0;
      else if(tx_status_sync_red[2])
        ic_sr[2] <= 1'b1;

      //  TXMSGDISC: Transmit message discarded interrupt
      if(ic_icr[1])
        ic_sr[1] <= 1'b0;
      else if(tx_status_sync_red[1])
        ic_sr[1] <= 1'b1;

      // TXIS: Transmit interrupt status
      if(txdr_we)
        ic_sr[0] <= 1'b0;
      else if(tx_status_sync_red[0])
        ic_sr[0] <= 1'b1;
    end
  end

  /*------------------------------------------------------------------------------
  --  APB read data mux
  --  The data from the selected register is
  --  placed on a zero-padded 32-bit read data bus.
  --  this is a reverse case and parallel case
  ------------------------------------------------------------------------------*/
  always @ (*) begin : IPRDATA_PROC
    iprdata = 32'b0;
    case (1'b1)
      ic_cfg1_en       : iprdata  = ic_cfg1_s       ;
      ic_cfg2_en       : iprdata  = ic_cfg2_s       ;
      ic_cr_en         : iprdata  = ic_cr_s         ;
      ic_imr_en        : iprdata  = ic_imr_s        ;
      ic_sr_en         : iprdata  = ic_sr_s         ;
      ic_tx_paysz_en   : iprdata  = ic_tx_paysz_s   ;
      ic_txdr_en       : iprdata  = ic_txdr_s       ;
      ic_rx_ordset_en  : iprdata  = ic_rx_ordset_s  ;
      ic_rx_paysz_en   : iprdata  = ic_rx_paysz_s   ;
      ic_rxdr_en       : iprdata  = ic_rxdr_s       ;
      ic_rx_ordext1_en : iprdata  = ic_rx_ordext1_s ;
      ic_rx_ordext2_en : iprdata  = ic_rx_ordext2_s ;
    endcase
  end

endmodule
//  ------------------------------------------------------------------------
//
//                    (C) COPYRIGHT 2003 - 2016 SYNOPSYS, INC.
//                            ALL RIGHTS RESERVED
//
//  This software and the associated documentation are confidential and
//  proprietary to Synopsys, Inc.  Your use or disclosure of this
//  software is subject to the terms and conditions of a written
//  license agreement between you, or your company, and Synopsys, Inc.
//
// The entire notice above must be reproduced on all authorized copies.
//
//  ------------------------------------------------------------------------

//
// Filename    : DW_apb_i2c_bcm47.v
// Revision    : $Id: //dwh/DW_ocb/DW_apb_i2c/amba_dev/src/DW_apb_i2c_bcm47.v#4 $
// Author      : Bruce Dean      May 01, 2004
// Description : DW_apb_i2c_bcm47.v Verilog module for DWbb
//
// DesignWare IP ID: 310fedd9
// crc8 DATA_WIDTH = 8; POLY_SIZE = 8; CRC_CFG = 0; BIT_ORDER= 0;
//      POLY_COEF0 = 7;POLY_COEF1 = 0;POLY_COEF2 = 0;POLY_COEF3 = 0;
//crc16 DATA_WIDTH = 8; POLY_SIZE = 16; CRC_CFG = 0; BIT_ORDER= 0;
//      POLY_COEF0 = 16'h1021;POLY_COEF1 = 0;POLY_COEF2 = 0;POLY_COEF3 = 0;
////////////////////////////////////////////////////////////////////////////////
module apb_ucpd_pcrc (
     ic_clk,
     ic_rst_n,
     init_n,
     enable,
     drain,
     ld_crc_n,
     data_in,
     crc_in,
     draining,
     drain_done,
     crc_ok,
     data_out,
     crc_out
    );

parameter DATA_WIDTH = 8 ;
parameter POLY_SIZE  = 32 ;
parameter CRC_CFG    = 0 ;
parameter CRC_INI    = 1 ;
parameter BIT_ORDER  = 0 ;
parameter POLY_COEF0 = 16'h1DB7;
parameter POLY_COEF1 = 16'h04C1;
parameter POLY_COEF2 = 0 ;
parameter POLY_COEF3 = 0 ;

localparam              ODD_WIDTH_OFFSET = ((DATA_WIDTH & 1) == 1)? DATA_WIDTH : 0;
localparam              POLY_2_DATA_RATIO = POLY_SIZE/DATA_WIDTH;
localparam [ 4 : 0]     INITIAL_POINTER   = POLY_SIZE/DATA_WIDTH;
localparam              INIT_VAL = 32'h0;

localparam [31 : 0] tp =   ((POLY_COEF3 & 65535) << 48) +
                           ((POLY_COEF2 & 65535) << 32) +
                           ((POLY_COEF1 & 65535) << 16) +
                            (POLY_COEF0 & 65535);


input                  ic_clk;
input                  ic_rst_n;
input                  init_n;
input                  enable;
input                  drain;
input                  ld_crc_n;
input [DATA_WIDTH-1:0] data_in;
input [POLY_SIZE-1:0]  crc_in;

output                  draining;
output                  drain_done;
output                  crc_ok;
output [DATA_WIDTH-1:0] data_out;
output [POLY_SIZE-1:0]  crc_out;

reg [4:0] data_pointer        ;
reg       drain_done_next     ;
reg       crc_ok_int          ;
reg       drain_done_int      ;
reg       draining_status     ;
reg       draining_status_next;

reg  [DATA_WIDTH-1:0] data_out_next;
reg  [DATA_WIDTH-1:0] data_out_int;

wire [POLY_SIZE-1:0]  crc_out_int;
reg  [POLY_SIZE-1:0]  crc_out_rg;
reg  [POLY_SIZE-1:0]  crc_out_next;
reg  [POLY_SIZE-1:0]  crc_out_temp;

wire       crc_ok_result    ;
wire [4:0] data_pointer_next;

wire [DATA_WIDTH-1:0] crc_drn_dat;
wire [DATA_WIDTH-1:0] data_in_ro;
wire [DATA_WIDTH-1:0] crc_xor_res;
wire [DATA_WIDTH-1:0] crc_ins_mask;
wire [DATA_WIDTH-1:0] crc_xord_swaped;

wire [POLY_SIZE-1:0]  crc_result;
wire [POLY_SIZE-1:0]  crc_out_next_shifted;
wire [POLY_SIZE-1:0]  crc_ok_remn;
wire [POLY_SIZE-1:0]  crc_xor_constant;
wire [POLY_SIZE-1:0]  reset_crc_reg;
wire [POLY_SIZE-1:0]  init_crc_reg;
wire [POLY_SIZE-1:0] crc_data_out   ;

  // This function generates the remainder
  // to be used in the crc ok generation
  function [POLY_SIZE-1:0] gen_crc_rem;
   input [POLY_SIZE-1:0]  crc_xor_constant;
   begin : FUNC_CRC_OK_NFO
    reg [POLY_SIZE-1:0]  int_ok_calc;
    reg                  xor_or_not;
    integer              i;
    int_ok_calc = crc_xor_constant;
    for(i = 0; i < POLY_SIZE; i = i + 1) begin
      xor_or_not  = int_ok_calc[(POLY_SIZE-1)];
      int_ok_calc = { int_ok_calc[((POLY_SIZE-1)- 1):0], 1'b0};
      if(xor_or_not == 1'b1)
       int_ok_calc = (int_ok_calc ^ tp[POLY_SIZE-1:0]);
     end

     gen_crc_rem = int_ok_calc;
    end
   endfunction


   // This function caculates the crc on a data word sized chunk
   // by checking if the msb is a one, and iff then xor the data
   // with the crc polynomial from the parameters
   function [POLY_SIZE-1:0] fcalc_crc;
    input [DATA_WIDTH-1:0] data_ro_in;
    input [POLY_SIZE-1:0]  crc_fb_data;
    input                  draining_status;
    begin : FUNC_CALC_CRC
     reg [DATA_WIDTH-1:0] fdata_in;
     reg [POLY_SIZE-1:0]  crc_data;
     reg                  xor_or_not;
     integer              i;
     crc_data  = crc_fb_data ;
     fdata_in  = data_ro_in;
     for (i = 0;i < DATA_WIDTH; i = i + 1 ) begin
       xor_or_not = !draining_status & (fdata_in[(DATA_WIDTH-1) - i] ^ crc_data[(POLY_SIZE-1)]);
       if(xor_or_not == 1'b1)
        crc_data = ({crc_data [((POLY_SIZE-1)-1):0],1'b0 } ^ tp[POLY_SIZE-1:0]);
       else
        crc_data   = {crc_data [((POLY_SIZE-1)-1):0],1'b0 };
      end
      fcalc_crc = crc_data ;
     end
   endfunction


   // This function re-orders the bits/bytes of data according
   // to the parameters passed through.
   function [DATA_WIDTH-1:0] fdata_ro0;
    input [DATA_WIDTH-1:0] data_ro_in;
    begin : FUNC_REORDER_DATA
     reg   [DATA_WIDTH-1:0] data_ro_out;
     integer             i;

      for (i = 0; i < DATA_WIDTH; i = i+1) begin
        data_ro_out[i] = data_ro_in[i];
      end
      fdata_ro0 = data_ro_out;
     end
   endfunction


   // This function directly reverse ordering of bits of data according
   // to the parameters passed through.
   function [DATA_WIDTH-1:0] fdata_ro1;
    input [DATA_WIDTH-1:0] data_ro_in;
    begin : FUNC_REORDER_DATA
     reg   [DATA_WIDTH-1:0] data_ro_out;
     integer             i,j;

      for (i = 0; i < DATA_WIDTH; i = i+1) begin
          j              = DATA_WIDTH - 1 - i;
          data_ro_out[i] = data_ro_in[j];
      end
      fdata_ro1 = data_ro_out;
     end
   endfunction


   // This function re-orders the bits/bytes of data according
   // to the parameters passed through using:
   // byte reverse, bit forward ordering
   function [DATA_WIDTH-1:0] fdata_ro2;
    input [DATA_WIDTH-1:0] data_ro_in;
    begin : FUNC_REORDER_DATA
     reg   [DATA_WIDTH-1:0] data_ro_out;
     integer             i,j;

      for (i = 0; i < DATA_WIDTH; i = i+1) begin
          j              = (i & 7) + (((DATA_WIDTH>>3)-1 - (i>>3))<<3);
          data_ro_out[i] = data_ro_in[j];
      end
      fdata_ro2 = data_ro_out;
     end
   endfunction


   // This function re-orders the bits/bytes of data according
   // to the parameter passed through using:
   // byte forward, bit reverse ordering
   function [DATA_WIDTH-1:0] fdata_ro3;
    input [DATA_WIDTH-1:0] data_ro_in;
    begin : FUNC_REORDER_DATA
     reg   [DATA_WIDTH-1:0] data_ro_out;
     integer             i,j;

      for (i = 0; i < DATA_WIDTH; i = i+1) begin
          j              = (i | 7)-(i & 7);
          data_ro_out[j] = data_ro_in[i];
      end
      fdata_ro3 = data_ro_out;
     end
   endfunction


  // This function will left-shift the input data by a number of bits
  // that specified by the parameter.
  function [POLY_SIZE-1:0] fshift_crc_nxt;
   input  [POLY_SIZE-1:0] crc_out_fnc;
    begin : FSHIFT_CRC_NXT
     reg [POLY_SIZE-1:0] shifted_data;
     integer             i;
     shifted_data = crc_out_fnc;
     for (i = 0;i < DATA_WIDTH; i = i + 1)
       shifted_data = shifted_data << 1'b1;

      fshift_crc_nxt =  shifted_data;
    end
  endfunction



generate
  if ((CRC_CFG & 6) == 0) begin : GEN_cfg_00x
    assign crc_xor_constant = {POLY_SIZE{1'b0}};
  end

  if (((CRC_CFG & 6) == 2) && ((POLY_SIZE & 1) == 0)) begin : GEN_cfg_01x_evn_ps
    assign crc_xor_constant = {(POLY_SIZE / 2){2'b01}} ;
  end

  if (((CRC_CFG & 6) == 2) && ((POLY_SIZE & 1) == 1)) begin : GEN_cfg_01x_odd_ps
    assign crc_xor_constant = {1'b1,{((POLY_SIZE-1)/2){2'b01}}};
  end

  if (((CRC_CFG & 6) == 4) && ((POLY_SIZE & 1) == 0)) begin : GEN_cfg_10x_evn_ps
    assign crc_xor_constant = {(POLY_SIZE / 2){2'b10}} ;
  end

  if (((CRC_CFG & 6) == 4) && ((POLY_SIZE & 1) == 1)) begin : GEN_cfg_10x_odd_ps
    assign crc_xor_constant = {1'b0,{((POLY_SIZE-1)/2){2'b10}}};
  end

  if ((CRC_CFG & 6) == 6) begin : GEN_cfg_11x
    assign crc_xor_constant = {POLY_SIZE{1'b1}};
  end
endgenerate

generate
  if ((CRC_CFG & 1) == 0) begin : GEN_crc_rst_zeros
    assign reset_crc_reg    = {POLY_SIZE{1'b0}};
  end

  if ((CRC_CFG & 1) == 1) begin : GEN_crc_rst_ones
    assign reset_crc_reg    = {POLY_SIZE{1'b1}};
  end
endgenerate

generate
  if ((CRC_INI & 1) == 0) begin : GEN_CRC_INI_zeros
    assign init_crc_reg    = {POLY_SIZE{1'b0}};
  end

  if ((CRC_INI & 1) == 1) begin : GEN_CRC_INI_ones
    assign init_crc_reg    = {POLY_SIZE{1'b1}};
  end
endgenerate


  assign crc_ok_remn      = gen_crc_rem(crc_xor_constant);

generate
  if (BIT_ORDER <= 0) begin : GEN_ORDER0
    assign data_in_ro           = fdata_ro0(data_in);
    assign crc_xord_swaped      = fdata_ro0 (crc_xor_res);
  end

  if (BIT_ORDER == 1) begin : GEN_ORDER1
    assign data_in_ro           = fdata_ro1(data_in);
    assign crc_xord_swaped      = fdata_ro1 (crc_xor_res);
  end

  if (BIT_ORDER == 2) begin : GEN_ORDER2
    assign data_in_ro           = fdata_ro2(data_in);
    assign crc_xord_swaped      = fdata_ro2 (crc_xor_res);
  end

  if (BIT_ORDER >= 3) begin : GEN_ORDER3
    assign data_in_ro           = fdata_ro3(data_in);
    assign crc_xord_swaped      = fdata_ro3 (crc_xor_res);
  end
endgenerate



  assign crc_out_next_shifted = fshift_crc_nxt(crc_out_int);
  assign crc_result           = fcalc_crc (data_in_ro, crc_out_int,
                                           draining_status_next);

generate
  if ((POLY_2_DATA_RATIO > 1) && ((DATA_WIDTH & 1) == 1)) begin : GEN_odd_ptrn
    assign crc_ins_mask         = (data_pointer_next[0] == 1'b0) ?
                                   crc_xor_constant[DATA_WIDTH*2-1:DATA_WIDTH]
                                   : crc_xor_constant[DATA_WIDTH-1:0];
  end else                                               begin : GEN_reg_ptrn
    assign crc_ins_mask         = crc_xor_constant[DATA_WIDTH-1:0];
  end
endgenerate

  assign crc_xor_res          = (crc_out_int[POLY_SIZE-1:POLY_SIZE-DATA_WIDTH]
                                 ^ crc_ins_mask);
  assign crc_drn_dat          = crc_xord_swaped;
  assign crc_ok_result        = (crc_out_temp == crc_ok_remn);
  assign data_pointer_next    = ((draining & enable)==1'b1) ?
                                        ((data_pointer == 5'b0)? 5'b0 : {1'b0, (data_pointer[3:0] - 4'b01)})
                                        : data_pointer;


  always @ (draining_status  or drain_done_int or data_pointer_next
            or crc_drn_dat or crc_out_next_shifted or drain
            or data_in or crc_result ) begin : gen_next_states_PROC
    if(draining_status == 1'b0) begin
      if((drain & (~drain_done_int)) == 1'b1) begin
        draining_status_next = 1'b1;
        data_out_next        = crc_drn_dat;
        crc_out_next         = crc_out_next_shifted;
        drain_done_next      = drain_done_int;
      end
      else begin
        draining_status_next = 1'b0;
        data_out_next        = data_in ;
        crc_out_next         = crc_result;
        drain_done_next      = drain_done_int;
      end
    end
    else begin
      if(data_pointer_next == 5'b0) begin
        draining_status_next = 1'b0 ;
        data_out_next        = data_in ;
        crc_out_next         = crc_result;
        drain_done_next      = 1'b1;
      end
      else begin
        draining_status_next = 1'b1 ;
        data_out_next        = crc_drn_dat ;
        crc_out_next         = crc_out_next_shifted;
        drain_done_next      = drain_done_int;
      end
    end

   end

  always @ (crc_in or crc_out_next or ld_crc_n) begin : gen_crc_out_temp_PROC
    if(ld_crc_n == 1'b0) begin
      crc_out_temp      = crc_in;
    end
    else begin
      crc_out_temp      = crc_out_next;
    end
   end

  always @ (posedge ic_clk or negedge ic_rst_n) begin : DW_crc_s_PROC
    if(ic_rst_n == 1'b0) begin
      data_pointer    <= INITIAL_POINTER ;
      crc_out_rg      <= init_crc_reg;
      data_out_int    <= {DATA_WIDTH{1'b0}} ;
      draining_status <= 1'b0 ;
      drain_done_int  <= 1'b0 ;
      crc_ok_int      <= 1'b0;
     end
    else if(init_n == 1'b0) begin
      data_pointer    <= INITIAL_POINTER ;
      crc_out_rg      <= init_crc_reg ;
      data_out_int    <= {DATA_WIDTH{1'b0}} ;
      draining_status <= 1'b0 ;
      drain_done_int  <= 1'b0 ;
      crc_ok_int      <= 1'b0;
     end
    else if(enable == 1'b1) begin
      draining_status <= draining_status_next;
      data_pointer    <= data_pointer_next ;
      data_out_int    <= data_out_next ;
      crc_out_rg      <= crc_out_temp ^ reset_crc_reg ;
      drain_done_int  <= drain_done_next ;
      crc_ok_int      <= crc_ok_result;
    end
   end

  reg [31:0] crc_out_r1;
  reg [31:0] crc_out_r2;
  reg [31:0] crc_out_r3;
  reg [31:0] crc_out_r4;
  reg [ 7:0] data_in_r1;
  reg [ 7:0] data_in_r2;
  reg [ 7:0] data_in_r3;
  reg [ 7:0] data_in_r4;

  always @ (posedge ic_clk or negedge ic_rst_n) begin
    if(ic_rst_n == 1'b0) begin
      crc_out_r1 <= init_crc_reg;
      crc_out_r2 <= init_crc_reg;
      crc_out_r3 <= init_crc_reg;
      crc_out_r4 <= init_crc_reg;
    end
    else if(~init_n) begin
      crc_out_r1 <= init_crc_reg;
      crc_out_r2 <= init_crc_reg;
      crc_out_r3 <= init_crc_reg;
      crc_out_r4 <= init_crc_reg;
    end
    else if(enable) begin
      crc_out_r1 <= crc_out;
      crc_out_r2 <= crc_out_r1;
      crc_out_r3 <= crc_out_r2;
      crc_out_r4 <= crc_out_r3;
    end
  end

  always @ (posedge ic_clk or negedge ic_rst_n) begin
    if(ic_rst_n == 1'b0) begin
      data_in_r1 <= 8'b0;
      data_in_r2 <= 8'b0;
      data_in_r3 <= 8'b0;
      data_in_r4 <= 8'b0;
    end
    else if(~init_n) begin
      data_in_r1 <= 8'b0;
      data_in_r2 <= 8'b0;
      data_in_r3 <= 8'b0;
      data_in_r4 <= 8'b0;
    end
    else if(enable) begin
      data_in_r1 <= data_in;
      data_in_r2 <= data_in_r1;
      data_in_r3 <= data_in_r2;
      data_in_r4 <= data_in_r3;
    end
  end

  wire [31:0] data_in_32;
  assign data_in_32 = {data_in_r1, data_in_r2, data_in_r3,data_in_r4};
  assign crc_ok     = init_n ? data_in_32 == crc_out_r4 : 1'b0;

   assign crc_out_int = crc_out_rg ^ reset_crc_reg ;

   assign crc_out    = crc_out_int;
   assign draining   = draining_status;
   assign data_out   = data_out_int;
   //assign crc_ok     = crc_ok_int;
   assign drain_done = drain_done_int;

endmodule


module apb_ucpd_top (
  input         pclk       , //# APB Clock Signal, used for the bus interface unit, can be asynchronous to the I2C clocks
  input         presetn    , //# APB Reset Signal (active low)
  input         psel       , //# APB Peripheral Select Signal: lasts for two pclk cycles; when asserted indicates that the peripheral has been selected for read/write operation
  input         penable    , //# Strobe Signal: asserted for a single pclk cycle, used for timing read/write operations
  input         pwrite     , //# Write Signal: when high indicates a write access to the peripheral; when low indicates a read access
  input  [ 7:0] paddr      , //# Address Bus: uses the lower 7 bits of the address bus for register decode, ignores bits 0 and 1 so that the 8 registers are on 32 bit boundaries
  input  [31:0] pwdata     , //Write Data Bus: driven by the
  input         ic_clk     , //usbpd clock(HSI16)
  input         ic_rst_n   ,
  input  [ 2:0] cc1_compout, // SR.17:16  TYPEC_VSTATE_CC1
  input  [ 2:0] cc2_compout, // SR.19:18  TYPEC_VSTATE_CC2
  input         cc1_datai  , // cc1_in
  input         cc2_datai  , // cc2_in
  output [ 1:0] phy_en     , // CR.11:10 CCENABLE
  output        set_c500   , // CR.8:7 ANASUBMODE
  output        set_c1500  , // CR.8:7 ANASUBMODE
  output        set_c3000  , // CR.8:7 ANASUBMODE
  output        set_pd     , // CR.9 ANAMODE 1
  output        source_en  , // CR.9 ANAMODE 0
  output        phy_rx_en  , // CR.5 PHYRXEN
  output        cc1_det_en , // CR.20 CC1TCDIS
  output        cc2_det_en , // CR.21 CC2TCDIS
  output        phy_cc1_com, // CR.6 PHYCCSEL 0
  output        phy_cc2_com, // CR.6 PHYCCSEL 1
  output        cc1_datao  , // cc1_out
  output        cc1_dataoen, // cc1_oen
  output        cc2_datao  , // cc2_out
  output        cc2_dataoen, // cc2_oen
  output        ucpd_intr  ,
  output [31:0] prdata
);

  // ----------------------------------------------------------
  // -- local registers and wires
  // ----------------------------------------------------------
  //registers

  //wires
  wire [ 3:0] byte_en     ;
  wire [ 5:0] reg_addr    ;
  wire [31:0] ipwdata     ;
  wire [31:0] iprdata     ;
  wire        ucpden      ;
  wire [ 4:0] transwin    ;
  wire [ 4:0] ifrgap      ;
  wire [ 5:0] hbitclkdiv  ;
  wire [ 2:0] psc_usbpdclk;
  wire [19:0] tx_ordset   ;
  wire [ 9:0] tx_paysize  ;
  wire        wr_en       ;
  wire        rd_en       ;
  wire        txhrst_clr  ;
  wire        txsend_clr  ;
  wire        frs_evt     ;
  wire [ 1:0] vstate_cc1  ;
  wire [ 1:0] vstate_cc2  ;
  wire [ 6:0] tx_status   ;
  wire [ 5:0] rx_status   ;
  wire [ 6:0] rx_ordset   ;
  wire [ 9:0] rx_byte_cnt ;
  wire [ 7:0] rx_byte     ;
  wire        hrst_vld    ;
  wire        tx_hrst     ;
  wire        rxdr_rd     ;
  wire [ 1:0] tx_mode     ;
  wire        tx_ordset_we;
  wire [ 8:0] rx_ordset_en;
  wire        txdr_we     ;
  wire [ 7:0] ic_txdr     ;
  wire        ic_cc_out   ;
  wire [ 1:0] rxfilte     ;
  wire transmit_en;
  wire cc_oen;

  assign cc_out      = ic_cc_out;
  assign cc_in       = phy_cc1_com ? cc1_datai : cc2_datai;
  assign cc1_dataoen = phy_cc1_com ? cc_oen : 1'b0;
  assign cc2_dataoen = phy_cc2_com ? cc_oen : 1'b0;
  assign cc1_datao   = phy_cc1_com ? cc_out : 1'b0;
  assign cc2_datao   = phy_cc2_com ? cc_out : 1'b0;

  apb_ucpd_biu u_apb_ucpd_biu (
    .pclk    (pclk    ), // APB clock
    .presetn (presetn ), // APB reset
    .psel    (psel    ), // APB slave select
    .pwrite  (pwrite  ), // APB write/read
    .penable (penable ), // APB enable
    .paddr   (paddr   ), // APB address
    .pwdata  (pwdata  ), // APB write data bus
    .iprdata (iprdata ), // Internal read data bus
    .wr_en   (wr_en   ), // Write enable signal
    .rd_en   (rd_en   ), // Read enable signal
    .byte_en (byte_en ), // Active byte lane signal
    .reg_addr(reg_addr), // Register address offset
    .ipwdata (ipwdata ), // Internal write data bus
    .prdata  (prdata  )  // APB read data bus
  );

  apb_ucpd_if u_apb_ucpd_if (
    .pclk        (pclk        ),
    .presetn     (presetn     ),
    .wr_en       (wr_en       ),
    .rd_en       (rd_en       ),
    .reg_addr    (reg_addr    ),
    .ipwdata     (ipwdata     ),
    .txhrst_clr  (txhrst_clr  ),
    .txsend_clr  (txsend_clr  ),
    .frs_evt     (frs_evt     ),
    .tx_status   (tx_status   ),
    .rx_status   (rx_status   ),
    .rx_ordset   (rx_ordset   ),
    .rx_byte_cnt (rx_byte_cnt ),
    .rx_byte     (rx_byte     ),
    .hrst_vld    (hrst_vld    ),
    .cc1_compout (cc1_compout ),
    .cc2_compout (cc2_compout ),
    .phy_en      (phy_en      ),
    .set_c500    (set_c500    ),
    .set_c1500   (set_c1500   ),
    .set_c3000   (set_c3000   ),
    .set_pd      (set_pd      ),
    .source_en   (source_en   ),
    .phy_rx_en   (phy_rx_en   ),
    .cc1_det_en  (cc1_det_en  ),
    .cc2_det_en  (cc2_det_en  ),
    .phy_cc1_com (phy_cc1_com ),
    .phy_cc2_com (phy_cc2_com ),
    .ucpden      (ucpden      ),
    .transwin    (transwin    ),
    .ifrgap      (ifrgap      ),
    .hbitclkdiv  (hbitclkdiv  ),
    .psc_usbpdclk(psc_usbpdclk),
    .rx_ordset_en(rx_ordset_en),
    .tx_hrst     (tx_hrst     ),
    .rxdr_rd     (rxdr_rd     ),
    .transmit_en (transmit_en ),
    .tx_mode     (tx_mode     ),
    .ucpd_intr   (ucpd_intr   ),
    .tx_ordset_we(tx_ordset_we),
    .tx_paysize  (tx_paysize  ),
    .txdr_we     (txdr_we     ),
    .rxfilte     (rxfilte     ),
    .tx_ordset   (tx_ordset   ),
    .ic_txdr     (ic_txdr     ),
    .iprdata     (iprdata     )
  );

  apb_ucpd_core u_apb_ucpd_core (
    .ic_clk      (ic_clk      ),
    .ic_rst_n    (ic_rst_n    ),
    .ucpden      (ucpden      ),
    .transwin    (transwin    ),
    .ifrgap      (ifrgap      ),
    .psc_usbpdclk(psc_usbpdclk),
    .hbitclkdiv  (hbitclkdiv  ),
    .tx_hrst     (tx_hrst     ),
    .cc_in       (cc_in       ),
    .transmit_en (transmit_en ),
    .rxdr_rd     (rxdr_rd     ),
    .tx_ordset_we(tx_ordset_we),
    .rx_ordset_en(rx_ordset_en),
    .txdr_we     (txdr_we     ),
    .tx_mode     (tx_mode     ),
    .rxfilte     (rxfilte     ),
    .tx_ordset   (tx_ordset   ),
    .ic_txdr     (ic_txdr     ),
    .tx_paysize  (tx_paysize  ),
    .txhrst_clr  (txhrst_clr  ),
    .txsend_clr  (txsend_clr  ),
    .tx_status   (tx_status   ),
    .rx_status   (rx_status   ),
    .rx_ordset   (rx_ordset   ),
    .rx_byte_cnt (rx_byte_cnt ),
    .rx_byte     (rx_byte     ),
    .hrst_vld    (hrst_vld    ),
    .ic_cc_out   (ic_cc_out   ),
    .cc_oen      (cc_oen      )
  );


endmodule//          finished  file  pd.v           // 
