////////////////////////////////////////////////////
// Created by MengChao V1.0 2018/12/7 //////////////
////////////////////////////////////////////////////

module AHB_MASTER(
  HCLK   ,
  HADDR  ,
  HBURST ,
  HSIZE  ,
  HTRANS ,
  HWRITE ,
  HWDATA ,
  HRDATA ,
  HREADY ,
  HRESP
);

  parameter ADDR_BITS = 32;
  parameter DATA_BITS = 32;

  input [DATA_BITS-1:0] HRDATA;
  input                 HREADY;
  input [          1:0] HRESP ;

  output                  HCLK  ;
  output [ADDR_BITS-1:0]  HADDR ;
  output [          2:0]  HBURST;
  output [          2:0]  HSIZE ;
  output [          1:0]  HTRANS;
  output                  HWRITE;
  output [DATA_BITS-1:0]  HWDATA;

  reg [ADDR_BITS-1:0]  HADDR ;
  reg [DATA_BITS-1:0]  HWDATA;
  reg [          2:0]  HBURST;
  reg [          2:0]  HSIZE ;
  reg [          1:0]  HTRANS;
  reg                  HWRITE;
  reg                  HCLK  ;

  reg  [1:0] bus_sate;

  initial begin
    HADDR  = 0;
    HBURST = 3'b000;
    HTRANS = 2'b00;
    HWRITE = 1'b0;
    HSIZE  = 3'b000;
    HCLK   = 1'b0 ;
    HWDATA = 0;
    bus_sate =2'b00;
  end

  initial #50 forever #(`TOP.PERIOD_PCLK/2) HCLK = ~HCLK ;

  task ahb_write(input [31:0] addr, input [2:0] size, input [31:0] wdata);
  begin
    @(posedge HCLK);
    #1;
    HSIZE = 1;
    HTRANS = 2'b10;
    HWRITE = 1;
    HADDR = addr;
    @(posedge HCLK);
    #1;
    HWDATA = wdata;
    HADDR = 0;
    HTRANS = 2'b00;
    HWRITE = 0;
    HSIZE = 0;
    @(posedge HCLK);
    #1;
    @(posedge HCLK);
    #1;
    HWDATA = 0;

    `ifdef VERBOSE
      $display ("%t INFO: mst write reg addr 0x%h, wdata 0x%h ", $realtime, addr, wdata);
    `endif
  end
endtask

task ahb_read(input [31:0] addr, input [2:0] size, output [31:0] rdata);
  begin
    @(posedge HCLK);
    #1;
    HADDR = addr;
    HSIZE = 1;
    HTRANS = 2'b10;
    @(posedge HCLK);
    #1;
    HTRANS = 2'b00;
    HADDR = 0;
    HSIZE = 0;
    wait(HREADY);
      rdata = HRDATA;
    @(posedge HCLK);
    #1;

    `ifdef VERBOSE
      $display ("%t INFO: mst read reg addr 0x%h, rdata 0x%h ",$realtime, addr, rdata);
    `endif
  end
endtask

  // task  ahb_write;
  //   input [ADDR_BITS-1 :0] ahb_addr;
  //   input [2:0]            ahb_size;
  //   input [DATA_BITS-1 :0] ahb_wdata;
  //   begin
  //     wait (HCLK) #2
  //       begin
  //         HADDR = ahb_addr ;
  //         HWRITE = 1'b1;
  //         HTRANS = 2'b10;
  //         HSIZE  = ahb_size ;
  //       end
  //     wait (~HCLK) ;
  //     wait (HCLK)  #1
  //       begin
  //         HADDR = 0 ;
  //         HWRITE = 1'b0;
  //         HTRANS = 2'b00;
  //         HWDATA = 0;
  //         HSIZE  = 0 ;
  //         HWDATA = ahb_wdata;
  //         // `ifdef DEBUG_ON
  //         //   $display("%t ns, AHB_WRITE_OK wdata = 0x%h at addrress = 0x%h",$time,ahb_wdata,ahb_addr);
  //         // `endif
  //         if(HREADY)  begin
  //           // $display("%t ns, AHB_WRITE_OK wdata = 0x%h at addrress = 0x%h",$time,ahb_wdata,ahb_addr);
  //         end
  //         else begin
  //           wait (~HCLK) ;
  //           wait (HCLK)  #1 begin
  //             if(HREADY)  begin
  //               $display("%t ns, AHB_WRITE_FAIL wdata = 0x%h at addrress = 0x%h",$time,ahb_wdata,ahb_addr);
  //               $display("%t ns, AHB_HRESP %h\n",$time,HRESP);
  //             end
  //           end
  //         end
  //       end
  //     wait (~HCLK) ;
  //     wait (HCLK)  #2 begin
  //       HADDR = 0 ;
  //       HWRITE = 1'b0;
  //       HTRANS = 2'b00;
  //       HWDATA = 0;
  //       HSIZE  = 0 ;
  //     end
  //   end
  // endtask

  // task  ahb_read;
  //   input [ADDR_BITS-1 :0] ahb_addr;
  //   input [2:0]            ahb_size;
  //   output [DATA_BITS-1 :0] ahb_rdata;

  //   reg [DATA_BITS-1 :0] ahb_rdata ;
  //   begin
  //     wait (HCLK) #2
  //       begin
  //         HADDR = ahb_addr ;
  //         HTRANS = 2'b10;
  //         HSIZE  = ahb_size ;
  //       end
  //     wait (~HCLK) ;
  //     wait (HCLK)  #1
  //       begin
  //         HADDR = 0 ;
  //         HTRANS = 2'b00;
  //         HSIZE  = 0 ;
  //         wait(HREADY);
  //         begin
  //           ahb_rdata = HRDATA ;
  //           // $display("%t ns,AHB_READ_OK rdata = 0x%h at addrress = 0x%h",$time,ahb_rdata,ahb_addr);
  //         end
  //       end
  //     wait (~HCLK) ;
  //     wait (HCLK) #2  begin
  //       HADDR = 0 ;
  //       HTRANS = 2'b00;
  //       HSIZE  = 0 ;
  //     end
  //   end
  // endtask

endmodule