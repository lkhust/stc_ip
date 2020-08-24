//Flexible static memory controller (FSMC) task

task sys_reset;
  begin
    hresetn = 0;
    htrans = 0;
    hsize = 0;
    hwrite = 0;
    haddr = 0;
    hsel = 0;
    hwdata = 0;
    repeat(`CYCLE) @(posedge hclk);
    hresetn = 1;

    `ifdef VERBOSE
      $display ("%t INFO: Simulation is start", $realtime);
    `endif
  end
endtask

task ahb_write_reg(input [31:0] addr, input [31:0] wdata);
  begin
    @(posedge hclk);
    #`DEL;
    hsize = 2;
    htrans = NONSEQ;
    hwrite = 1;
    hsel = 1;
    haddr = addr;
    @(posedge hclk);
    #`DEL;
    hwdata = wdata;
    haddr = 0;
    htrans = IDLE;
    hwrite = 0;
    hsize = 0;
    @(posedge hclk);
    #`DEL;
    hsel = 0;
    hwdata = 0;

    `ifdef VERBOSE
      $display ("%t INFO: write reg addr 0x%h, wdata 0x%h ",$realtime, addr, wdata);
    `endif
  end
endtask

task ahb_read_reg(input [31:0] addr, output [31:0] rdata);
  begin
    @(posedge hclk);
    #`DEL;
    haddr = addr;
    hsize = 2;
    htrans = NONSEQ;
    hwrite = 0;
    hsel = 1;
    @(posedge hclk);
    #`DEL;
    htrans = IDLE;
    haddr = 0;
    hsize = 0;
    @(posedge hclk);
    #`DEL;
    rdata = hrdata;
    hsel = 0;

    `ifdef VERBOSE
      $display ("%t INFO: read reg addr 0x%h, wdata 0x%h ",$realtime, addr, rdata);
    `endif
  end
endtask

task ahb_write_fsmc(input [31:0] addr, input[2:0] size, input [31:0] wdata);
  begin
    @(posedge hclk);
    #`DEL;
    hsize = size;
    htrans = NONSEQ;
    hwrite = 1;
    hsel = 1;
    haddr = addr;
    @(posedge hclk);
    #`DEL;
    htrans = IDLE;
    hwrite = 0;
    haddr = 0;
    hsize = 0;
    hwdata = wdata;
    if(size == `BYTE)
      hwdata = {wdata[7:0], wdata[7:0]};
    else if(size == `HALFWORD)
      hwdata = wdata[15:0];
    @(posedge hclk);
    #`DEL;
    wait (hreadyi);
    hsel = 0;
    hwdata = 0;

    `ifdef VERBOSE
      $display ("%t INFO: Operate fsmc data addr 0x%h, size 0x%h, write data 0x%h", $realtime, addr, size, wdata);
    `endif
  end
endtask

task ahb_read_fsmc(input [31:0] addr, input[2:0] size, output [31:0] rdata);
  reg [7:0] test;
  begin
    test = 7;
    @(posedge hclk);
    #`DEL;
    haddr = addr;
    hsize = size;
    htrans = NONSEQ;
    hwrite = 0;
    hsel = 1;
    @(posedge hclk);
    #`DEL;
    htrans = IDLE;
    haddr = 0;
    hsize = 0;
    @(posedge hclk);
    #`DEL;
    while(!hreadyi)
      begin
        @(posedge hclk);
        #`DEL;

        rdata = hrdata;
        if(size == `BYTE)
          begin
            if(addr[0])
              rdata = hrdata[15:8];
            else
              rdata = hrdata[7:0];
          end
        else if(size == `HALFWORD)
          rdata = hrdata[15:0];
      end

    @(posedge hclk);
    #`DEL;
    //wait(hreadyi)
    hsel = 0;

    `ifdef VERBOSE
      $display ("%t INFO: Operate fsmc data addr 0x%h, size 0x%h, read data 0x%h", $realtime, addr, size, rdata);
    `endif
  end
endtask


task sram_8b_test(input [31:0] addr);
  reg [7:0] temp;
  reg [ 2:0] size;
  begin
    size = `BYTE;
    for (i = 0; i < `SRAM_SIZE; i=i+1) begin
      `ifdef RANDOM
        temp = data_word;
        ahb_write_fsmc(addr+i, size, temp);
      `else
        temp = i;
        ahb_write_fsmc(addr+i, size, temp);
      `endif
      MCUTxData[i] = temp;
    end

    for (i = 0; i < `SRAM_SIZE; i=i+1) begin
      delay(400);

      ahb_read_fsmc(addr+i, size, rdata);
      check(addr+i, MCUTxData[i], rdata);

      `ifdef VERBOSE
        $display ("%t INFO: check count: %d, fsmc data type is %s ", $realtime, i, gettype(size));
      `endif
    end
  end
