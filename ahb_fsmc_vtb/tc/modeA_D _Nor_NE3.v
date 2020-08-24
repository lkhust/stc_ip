
  $display("");
  $display ("%t INFO: Test Mode A SRAM/PSRAM (CRAM) OE toggling, in 8/16/32 bits mode access Psarm NE3", $realtime);
  repeat(`CYCLE) @(posedge hclk);
  ahb_write_reg(`REG_BCR3, `EXTMOD | `WREN | `MWID_16 | `MTYP_CRAM | `MBKEN);
  ahb_write_reg(`REG_BTR3,  `ACCMOD_A | `DATAST | `ADDHLD | `ADDSET);
  ahb_write_reg(`REG_BWTR3, `ACCMOD_W_A | `DATAST_W | `ADDHLD_W | `ADDSET_W);
  norflash_16b_test(`Bank1_NORSRAM3_ADR, 20'h03000, 20'h03800);
