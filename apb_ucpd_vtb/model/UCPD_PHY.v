
module UCPD_PHY (
        
        UCPD_PHY_EN,
        SET_C500MA,
        SET_C1500MA,
        SET_C3000MA,
        SET_RD,
        CC,
        
        SOURCE_EN,
        PHY_COMEN,
        PHY_RXEN,        
        PHY_DETEN,
        
        COMPOUT,
        cc_datai,
        cc_datao,
        cc_dataoen,
        VDDL,VSSL,VDD5,VSS5,VDDH,VSSH
) ;
  input  UCPD_PHY_EN ;
  input  SET_C500MA, SET_C1500MA, SET_C3000MA;   //36K/12K/4.7K at 3.3v
  input  SET_RD ;           // 5.1K
  input  PHY_COMEN, PHY_RXEN, PHY_DETEN ;
  output [3:0] COMPOUT ;
  inout  CC;
  
  
  input VDDL,VSSL,VDD5,VSS5,VDDH,VSSH;
 
 
    
  //synopsys translate_off
  /* UCPDPHY */
     reg [3:0] COMPOUT_pre ; 
     
  initial begin
     if(SOURCE_EN)
      begin
        #10000 COMPOUT_pre = 4'b1000 ;
        #10000 COMPOUT_pre = 4'b0100 ;
        #1000000 COMPOUT_pre = 4'b1000 ;
      end
     else
      begin
        #10000 COMPOUT_pre = 4'b0000 ;
        #10000 COMPOUT_pre = 4'b0100 ;
        #1000000 COMPOUT_pre = 4'b0000 ;
      end      
 end
 
 wire [3:0] COMPOUT = ( SET_C500MA | SET_C1500MA | SET_C3000MA ) ? COMPOUT_pre & {PHY_DETEN,PHY_DETEN,PHY_DETEN,PHY_DETEN } : 4'd0 ;
 
 wire cc_datai = PHY_RXEN & PHY_COMEN & UCPD_PHY_EN ? 1'b1 : CC;
 wire CC = cc_dataoen & PHY_COMEN & UCPD_PHY_EN ? cc_datao : 1'bz ;

    
  //synopsys translate_on

     
endmodule