endtask

task sram_16b_test(input [31:0] addr);
  reg [15:0] temp;
  reg [ 2:0] size;
  begin
    size = `HALFWORD;
    for (i = 0; i < `SRAM_SIZE; i=i+2) begin
      delay(400);
      `ifdef RANDOM
        temp = data_word;
      `else
        temp = i;
      `endif
      ahb_write_fsmc(addr+i, size, temp);
      MCUTxData[i] = temp;

      ahb_read_fsmc(addr+i, size, rdata);
      check(addr+i, MCUTxData[i], rdata);

    end

    delay(400);

    for (i = 0; i < `SRAM_SIZE; i=i+2) begin

      `ifdef RANDOM
        temp = data_word;
      `else
        temp = i;
      `endif
      ahb_write_fsmc(addr+i, size, temp);
      MCUTxData[i] = temp;
    end

    for (i = 0; i < `SRAM_SIZE; i=i+2) begin
      delay(400);

      ahb_read_fsmc(addr+i, size, rdata);
      check(addr+i, MCUTxData[i], rdata);

      `ifdef VERBOSE
        $display ("%t INFO: check count: %d, fsmc data type in HALFWORD mode!", $realtime, i>>1);
      `endif
    end
  end
endtask

task sram_32b_test(input [31:0] addr);
  reg [31:0] temp;
  reg [ 2:0] size;
  begin
    size = `WORD;
    for (i = 0; i < `SRAM_SIZE; i=i+4) begin
      `ifdef RANDOM
        temp = data_word;
        ahb_write_fsmc(addr+i, size, temp);
      `else
        temp = i;
        ahb_write_fsmc(addr+i, size, temp);
      `endif
      MCUTxData[i] = temp;
    end

    for (i = 0; i < `SRAM_SIZE; i=i+4) begin
      delay(400);

      ahb_read_fsmc(addr+i, size, rdata);
      check(addr+i, MCUTxData[i], rdata);

      `ifdef VERBOSE
        $display ("%t INFO: check count: %d, fsmc data type in WORD mode!", $realtime, i>>2);
      `endif
    end
  end
endtask

