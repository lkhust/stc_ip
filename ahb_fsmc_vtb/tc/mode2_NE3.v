
  $display("");
  $display ("%t INFO: Test Mode 2 NOR Flash, in 8/16/32 bits mode access Psarm", $realtime);
  repeat(`CYCLE) @(posedge hclk);

  ahb_write_reg(`REG_BCR3, `WREN | `FACCEN | `MWID_8 | `MTYP_NOR | `MBKEN);
  ahb_write_reg(`REG_BTR3, `DATAST | `ADDHLD | `ADDSET);
  sram_8b_test(`Bank1_NORSRAM3_ADR);

  $display("");
  $display ("%t INFO: Test Mode 2 NOR Flash, in 8/16/32 bits mode access Psarm", $realtime);
  repeat(`CYCLE) @(posedge hclk);
  ahb_write_reg(`REG_BCR3, `WREN | `FACCEN | `MWID_16 | `MTYP_NOR | `MBKEN);
  sram_16b_test(`Bank1_NORSRAM3_ADR);

  $display("");
  $display ("%t INFO: Test Mode 2 NOR Flash, in 8/16/32 bits mode access Psarm", $realtime);
  repeat(`CYCLE) @(posedge hclk);
  ahb_write_reg(`REG_BCR3, `WREN | `FACCEN | `MWID_32 | `MTYP_NOR | `MBKEN);
  sram_32b_test(`Bank1_NORSRAM3_ADR);

