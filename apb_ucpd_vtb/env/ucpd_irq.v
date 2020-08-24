
/*------------------------------------------------------------------------------
--  tx interpet
------------------------------------------------------------------------------*/
always @(tx_ucpd_intr) begin
  UCPD_TX_IRQHandler();
end

task UCPD_TX_IRQHandler;
  reg [31:0] rdata ;
  begin
    rdata = 0;
    ucpd_read(TRANS, UCPD_SR, rdata);

    if(rdata[0] == SET)
      begin
        ucpd_write(TRANS, UCPD_TXDR, randval);
        tx_processing = 1'b1;
        `ifdef DEBUG_IRQ_ON
          $display("***** enter TXIS: write txdr = 0x%0h, and clear *****", randval);
        `endif
      end

    if(rdata[2] == SET)
      begin
        ucpd_write(TRANS, UCPD_ICR, TXMSGSENTCF_SET);
        ucpd_write(TRANS, UCPD_ICR, TXMSGSENTCF_RESET);
        tx_finished = 1'b1;
        `ifdef DEBUG_IRQ_ON
          $display("***** enter TXMSGSENT: Transmit message sent interrupt, and clear *****");
        `endif
      end

    if(rdata[5] == SET)
      begin
        ucpd_write(TRANS, UCPD_ICR, HRSTSENTCF_SET);
        ucpd_write(TRANS, UCPD_ICR, HRSTSENTCF_RESET);
        tx_hrst_flag = 1'b1;
        // ucpd_write(TRANS, UCPD_CFG1, UCPDEN_DIS);
        `ifdef DEBUG_IRQ_ON
          $display("***** enter HRSTSENT: HRST sent interrupt, and clear *****");
        `endif
      end
  end
endtask

/*------------------------------------------------------------------------------
--  rx interpet
------------------------------------------------------------------------------*/
always @(rx_ucpd_intr) begin
  UCPD_RX_IRQHandler();
end

task UCPD_RX_IRQHandler;
  reg [31:0] rdata;

  begin
    rdata = 0;
    ucpd_read(RCV, UCPD_SR, rdata);

    if(rdata[8] == SET)
      begin
        ucpd_read(RCV, UCPD_RXDR, rxdr);
        `ifdef DEBUG_IRQ_ON
          $display("***** enter RXNE: read rxdr = %0h, and clear *****", rxdr);
        `endif
      end

    if(rdata[9] == SET)
      begin
        ucpd_read(RCV, UCPD_RX_ORDSET, rx_ordset);
        ucpd_write(RCV, UCPD_ICR, RXORDDETCF_SET);
        ucpd_write(RCV, UCPD_ICR, RXORDDETCF_RESET);
        rx_orddet_flag = 1'b1;
        `ifdef DEBUG_IRQ_ON
          $display("***** enter RXORDDET: Rx ordered set detected interrupt, read rx_ordset = 0x%0h *****", rx_ordset);
        `endif
      end

    if(rdata[10] == SET)
      begin
       ucpd_write(RCV, UCPD_ICR, RXHRSTDETCF_SET);
       ucpd_write(RCV, UCPD_ICR, RXHRSTDETCF_RESET);
       rx_hrst_flag = 1'b1;
        `ifdef DEBUG_IRQ_ON
          $display("***** enter RXHRSTDET: Rx Hard Reset detect interrupt and clear *****");
        `endif
      end

    if(rdata[12] == SET)
      begin
        ucpd_read(RCV, UCPD_RX_PAYSZ, rx_paysz);
        ucpd_write(RCV, UCPD_ICR, RXMSGENDCF_SET);
        ucpd_write(RCV, UCPD_ICR, RXMSGENDCF_RESET);
        rx_finished = 1;
        `ifdef DEBUG_IRQ_ON
          $display("***** enter RXMSGEND:  Rx message received , read rx_paysz = %0d *****", rx_paysz);
        `endif
      end


  end
endtask




