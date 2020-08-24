
  $display("");
  $display ("%t INFO: Test Mode D Write, Mode D Read NOR Flash, in 8/16/32 bits mode access Psarm", $realtime);
  repeat(`CYCLE) @(posedge hclk);

  ahb_write_reg(`REG_BCR4, `EXTMOD | `WREN | `FACCEN | `MWID_8 | `MTYP_NOR | `MBKEN);
  ahb_write_reg(`REG_BTR4, `ACCMOD_D | `ADDHLD | `DATAST | `ADDHLD | `ADDSET);
  ahb_write_reg(`REG_BWTR4, `ACCMOD_W_D | `ADDHLD_W | `DATAST_W | `ADDHLD_W | `ADDSET_W);
  sram_8b_test(`Bank1_NORSRAM4_ADR);

  $display("");
  $display ("%t INFO: Test Mode D Write, Mode D Read NOR Flash, in 8/16/32 bits mode access Psarm", $realtime);
  repeat(`CYCLE) @(posedge hclk);
  ahb_write_reg(`REG_BCR4, `EXTMOD | `WREN | `FACCEN | `MWID_16 | `MTYP_NOR | `MBKEN);
  sram_16b_test(`Bank1_NORSRAM4_ADR);

  $display("");
  $display ("%t INFO: Test Mode D Write, Mode D Read NOR Flash, in 8/16/32 bits mode access Psarm", $realtime);
  repeat(`CYCLE) @(posedge hclk);
  ahb_write_reg(`REG_BCR4, `EXTMOD | `WREN | `FACCEN | `MWID_32 | `MTYP_NOR | `MBKEN);
  sram_32b_test(`Bank1_NORSRAM4_ADR);

