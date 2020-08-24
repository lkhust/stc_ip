
  $display("");
  $display ("%t INFO: Test Mode A READ, Mode D WRITE, SRAM/PSRAM (CRAM) OE toggling, in 8/16/32 bits mode access Psarm", $realtime);
  repeat(`CYCLE) @(posedge hclk);

  ahb_write_reg(`REG_BCR1, `EXTMOD | `WREN | `MWID_8 | `MTYP_CRAM | `MBKEN);
  ahb_write_reg(`REG_BTR1,  `ACCMOD_A | `DATAST | `ADDHLD | `ADDSET);
  ahb_write_reg(`REG_BWTR1,  `ACCMOD_W_D | `DATAST_W | `ADDHLD_W | `ADDSET_W);
  sram_8b_test(`Bank1_NORSRAM1_ADR);

  $display("");
  $display ("%t INFO: Test Mode A SRAM/PSRAM (CRAM) OE toggling, in 8/16/32 bits mode access Psarm", $realtime);
  repeat(`CYCLE) @(posedge hclk);
  ahb_write_reg(`REG_BCR1, `EXTMOD | `WREN | `MWID_16 | `MTYP_CRAM | `MBKEN);
  ahb_write_reg(`REG_BWTR1, `ACCMOD_W_A | `DATAST_W | `ADDHLD_W | `ADDSET_W);
  sram_16b_test(`Bank1_NORSRAM1_ADR);

  $display("");
  $display ("%t INFO: Test Mode A SRAM/PSRAM (CRAM) OE toggling, in 8/16/32 bits mode access Psarm", $realtime);
  repeat(`CYCLE) @(posedge hclk);
  ahb_write_reg(`REG_BCR1, `EXTMOD | `WREN | `MWID_32 | `MTYP_CRAM | `MBKEN);
  sram_32b_test(`Bank1_NORSRAM1_ADR);