task norflash_16b_test(input [31:0] addr, input [19:0] bulk_addr1, input [19:0] bulk_addr2);
  reg [15:0] temp;
  begin
    Read_Status_Reg(addr, 20'h01234);
    Clear_Status_Reg(addr);
    Set_Burst_CR(addr, 20'h01234);
    #200;
    Clear_Block_Prot_Reg(addr, 20'h00000);
    Clear_Block_Prot_Reg(addr, 20'h00800);
    Clear_Block_Prot_Reg(addr, 20'h02000);
    Clear_Block_Prot_Reg(addr, 20'h02800);
    Clear_Block_Prot_Reg(addr, 20'h03000);
    Clear_Block_Prot_Reg(addr, 20'h03800);
    Clear_Block_Prot_Reg(addr, 20'h04000);
    Clear_Block_Prot_Reg(addr, 20'h04800);
    #200;

    for (i = 0; i < `SRAM_SIZE; i=i+1) begin
      delay(400);

      `ifdef RANDOM
        temp = data_word;
      `else
        temp = i;
      `endif
      Program_dc40(addr, bulk_addr1+i, temp);
      MCUTxData[i] = temp;
      #15500;
      Read_Array(addr, bulk_addr1+i, rdata);

      check(addr+((bulk_addr1+i)), MCUTxData[i], rdata);
      #200;
    end

    delay(400);

    for (i = 0; i < `SRAM_SIZE; i=i+1) begin

      `ifdef RANDOM
        temp = data_word;
      `else
        temp = i;
      `endif
      Program_dc40(addr, bulk_addr2+i, temp);
      MCUTxData[i] = temp;
      #15500;
    end

    #200;

    for (i = 0; i < `SRAM_SIZE; i=i+1) begin
      delay(400);
      Read_Array(addr, bulk_addr2+i, rdata);
      `ifdef VERBOSE
        $display ("%t INFO: check count: %d, fsmc data type in HALFWORD mode!", $realtime, i);
      `endif
      check(addr+((bulk_addr2+i)), MCUTxData[i], rdata);
    end
  end
endtask

task check (input [31:0] addr, input [31:0] wdata, input [31:0] rdata);
  begin
    if (wdata !== rdata) begin
      $display("%t **ERROR: check 0x%h read from sram address 0x%h, (expected 0x%h) *_* *_* *_* ", $realtime, rdata, addr, wdata);
      $display("%t **ERROR: ***************************************************************", $realtime);
      Errors = Errors + 1;
    end
    else begin
      $display("%t INFO: check address: 0x%h, read: 0x%h, write: 0x%h", $realtime, addr, rdata, wdata);
      $display("%t INFO: check completed without errors, ^_^ ^_^ ", $realtime);
      $display("%t INFO: ===============================================================", $realtime);
    end
  end
endtask

task nwait_set;
  begin
    fsmc_nwait   = 0;
    repeat(2*`CYCLE) @(posedge hclk);
    fsmc_nwait   = 1;
  end
endtask

task delay(input [31:0] dly);
  begin
    if(mux1_en || mux2_en) #dly;
    else #0;
  end
endtask

/*------------------------------------------------------------------------------
--  nor flash task
------------------------------------------------------------------------------*/
task Block_Erase;
  input [31:0] base_addr;
  input [19:0] bulk_addr;
  reg [31:0] addr;
  begin
    addr = base_addr+(bulk_addr<<1);
    ahb_write_fsmc(base_addr+(20'h00055<<1), `HALFWORD, 16'h20);
    ahb_write_fsmc(addr, `HALFWORD, 16'hD0);
  end
endtask

task Erase_All_Main_Blocks;
  input [31:0] base_addr;
  begin
    ahb_write_fsmc(base_addr+(20'h00055<<1), `HALFWORD, 16'h80);
    ahb_write_fsmc(base_addr+(20'h000AA<<1), `HALFWORD, 16'hD0);
  end
endtask

task Read_Status_Reg;
  input [31:0] base_addr;
  input [19:0] bulk_addr;
  reg [31:0] addr;
  begin
    addr = base_addr+(bulk_addr<<1);
    ahb_write_fsmc(addr, `HALFWORD, 16'h70);
  end
endtask

task Clear_Status_Reg;
  input [31:0] base_addr;
  begin
    ahb_write_fsmc(base_addr+20'h00000, `HALFWORD, 16'h50);
  end
endtask

task Set_Burst_CR;
  input [31:0] base_addr;
  input [19:0] bulk_addr;
  reg [31:0] addr;
  begin
    addr = base_addr+(bulk_addr<<1);
    ahb_write_fsmc(base_addr+20'h00000, `HALFWORD, 16'h60);
    ahb_write_fsmc(addr, `HALFWORD, 16'h03);
  end
endtask

task Clear_Block_Prot_Reg;
  input [31:0] base_addr;
  input [19:0] bulk_addr;
  reg [31:0] addr;
  begin
    addr = base_addr+(bulk_addr<<1);
    ahb_write_fsmc(base_addr+20'h00000, `HALFWORD, 16'h60);
    ahb_write_fsmc(addr, `HALFWORD, 16'hD0);
  end
endtask

task Program_dc40;
  input [31:0] base_addr;
  input [19:0] bulk_addr;
  input [15:0] wdata;
  reg [31:0] addr;
  begin
    addr = base_addr+(bulk_addr<<1);
    ahb_write_fsmc(base_addr+(20'h000AA<<1), `HALFWORD, 16'h40);
    ahb_write_fsmc(addr, `HALFWORD, wdata);
  end
endtask

task Read_Array;
  input [31:0] base_addr;
  input [19:0] bulk_addr;
  output [15:0] rdata;
  reg [31:0] addr;
  begin
    addr = base_addr+(bulk_addr<<1);
    ahb_write_fsmc(base_addr+20'h00000, `HALFWORD, 16'hFF);
    ahb_read_fsmc(addr, `HALFWORD, rdata);
  end
endtask

task get_randomVal (output [31:0] val);
  begin
    val = {$random};
  end
endtask

// ----------------------------------------------

function [8*10:1] gettype (input [2:0] size);
  begin
    case (size)
      `BYTE     : gettype = "BYTE";
      `HALFWORD : gettype = "HALFWORD";
      `WORD     : gettype = "WORD";
      default   : gettype = "UNTYPE";
    endcase
  end
endfunction