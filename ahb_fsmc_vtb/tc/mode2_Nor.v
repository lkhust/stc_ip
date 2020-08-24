

  $display("");
  $display ("%t INFO: Test Mode 2 NOR Flash, in 8/16/32 bits mode access Psarm", $realtime);

  repeat(`CYCLE) @(posedge hclk);
  ahb_write_reg(`REG_BCR1, `WREN | `FACCEN | `MWID_16 | `MTYP_NOR | `MBKEN);
  ahb_write_reg(`REG_BTR1, `DATAST | `ADDHLD | `ADDSET);

  norflash_16b_test(`Bank1_NORSRAM1_ADR, 20'h00000, 20'h00800);



