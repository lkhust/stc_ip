// FSMC Controller definitions
// MCU registers

`define AHB_BASE_ADR       32'hA000_0000
`define BANK1_BASE_ADR     32'h6000_0000
`define BANK2_BASE_ADR     32'h7000_0000
`define BANK3_BASE_ADR     32'h8000_0000
`define BANK4_BASE_ADR     32'h9000_0000
`define Bank1_NORSRAM1_ADR 32'h6000_0000
`define Bank1_NORSRAM2_ADR 32'h6400_0000
`define Bank1_NORSRAM3_ADR 32'h6800_0000
`define Bank1_NORSRAM4_ADR 32'h6C00_0000
`define DELAY              10

`define REG_BCR1   `AHB_BASE_ADR + 9'h000
`define REG_BTR1   `AHB_BASE_ADR + 9'h004
`define REG_BCR2   `AHB_BASE_ADR + 9'h008
`define REG_BTR2   `AHB_BASE_ADR + 9'h00C
`define REG_BCR3   `AHB_BASE_ADR + 9'h010
`define REG_BTR3   `AHB_BASE_ADR + 9'h014
`define REG_BCR4   `AHB_BASE_ADR + 9'h018
`define REG_BTR4   `AHB_BASE_ADR + 9'h01C
`define REG_PCR2   `AHB_BASE_ADR + 9'h060
`define REG_SR2    `AHB_BASE_ADR + 9'h064
`define REG_PMEM2  `AHB_BASE_ADR + 9'h068
`define REG_PATT2  `AHB_BASE_ADR + 9'h06C
`define REG_PCR3   `AHB_BASE_ADR + 9'h080
`define REG_SR3    `AHB_BASE_ADR + 9'h084
`define REG_PMEM3  `AHB_BASE_ADR + 9'h088
`define REG_PATT3  `AHB_BASE_ADR + 9'h08C
`define REG_PCR4   `AHB_BASE_ADR + 9'h0A0
`define REG_SR4    `AHB_BASE_ADR + 9'h0A4
`define REG_PMEM4  `AHB_BASE_ADR + 9'h0A8
`define REG_PATT4  `AHB_BASE_ADR + 9'h0AC
`define REG_PIO4   `AHB_BASE_ADR + 9'h0B0
`define REG_ECCR2  `AHB_BASE_ADR + 9'h074
`define REG_ECCR3  `AHB_BASE_ADR + 9'h094
`define REG_BWTR1  `AHB_BASE_ADR + 9'h104
`define REG_BWTR2  `AHB_BASE_ADR + 9'h10C
`define REG_BWTR3  `AHB_BASE_ADR + 9'h114
`define REG_BWTR4  `AHB_BASE_ADR + 9'h11C

// FSMC_BCRx bits
`define MBKEN      32'h0000_0001
`define MUXEN      32'h0000_0002
`define MTYP_SRAM  32'h0000_0000
`define MTYP_CRAM  32'h0000_0004
`define MTYP_NOR   32'h0000_0008
`define MWID_8     32'h0000_0000
`define MWID_16    32'h0000_0010
`define MWID_32    32'h0000_0020
`define FACCEN     32'h0000_0040
`define BURSTEN    32'h0000_0100
`define WAITPOL    32'h0000_0200
`define WRAPMOD    32'h0000_0400
`define WAITCFG    32'h0000_0800
`define WREN       32'h0000_1000
`define WAITEN     32'h0000_2000
`define EXTMOD     32'h0000_4000
`define ASYNCWAIT  32'h0000_8000
`define CBURSTRW   32'h0008_0000

// FSMC_BTRx bits
`define ADDSET     32'h0000_0000
`define ADDHLD     32'h0000_0010
`define DATAST     32'h0000_0100
`define BUSTURN    32'h0002_0000
`define CLKDIV     32'h0000_0000
`define DATLAT     32'h0000_0000
`define ACCMOD_A   32'h0000_0000
`define ACCMOD_B   32'h1000_0000
`define ACCMOD_C   32'h2000_0000
`define ACCMOD_D   32'h3000_0000

// FSMC_BWTRx bits
`define ADDSET_W     32'h0000_0008
`define ADDHLD_W     32'h0000_0020
`define DATAST_W     32'h0000_0500
`define CLKDIV_W     32'h0000_0000
`define DATLAT_W     32'h0000_0000
`define ACCMOD_W_A   32'h0000_0000
`define ACCMOD_W_B   32'h1000_0000
`define ACCMOD_W_C   32'h2000_0000
`define ACCMOD_W_D   32'h3000_0000


`define RESET      0
`define SET        1
`define DISABLE    0
`define ENABLE     1
`define NULL       0
`define BYTE       0
`define HALFWORD   1
`define WORD       2
`define SRAM_SIZE  16 //512

`define CYCLE  20      // Half period of system clock
`define DEL    1      // Input delay for VCI signals (offset from FCLK)
`define VERBOSE        // Enable extra output messages from testbench
`define FSDB           // Enable fsdb output for debussy
`define RANDOM
`define HDEL    1      // Delay of AHB inputs from HCLK

