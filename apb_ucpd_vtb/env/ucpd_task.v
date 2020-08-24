
/*------------------------------------------------------------------------------
--  Below task as system task for combine a testcase
------------------------------------------------------------------------------*/
task gen_clk;
  integer count;
  integer i;
  begin
    count = 64;
    for (i = 0; i < count; i=i+1) begin
      ucpd_write(TRANS, UCPD_CFG1, UCPDEN|i<<17|i<<11|i<<6|i<<0);
      Delay(3500);
    end
    // ucpd_write(UCPD_CFG1, UCPDEN|PSC_USBPDCLK|TRANSWIN|IFRGAP|HBITCLKDIV);
  end
endtask

task gen_cnt;
  begin
    Delay(10);
    ucpd_write(TRANS, UCPD_CFG1, HBITCLKDIV|IFRGAP|TRANSWIN|PSC_USBPDCLK);
    Delay(350);
  end
endtask

task trans_init;
  begin
    Delay(10);
    ucpd_write(TRANS, UCPD_CFG1, HBITCLKDIV|IFRGAP|TRANSWIN|PSC_USBPDCLK);
    ucpd_write(TRANS, UCPD_CFG1, UCPDEN);
    Delay(10);
  end
endtask

task recv_init;
  begin
    Delay(10);
    ucpd_write(RCV, UCPD_CFG1, HBITCLKDIV|IFRGAP|TRANSWIN|PSC_USBPDCLK);
    ucpd_write(RCV, UCPD_CFG2, RXFILTDIS);
    ucpd_write(RCV, UCPD_CFG1, UCPDEN);
    ucpd_write(RCV, UCPD_IMR, RXMSGENDIE|RXHRSTDETIE|RXORDDETIE|RXNEIE);
    Delay(10);
  end
endtask

task rx_cfg;
  begin
    Delay(2);
    ucpd_write(RCV, UCPD_CFG1, UCPDEN);
    ucpd_write(RCV, UCPD_IMR, RXMSGENDIE|RXORDDETIE|RXNEIE);
    Delay(2);
  end
endtask

task tx_rx_test(input [7:0] count);
  integer i;
  begin
    for (i = 0; i < count; i=i+1) begin
      ucpd_write(TRANS, UCPD_TX_ORDSET, SOP);
      ucpd_write(TRANS, UCPD_TX_PAYSZ, TXPAYSZ);
      ucpd_write(TRANS, UCPD_TXDR, TXDATA);
      ucpd_write(TRANS, UCPD_IMR, TXMSGSENTIE|TXISIE);

      ucpd_write(TRANS, UCPD_CR, TXSEND);

      wait(tx_finished);
      checks(TXPAYSZ);

      Delay(500);
      tx_finished = 1'b0;
    end

    Delay(1500);
  end
endtask

task tx_rx_hrst(input [7:0] count);
  integer i;
  begin
    for (i = 0; i < count; i=i+1) begin
      $display("");
      ucpd_write(TRANS, UCPD_CFG1, UCPDEN);
      ucpd_write(TRANS, UCPD_TX_ORDSET, SOP);
      ucpd_write(TRANS, UCPD_TX_PAYSZ, TXPAYSZ);
      ucpd_write(TRANS, UCPD_TXDR, TXDATA);
      ucpd_write(TRANS, UCPD_IMR, HRSTSENTIE);

      ucpd_write(TRANS, UCPD_CR, TXHRST);

      wait(rx_hrst_flag);
      Delay(500);
      rx_hrst_flag = 1'b0;
    end

    Delay(1500);
  end
endtask

task tx_rx_data_hrst(input [7:0] count);
  integer i;
  begin
    for (i = 0; i < count; i=i+1) begin
      $display("");
      // ucpd_write(TRANS, UCPD_CFG1, UCPDEN);
      ucpd_write(TRANS, UCPD_TX_ORDSET, SOP);
      ucpd_write(TRANS, UCPD_TX_PAYSZ, TXPAYSZ);
      ucpd_write(TRANS, UCPD_TXDR, TXDATA);
      ucpd_write(TRANS, UCPD_IMR, HRSTSENTIE|TXMSGSENTIE|TXISIE);
      ucpd_write(TRANS, UCPD_CR, TXSEND);
      // wait(tx_finished);
      // tx_finished = 1'b0;
      // checks(TXPAYSZ);
      wait(tx_processing);
      tx_processing =1'b0;
      Delay(10);
      ucpd_write(TRANS, UCPD_CR, TXHRST);

      // ucpd_write(TRANS, UCPD_CR, TXHRST);
      wait(tx_hrst_flag);
      tx_hrst_flag =1'b0;
      Delay(500);
      //ucpd_write(TRANS, UCPD_CFG1, UCPDEN_DIS);
      // wait(rx_hrst_flag);
      // rx_hrst_flag = 1'b0;
      // Delay(1500);
    end

    Delay(1500);
  end
