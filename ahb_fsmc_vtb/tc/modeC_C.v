
  $display("");
  $display ("%t INFO: Test Mode C Write, Test Mode C Read NOR Flash, in 8/16/32 bits mode access Psarm", $realtime);
  repeat(`CYCLE) @(posedge hclk);

  ahb_write_reg(`REG_BCR1, `EXTMOD | `WREN | `FACCEN | `MWID_8 | `MTYP_NOR | `MBKEN);
  ahb_write_reg(`REG_BTR1, `ACCMOD_C | `DATAST | `ADDHLD | `ADDSET);
  ahb_write_reg(`REG_BWTR1, `ACCMOD_W_C | `DATAST_W | `ADDHLD_W | `ADDSET_W);
  sram_8b_test(`Bank1_NORSRAM1_ADR);

  $display("");
  $display ("%t INFO: Test Mode C Write, Test Mode C Read NOR Flash, in 8/16/32 bits mode access Psarm", $realtime);
  repeat(`CYCLE) @(posedge hclk);
  ahb_write_reg(`REG_BCR1, `EXTMOD | `WREN | `FACCEN | `MWID_16 | `MTYP_NOR | `MBKEN);
  sram_16b_test(`Bank1_NORSRAM1_ADR);

  $display("");
  $display ("%t INFO: Test Mode C Write, Test Mode C Read NOR Flash, in 8/16/32 bits mode access Psarm", $realtime);
  repeat(`CYCLE) @(posedge hclk);
  ahb_write_reg(`REG_BCR1, `EXTMOD | `WREN | `FACCEN | `MWID_32 | `MTYP_NOR | `MBKEN);
  sram_32b_test(`Bank1_NORSRAM1_ADR);

