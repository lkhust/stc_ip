/****************************************************************************************
*
*   Disclaimer   This software code and all associated documentation, comments or other 
*  of Warranty:  information (collectively "Software") is provided "AS IS" without 
*                warranty of any kind. MICRON TECHNOLOGY, INC. ("MTI") EXPRESSLY 
*                DISCLAIMS ALL WARRANTIES EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
*                TO, NONINFRINGEMENT OF THIRD PARTY RIGHTS, AND ANY IMPLIED WARRANTIES 
*                OF MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. MTI DOES NOT 
*                WARRANT THAT THE SOFTWARE WILL MEET YOUR REQUIREMENTS, OR THAT THE 
*                OPERATION OF THE SOFTWARE WILL BE UNINTERRUPTED OR ERROR-FREE. 
*                FURTHERMORE, MTI DOES NOT MAKE ANY REPRESENTATIONS REGARDING THE USE OR 
*                THE RESULTS OF THE USE OF THE SOFTWARE IN TERMS OF ITS CORRECTNESS, 
*                ACCURACY, RELIABILITY, OR OTHERWISE. THE ENTIRE RISK ARISING OUT OF USE 
*                OR PERFORMANCE OF THE SOFTWARE REMAINS WITH YOU. IN NO EVENT SHALL MTI, 
*                ITS AFFILIATED COMPANIES OR THEIR SUPPLIERS BE LIABLE FOR ANY DIRECT, 
*                INDIRECT, CONSEQUENTIAL, INCIDENTAL, OR SPECIAL DAMAGES (INCLUDING, 
*                WITHOUT LIMITATION, DAMAGES FOR LOSS OF PROFITS, BUSINESS INTERRUPTION, 
*                OR LOSS OF INFORMATION) ARISING OUT OF YOUR USE OF OR INABILITY TO USE 
*                THE SOFTWARE, EVEN IF MTI HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
*                DAMAGES. Because some jurisdictions prohibit the exclusion or 
*                limitation of liability for consequential or incidental damages, the 
*                above limitation may not apply to you.
*
*                Copyright 2003 Micron Technology, Inc. All rights reserved.
*
****************************************************************************************/

    // Parameters current with P23Z datasheet rev D

    // Timing parameters based on Speed Grade

                             // SYMBOL UNITS DESCRIPTION
                             // ------ ----- -----------
`ifdef sg701
    parameter tACLK =   7.0; // ns CLK to output delay 
    parameter tCLK  =  9.62; // ns CLK period
    parameter tCSP  =   3.0; // ns CE# setup time to active CLK edge 
    parameter tKP   =   3.0; // ns CLK HIGH or LOW time 
`else `define sg708
    parameter tACLK =   9.0; // ns CLK to output delay 
    parameter tCLK  =  12.5; // ns CLK period
    parameter tCSP  =   4.5; // ns CE# setup time to active CLK edge 
    parameter tKP   =   4.0; // ns CLK HIGH or LOW time 
`endif

    parameter tAPA  =  20.0; // ns Page access time 
    parameter tAS   =   0.0; // ns Address and ADV# LOW setup time 
    parameter tAW   =  70.0; // ns Address valid to end of WRITE 
    parameter tAVH  =   5.0; // ns Address hold from ADV# HIGH
    parameter tAVS  =  10.0; // ns Address setup to ADV# HIGH
    parameter tBW   =  70.0; // ns BY# select to end of WRITE 
    parameter tCBPH =   5.0; // ns CE# HIGH between subsequent burst or mixed-mode operations
    parameter tCPH  =   5.0; // ns CE# HIGH between subsequent async operations 
    parameter tCVS  =  10.0; // ns CE# LOW to ADV# HIGH 
    parameter tCW   =  70.0; // ns Chip enable to end of WRITE 
    parameter tDH   =   0.0; // ns Data hold from WRITE time 
    parameter tDPDX =  10e3; // ns CE# LOW time to exit DPD 
    parameter tDW   =  23.0; // ns Data WRITE setup time
    parameter tHD   =   2.0; // ns Hold time from active CLK edge 
    parameter tOW   =   5.0; // ns End WRITE to Low-Z output
    parameter tPC   =  20.0; // ns Page READ cycle time 
    parameter tPU   = 150e3; // ns Initialization period (required before normal operations) 
    parameter tRC   =  70.0; // ns READ cycle time 
    parameter tSP   =   3.0; // ns Setup time to active CLK edge 
    parameter tVP   =  10.0; // ns ADV# pulse width LOW 
    parameter tVPH  =  10.0; // ns ADV# pulse width HIGH
    parameter tVS   =  70.0; // ns ADV# setup to end of WRITE 
    parameter tWC   =  70.0; // ns WRITE cycle time
    parameter tWPH  =  10.0; // ns WRITE pulse width HIGH
    parameter tWP   =  46.0; // ns WRITE pulse width 
    parameter tWR   =   0.0; // ns WRITE recovery time 



