
module ahb2apb_s #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32
) (
  input                   hclk     ,
  input                   hresetn  ,
  input                   hsel_s   ,
  input  [           2:0] hsize_s  ,
  input  [           1:0] htrans_s ,
  input                   hwrite_s ,
  input  [ADDR_WIDTH-1:0] haddr_s  ,
  input  [DATA_WIDTH-1:0] prdata_s ,
  input  [DATA_WIDTH-1:0] hwdata_s ,
  output [DATA_WIDTH-1:0] hrdata_s ,
  output                  pwrite_s ,
  output                  penable_s,
  output                  psel_s   ,
  output                  hready_s ,
  output [DATA_WIDTH-1:0] pwdata_s ,
  output [ADDR_WIDTH-1:0] paddr_s
);
  localparam REGISTER_RDATA = 1    ;
  localparam REGISTER_WDATA = 1    ;

  cmsdk_ahb_to_apb #(
    .ADDRWIDTH     (ADDR_WIDTH),
    .DATAWIDTH     (DATA_WIDTH),
    .REGISTER_RDATA(REGISTER_RDATA),
    .REGISTER_WDATA(REGISTER_WDATA)
  ) cmsdk_ahb_to_apb_slv (
    .HCLK     (hclk     ),
    .HRESETn  (hresetn  ),
    .PCLKEN   (1'b1     ),
    .HSEL     (hsel_s   ),
    .HADDR    (haddr_s  ),
    .HTRANS   (htrans_s ),
    .HSIZE    (hsize_s  ),
    .HPROT    (4'b0     ),
    .HWRITE   (hwrite_s ),
    .HREADY   (1'b1     ),
    .HWDATA   (hwdata_s ),
    .PRDATA   (prdata_s ),
    .PREADY   (1'b1     ),
    .PSLVERR  (1'b0     ),
    .HREADYOUT(hready_s ),
    .HRDATA   (hrdata_s ),
    .HRESP    (         ),
    .PADDR    (paddr_s  ),
    .PENABLE  (penable_s),
    .PWRITE   (pwrite_s ),
    .PSTRB    (         ),
    .PPROT    (         ),
    .PWDATA   (pwdata_s ),
    .PSEL     (psel_s   ),
    .APBACTIVE(         )
  );

endmodule