endtask

task tx_rx_crst(input [7:0] count);
  integer i;
  begin
    for (i = 0; i < count; i=i+1) begin
      $display("");
      ucpd_write(TRANS, UCPD_CFG1, UCPDEN);
      ucpd_write(TRANS, UCPD_TX_ORDSET, SOP);
      ucpd_write(TRANS, UCPD_TX_PAYSZ, TXPAYSZ);
      ucpd_write(TRANS, UCPD_TXDR, TXDATA);
      ucpd_write(TRANS, UCPD_IMR, TXMSGSENTIE|TXISIE);

      ucpd_write(TRANS, UCPD_CR, TXSEND|TXMODE);

      wait(tx_finished);
      tx_finished = 1'b0;
      Delay(500);
    end

    Delay(1500);
  end
endtask

task tx_rx_data_crst(input [7:0] count);
  integer i;
  begin
    for (i = 0; i < count; i=i+1) begin
      $display("");
      ucpd_write(TRANS, UCPD_CFG1, UCPDEN);
      ucpd_write(TRANS, UCPD_TX_ORDSET, SOP);
      ucpd_write(TRANS, UCPD_TX_PAYSZ, TXPAYSZ);
      ucpd_write(TRANS, UCPD_TXDR, TXDATA);
      ucpd_write(TRANS, UCPD_IMR, TXMSGSENTIE|TXISIE);

      ucpd_write(TRANS, UCPD_CR, TXSEND);

      wait(tx_finished);
      tx_finished = 1'b0;
      checks(TXPAYSZ);
      Delay(500);

      ucpd_write(TRANS, UCPD_TX_ORDSET, SOP);
      ucpd_write(TRANS, UCPD_TX_PAYSZ, TXPAYSZ);
      ucpd_write(TRANS, UCPD_TXDR, TXDATA);
      ucpd_write(TRANS, UCPD_IMR, TXMSGSENTIE|TXISIE);
      ucpd_write(TRANS, UCPD_CR, TXSEND|TXMODE);
      wait(tx_finished);
      tx_finished = 1'b0;
      Delay(500);
    end

    Delay(1500);
  end
endtask

task checks(input [9:0] size);
  reg [9:0] k;
  begin
    $display("");
    for(k = 0; k < size; k=k+1) begin
      check(k, PD1_tx_buf[k], PD2_rx_buf[k]);
    end
    buf_rd_en = 1'b0;
    i=0;
    j=0;
  end

endtask

task flag_init;
  begin
    finish_flag    = 1'b0;
    tx_finished    = 1'b0;
    rx_finished    = 1'b0;
    tx_processing  = 1'b0;
    buf_rd_en      = 1'b0;
    rx_hrst_flag   = 1'b0;
    tx_hrst_flag   = 1'b0;
    rx_orddet_flag = 1'b0;
  end
endtask
/*------------------------------------------------------------------------------
--  lowest hdl tasks
------------------------------------------------------------------------------*/
task sys_reset;
  begin
    hresetn = 0;
    htrans_m = 0;
    hsize_m = 0;
    hwrite_m = 0;
    haddr_m = 0;
    hsel_m = 0;
    hwdata_m = 0;
    htrans_s = 0;
    hsize_s = 0;
    hwrite_s = 0;
    haddr_s = 0;
    hsel_s = 0;
    hwdata_s = 0;
    #100;
    hresetn = 1;
  end
endtask

task ahb_write_m(input [31:0] addr, input [31:0] wdata);
  begin
    @(posedge hclk);
    #`DEL;
    hsize_m = BIT32;
    htrans_m = NONSEQ;
    hwrite_m = 1;
    hsel_m = 1;
    haddr_m = addr;
    @(posedge hclk);
    #`DEL;
    hwdata_m = wdata;
    haddr_m = 0;
    htrans_m = IDLE;
    hwrite_m = 0;
    hsize_m = 0;
    @(posedge hclk);
    #`DEL;
    @(posedge hclk);
    #`DEL;
    hsel_m = 0;
    hwdata_m = 0;

    `ifdef VERBOSE
      $display ("%t INFO: mst write reg addr 0x%h, wdata 0x%h ", $realtime, addr, wdata);
    `endif
  end
