
  $display("");
  $display ("%t INFO: Test Mode Muxed mode multiplexed asynchronous access to NOR Flash, in 8/16/32 bits mode access Psarm", $realtime);
  repeat(`CYCLE) @(posedge hclk);
  mux2_en = `ENABLE;
  ahb_write_reg(`REG_BCR2, `ASYNCWAIT | `WREN | `FACCEN | `MWID_8 | `MUXEN | `MTYP_NOR | `MBKEN);
  ahb_write_reg(`REG_BTR2, `BUSTURN | `DATAST | `ADDHLD | `ADDSET);
  sram_8b_test(`Bank1_NORSRAM2_ADR);
  mux2_en = `DISABLE;

  $display("");
  $display ("%t INFO: Test Mode Muxed mode multiplexed asynchronous access to NOR Flash, in 8/16/32 bits mode access Psarm", $realtime);
  repeat(`CYCLE) @(posedge hclk);
  mux2_en = `ENABLE;
  ahb_write_reg(`REG_BCR2, `ASYNCWAIT | `WREN | `FACCEN | `MWID_16 | `MUXEN | `MTYP_NOR | `MBKEN);
  ahb_write_reg(`REG_BTR2, `BUSTURN | `DATAST | `ADDHLD | `ADDSET);
  sram_16b_test(`Bank1_NORSRAM2_ADR);
  mux2_en = `DISABLE;

  $display("");
  $display ("%t INFO: Test Mode Muxed mode multiplexed asynchronous access to NOR Flash, in 8/16/32 bits mode access Psarm", $realtime);
  repeat(`CYCLE) @(posedge hclk);
  mux2_en = `ENABLE;
  ahb_write_reg(`REG_BCR2, `ASYNCWAIT | `WREN | `FACCEN | `MWID_32 | `MUXEN | `MTYP_NOR | `MBKEN);
  ahb_write_reg(`REG_BTR2, `BUSTURN | `DATAST | `ADDHLD | `ADDSET);
  sram_32b_test(`Bank1_NORSRAM2_ADR);
  mux2_en = `DISABLE;