specify
`ifdef sg701
    specparam tABA  =  35.9; // ns Burst to read access time (variable latency)
    specparam tKHTL =   7.0; // ns CLK to WAIT valid 
`else `ifdef sg708
    specparam tABA  =  46.5; // ns Burst to read access time (variable latency)
    specparam tKHTL =   9.0; // ns CLK to WAIT valid 
`endif `endif
    specparam tAA   =  70.0; // ns Address access time
    specparam tAADV =  70.0; // ns ADV# access time
    specparam tAHZ  =   3.0; // ns ADV# HIGH to AD/Q Low-Z output
    specparam tALZ  =   8.0; // ns ADV# LOW to AD/Q High-Z output
    specparam tBA   =  70.0; // ns BY# access time 
    specparam tBHZ  =   8.0; // ns BY# disable to High-Z output
    specparam tBLZ  =  10.0; // ns LB#/UB# enable to Low-Z output 
    specparam tBOE  =  20.0; // ns Burst OE# LOW to output delay CE# HIGH between subsequent burst or mixedmode operations
    specparam tCEM  =   8e3; // ns Maximum CE# pulse width 
    specparam tCEW_MIN= 1.0; // ns Minimum CE# LOW to WAIT valid 
    specparam tCEW_MAX= 7.5; // ns Maximum CE# LOW to WAIT valid 
    specparam tCO   =  70.0; // ns Chip select access time 
    specparam tDPD  =  10e3; // ns Time from DPD entry to DPD exit 
    specparam tHZ   =   8.0; // ns Chip disable to High-Z output 
    specparam tKOH  =   2.0; // ns Output HOLD from CLK 
    specparam tLZ   =  10.0; // ns Chip enable to Low-Z output 
    specparam tOE   =  20.0; // ns Output enable to valid output 
    specparam tOEW_MIN= 1.0; // ns OE# LOW to WAIT valid 
    specparam tOEW_MAX= 7.5; // ns OE# LOW to WAIT valid 
    specparam tOH   =   5.0; // ns Output hold from address change 
    specparam tOHZ  =   8.0; // ns Output disable to High-Z output 
    specparam tOLZ  =   5.0; // ns Output enable to Low-Z output 
    specparam tWHZ  =   8.0; // ns WRITE to A/DQ High-Z output 
    specparam tWI   =  20.0; // ns time WRITE invalid
endspecify


// Size Parameters based on Part Width
`define x16 
    parameter ADQ_BITS       = 20;
    parameter DQ_BITS        = 16;
    parameter BY_BITS        = 2;

    parameter ADDR_BITS      = 20;
    parameter COL_BITS       = 7;           // DIDR[15] = 128 words per row
    parameter MEM_BITS       = 10;

    parameter BCR            = 2'b10;
    parameter RCR            = 2'b00;
    parameter DIDR           = 2'b01;
    parameter REG_SEL        = 18;

    parameter CR10           = 2'b01;
    parameter CR15           = 2'b10;
    parameter CR20           = 2'b11;
    parameter GENERATION     = 2'b01;       // DIDR[7:5] = CR1.0

    parameter CR20WAIT_POLARITY = 1'b1;     // 0 = Active Low, 1 = Active High
    parameter CRE_READ       = 1'b0;        // allow READ using CRE to BCR/RCR
    parameter BCR_MASK       = 18'bxx_1_0_111_1_0_1_0_1_1_0_1_111; // valid bits in BCR
    parameter BCR_DEFAULT    =    16'b1_0_011_1_0_1_0_1_0_0_1_111; 
    parameter RCR_MASK       = 18'b11_00000000_1_11_1_0_111; // valid bits in RCR
    parameter RCR_DEFAULT    =    16'b00000000_0_00_1_0_000;
    parameter DIDR_MASK      = 18'bxx_1_1111_111_111_11111; // valid bits in DIDR
    parameter DIDR_DEFAULT   =    16'b0_0000_000_001_00011;

// Function to return the minimum clock period
function real min_clk_period;
    input initial_latency;
    input [2:0] latency_counter;
    begin
        min_clk_period = 0.0;
`ifdef sg701
        case (latency_counter)
            3'd2   : min_clk_period = 15.00;
            3'd3   : min_clk_period =  9.62;
        endcase
`else `ifdef sg708
        case (latency_counter)
            3'd2   : min_clk_period = 18.75;
            3'd3   : min_clk_period = 12.50;
        endcase
`endif `endif
    end
endfunction

