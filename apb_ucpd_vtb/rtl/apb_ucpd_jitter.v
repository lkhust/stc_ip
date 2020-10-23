module apb_ucpd_jitter (
  input            ic_clk    , // peripherial clock
  input            ic_rst_n  , // ic reset signal active low
  input      [5:0] clk_freq  , // Peripheral clock frequency
  input      [9:0] det_us    , // 1us the most small
  input      [4:0] det_ms    , // 1ms the most small
  input            jitter_in ,
  output reg       jitter_out
);

  localparam MS_CNT_MAX = 999;

  reg [1:0] jitter_in_r   ;
  reg [5:0] us_counter    ;
  reg [9:0] ms_counter    ;
  reg [9:0] us_det_counter;
  reg [4:0] ms_det_counter;
  reg       us_tick       ;
  reg       ms_tick       ;
  reg       ms_jitter     ;
  reg       us_jitter     ;

  assign ms_tick_nxt   = (ms_counter == MS_CNT_MAX);
  assign us_tick_nxt   = (us_counter == clk_freq-1);
  assign ms_jitter_nxt = (ms_det_counter == det_ms);
  assign us_jitter_nxt = (us_det_counter == det_us);

  /*------------------------------------------------------------------------------
  --  check input pin have change
  ------------------------------------------------------------------------------*/
  assign jitter = jitter_in_r[0]^jitter_in;

  /*------------------------------------------------------------------------------
  --  comb logic to sequ
  ------------------------------------------------------------------------------*/
  always @(posedge ic_clk or negedge ic_rst_n)
    begin
      if(ic_rst_n == 1'b0) begin
        us_tick   <= 1'b0;
        ms_tick   <= 1'b0;
        us_jitter <= 1'b0;
        ms_jitter <= 1'b0;
      end
      else begin
        us_tick   <= us_tick_nxt;
        ms_tick   <= ms_tick_nxt;
        us_jitter <= us_jitter_nxt;
        ms_jitter <= ms_jitter_nxt;
      end
    end

  /*------------------------------------------------------------------------------
  --  1us counter
  ------------------------------------------------------------------------------*/
  always @(posedge ic_clk or negedge ic_rst_n)
    begin : us_counter_proc
      if(ic_rst_n == 1'b0)
        us_counter <= 6'd0;
      else if(us_tick)
        us_counter <= 6'd0;
      else
        us_counter <= us_counter + 1;
    end

  /*------------------------------------------------------------------------------
  --  1ms counter
  ------------------------------------------------------------------------------*/
  always @(posedge ic_clk or negedge ic_rst_n)
    begin : ms_counter_proc
      if(ic_rst_n == 1'b0)
        ms_counter <= 10'd0;
      else if(ms_tick)
        ms_counter <= 10'd0;
      else if(us_tick)
        ms_counter <= ms_counter + 1;
    end

  /*------------------------------------------------------------------------------
  --
  ------------------------------------------------------------------------------*/
  always @(posedge ic_clk or negedge ic_rst_n)
    begin : jitter_in_r_proc
      if(ic_rst_n == 1'b0)
        jitter_in_r <= 2'b0;
      else if(us_jitter)
        jitter_in_r <= {jitter_in_r[0], jitter_in};
    end

  /*------------------------------------------------------------------------------
  --  delay sw input det_us dectect time
  ------------------------------------------------------------------------------*/
  always @(posedge ic_clk or negedge ic_rst_n)
    begin : us_det_counter_proc
      if(ic_rst_n == 1'b0)
        us_det_counter <= 10'd0;
      else if(us_jitter)
        us_det_counter <= 10'd0;
      else if(us_tick)
        us_det_counter <= us_det_counter + 1;
    end

  /*------------------------------------------------------------------------------
  --  delay sw input det_ms dectect time
  ------------------------------------------------------------------------------*/
  always @(posedge ic_clk or negedge ic_rst_n)
    begin : ms_det_counter_proc
      if(ic_rst_n == 1'b0)
        ms_det_counter <= 5'd0;
      else if(jitter)
        ms_det_counter <= 5'd0;
      else if(ms_jitter)
        ms_det_counter <= 5'd0;
      else if(ms_tick)
        ms_det_counter <= ms_det_counter + 1;
    end

  /*------------------------------------------------------------------------------
  --  output
  ------------------------------------------------------------------------------*/
  always @(posedge ic_clk or negedge ic_rst_n)
    begin : jitter_out_proc
      if(ic_rst_n == 1'b0)
        jitter_out <= 1'b0;
      else if(ms_jitter)
        jitter_out <= jitter_in_r[0];
    end

endmodule // apb_ucpd_jitter