endtask

task ahb_read_m(input [31:0] addr, output [31:0] rdata);
  begin
    @(posedge hclk);
    #`DEL;
    haddr_m = addr;
    hsize_m = BIT32;
    htrans_m = NONSEQ;
    hwrite_m = 0;
    hsel_m = 1;
    @(posedge hclk);
    #`DEL;
    htrans_m = IDLE;
    haddr_m = 0;
    hsize_m = 0;
    wait(hready_m);
      rdata = hrdata_m;
    @(posedge hclk);
    #`DEL;
    hsel_m = 0;

    `ifdef VERBOSE
      $display ("%t INFO: mst read reg addr 0x%h, rdata 0x%h ",$realtime, addr, rdata);
    `endif
  end
endtask

task ahb_write_s(input [31:0] addr, input [31:0] wdata);
  begin
    @(posedge hclk);
    #`DEL;
    hsize_s = BIT32;
    htrans_s = NONSEQ;
    hwrite_s = 1;
    hsel_s = 1;
    haddr_s = addr;
    @(posedge hclk);
    #`DEL;
    hwdata_s = wdata;
    haddr_s = 0;
    htrans_s = IDLE;
    hwrite_s = 0;
    hsize_s = 0;
    @(posedge hclk);
    #`DEL;
    @(posedge hclk);
    #`DEL;
    hsel_s = 0;
    hwdata_s = 0;

    `ifdef VERBOSE
      $display ("%t INFO: slv write reg addr 0x%h, wdata 0x%h ", $realtime, addr, wdata);
    `endif
  end
endtask

task ahb_read_s(input [31:0] addr, output [31:0] rdata);
  begin
    @(posedge hclk);
    #`DEL;
    haddr_s = addr;
    hsize_s = BIT32;
    htrans_s = NONSEQ;
    hwrite_s = 0;
    hsel_s = 1;
    @(posedge hclk);
    #`DEL;
    htrans_s = IDLE;
    haddr_s = 0;
    hsize_s = 0;
    wait(hready_s);
      rdata = hrdata_s;
    @(posedge hclk);
    #`DEL;
    hsel_s = 0;

    `ifdef VERBOSE
      $display ("%t INFO: slv read reg addr 0x%h, rdata 0x%h ",$realtime, addr, rdata);
    `endif
  end
endtask

task  ucpd_write(input [7:0] pd_type, input [31:0] addr, wdata);
  begin
    if(pd_type == TRANS) begin
      ahb_write_m(addr, wdata);
      if(addr == UCPD_TXDR) begin
        PD1_tx_buf[i] = wdata;
        i = i+1;
      end
    end
    else begin
      ahb_write_s(addr, wdata);
      if(addr == UCPD_TXDR) begin
        PD1_tx_buf[i] = wdata;
        i = i+1;
      end
    end
  end
endtask

task  ucpd_read(input [7:0] pd_type, input [31:0] addr, output [31:0] rdata);
  begin
    if(pd_type == TRANS) begin
      ahb_read_m(addr, rdata);
      if(addr == UCPD_RXDR && data_en_tb) begin
        PD2_rx_buf[j] = rdata;
        j = j+1;
      end
    end
    else begin
      ahb_read_s(addr, rdata);
      if(addr == UCPD_RXDR && data_en_tb) begin
        PD2_rx_buf[j] = rdata;
        j = j+1;
      end
    end
  end
endtask

/*------------------------------------------------------------------------------
--  Below task is task tools for testbench
------------------------------------------------------------------------------*/
task get_randomVal (input [7:0] min, max, output [7:0] val);
  begin
    val = min + {$random}%(max - min + 1);
  end
endtask

task Delay (input [31: 0] dely_time);
  begin
    #(`HSI_CYCLE * dely_time);
  end
endtask

task check (input [9:0] addr, input [31:0] wdata, input [31:0] rdata);
  begin
    if (wdata !== rdata) begin
      $display("%t **ERROR: check 0x%0h read at addr %0d (expected 0x%0h) ", $realtime, rdata, addr, wdata);
      $display("%t **ERROR: ***************************************************************", $realtime);
      Errors = Errors + 1;
    end
    else begin
      $display("%t INFO: check at addr %0d read: 0x%0h, write: 0x%0h", $realtime, addr, rdata, wdata);
      $display("%t INFO: check completed without errors, ^_^ ", $realtime);
      $display("%t INFO: ===============================================================", $realtime);
    end
  end
endtask








