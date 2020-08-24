
module ahb2apb_m #(
  parameter ADDR_WIDTH = 32,
  parameter DATA_WIDTH = 32
) (
  input                   hclk     ,
  input                   hresetn  ,
  input                   hsel_m   ,
  input  [           2:0] hsize_m  ,
  input  [           1:0] htrans_m ,
  input                   hwrite_m ,
  input  [ADDR_WIDTH-1:0] haddr_m  ,
  input  [DATA_WIDTH-1:0] hwdata_m ,
  input  [DATA_WIDTH-1:0] prdata_m ,
  output [DATA_WIDTH-1:0] hrdata_m ,
  output                  pwrite_m ,
  output                  penable_m,
  output                  psel_m   ,
  output                  hready_m ,
  output [DATA_WIDTH-1:0] pwdata_m ,
  output [ADDR_WIDTH-1:0] paddr_m
);
  localparam REGISTER_RDATA = 1    ;
  localparam REGISTER_WDATA = 1    ;

  cmsdk_ahb_to_apb #(
    .ADDRWIDTH     (ADDR_WIDTH),
    .DATAWIDTH     (DATA_WIDTH),
    .REGISTER_RDATA(REGISTER_RDATA),
    .REGISTER_WDATA(REGISTER_WDATA)
  ) cmsdk_ahb_to_apb_mst (
    .HCLK     (hclk     ),
    .HRESETn  (hresetn  ),
    .PCLKEN   (1'b1     ),
    .HSEL     (hsel_m   ),
    .HADDR    (haddr_m  ),
    .HTRANS   (htrans_m ),
    .HSIZE    (hsize_m  ),
    .HPROT    (4'b0     ),
    .HWRITE   (hwrite_m ),
    .HREADY   (1'b1     ),
    .HWDATA   (hwdata_m ),
    .PRDATA   (prdata_m ),
    .PREADY   (1'b1     ),
    .PSLVERR  (1'b0     ),
    .HREADYOUT(hready_m ),
    .HRDATA   (hrdata_m ),
    .HRESP    (         ),
    .PADDR    (paddr_m  ),
    .PENABLE  (penable_m),
    .PWRITE   (pwrite_m ),
    .PSTRB    (         ),
    .PPROT    (         ),
    .PWDATA   (pwdata_m ),
    .PSEL     (psel_m   ),
    .APBACTIVE(         )
  );

endmodule
