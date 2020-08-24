

  $display("");
  $display ("%t INFO: Test Mode READ C WRITE D NOR Flash, in 8/16/32 bits mode access Psarm NE4", $realtime);
  repeat(`CYCLE) @(posedge hclk);
  ahb_write_reg(`REG_BCR4, `EXTMOD | `WREN | `FACCEN | `MWID_16 | `MTYP_NOR | `MBKEN);
  ahb_write_reg(`REG_BTR4, `ACCMOD_C | `DATAST | `ADDHLD | `ADDSET);
  ahb_write_reg(`REG_BWTR4, `ACCMOD_W_D | `ADDHLD_W | `DATAST_W | `ADDHLD_W | `ADDSET_W);
  norflash_16b_test(`Bank1_NORSRAM4_ADR, 20'h04000, 20'h04800);

