


  $display("");
  $display ("%t INFO: Test Mode C Write, Mode C Read NOR Flash, in 8/16/32 bits mode access Psarm NE2", $realtime);
  repeat(`CYCLE) @(posedge hclk);
  // ahb_write_reg(`REG_BCR1, `EXTMOD | `WREN | `FACCEN | `MWID_16 | `MTYP_NOR | `MBKEN);
  // ahb_write_reg(`REG_BTR1, `ACCMOD_B | `DATAST | `ADDHLD | `ADDSET);
  // ahb_write_reg(`REG_BWTR1, `ACCMOD_W_C | `DATAST_W | `ADDHLD_W | `ADDSET_W);

  // ahb_write_reg(`REG_BCR2, `WREN | `FACCEN | `MWID_16 | `MTYP_NOR | `MBKEN);
  // ahb_write_reg(`REG_BTR2, `DATAST | `ADDHLD | `ADDSET);
  //
  ahb_write_reg(`REG_BCR2, `EXTMOD | `WREN | `FACCEN | `MWID_8 | `MTYP_NOR | `MBKEN);
  ahb_write_reg(`REG_BTR2, `ACCMOD_C | `DATAST | `ADDHLD | `ADDSET);
  ahb_write_reg(`REG_BWTR2, `ACCMOD_W_C | `DATAST_W | `ADDHLD_W | `ADDSET_W);
  norflash_16b_test(`Bank1_NORSRAM2_ADR, 20'h02000, 20'h02800);

