//          _/             _/_/
//        _/_/           _/_/_/
//      _/_/_/_/         _/_/_/
//      _/_/_/_/_/       _/_/_/              ____________________________________________
//      _/_/_/_/_/       _/_/_/             /                                           /
//      _/_/_/_/_/       _/_/_/            /                                  M58BW16F /
//      _/_/_/_/_/       _/_/_/           /                                           /
//      _/_/_/_/_/_/     _/_/_/          /                                    16Mbit /
//      _/_/_/_/_/_/     _/_/_/         /                 x32,3.3v,boot block,burst /
//      _/_/_/ _/_/_/    _/_/_/        /                                           /
//      _/_/_/  _/_/_/   _/_/_/       /                  Verilog Behavioral Model /
//      _/_/_/   _/_/_/  _/_/_/      /                               Version 1.1 /
//      _/_/_/    _/_/_/ _/_/_/     /                                           /
//      _/_/_/     _/_/_/_/_/_/    /           Copyright (c) 2008 Numonyx B.V. /
//      _/_/_/      _/_/_/_/_/    /___________________________________________/
//      _/_/_/       _/_/_/_/
//      _/_/          _/_/_/
//
//
//             NUMONYX


`include "m58bw16f_defin.v"

`timescale 1ns/1ns

module m58bw16f_512k_sector(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_en, micro_pgm_pulse, micro_ers_pulse, read);


output fail_1su0;
output [`DQMAX - 1:0] dqpad_r;

input [`AMAX - 1:0] add_micro;
input [`AMAX - 1:0] add_read;
input [`DQMAX - 1:0] dqpad_p;
input sect_en;
input micro_pgm_pulse;
input micro_ers_pulse;
input read;

reg [`DQMAX - 1:0] ARRAY [0:16383] ;
reg [`DQMAX - 1:0] ROW;
reg [`DQMAX - 1:0] RL_PROG;
reg [13:0] index;
reg fail_1su0_int;
reg [`DQMAX - 1:0] dqpad_r_int;

integer i;
integer int_size;

assign (strong1, pull0) fail_1su0 = (fail_1su0_int) ? 1'b1 : 1'b0;
assign dqpad_r = (sect_en == 1'b1) ? dqpad_r_int : `tristate_data;


///////////////////////////////////////////////////////////

// INITIALIZATION
initial
   begin
      #2;
      int_size = (512 * 1024)/32;
      for( i = 0; i< int_size ; i = i + 1)
         begin

         ARRAY[i] = 32'hFFFFFFFF;
         // ARRAY[i] = i;
         end
   end

initial
   begin
     fail_1su0_int = 1'b0;
     RL_PROG = 32'h00000000;
   end

//
// Read Section
//

always@(add_read or sect_en or read)
  begin : ASYNC_READ
      #1;
      index = add_read[13:0];
      ROW= ARRAY[index];
		if ((sect_en == 1'b1) && (read == 1'b1))
			begin

			  for ( i = 0 ; i <= 31 ; i = i + 1)
                              dqpad_r_int[i] = ROW[i];
			end
		else if (sect_en == 1'b0)
			begin
                          dqpad_r_int[i] = `tristate_data;
			end
  end

//
// Modify
//

always@(sect_en or add_micro or micro_pgm_pulse or micro_ers_pulse)
   begin: PROGRAMMING
   #1;
     if ((sect_en == 1'b1 ) && (micro_pgm_pulse == 1'b1))

      begin
          index = add_micro[13:0];
          ROW = ARRAY[index];
      #5;
               RL_PROG = ROW[31:0];
               for (i=0 ; i<32; i=i+1)
                   begin
                     if ((RL_PROG[i] == 1'b0) && (dqpad_p[i] == 1'b1))
                        begin
                          fail_1su0_int = 1'b1;
                        end
                     else
                        begin
                          fail_1su0_int = 1'b0;
                        end
                     RL_PROG[i] = ROW[i] && dqpad_p[i] ;
                   end
               ARRAY[index] = RL_PROG;
         end
           else if ((sect_en == 1'b1 ) &&(micro_ers_pulse == 1'b1))
              begin
                for (i = 0; i < int_size ; i = i + 1)
                    begin
                      ARRAY[i] = 32'hFFFFFFFF;
                    end

              end
  end
endmodule

`timescale 1ns/1ns


module m58bw16f_64k_sector(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_en, micro_pgm_pulse, micro_ers_pulse, read);


output fail_1su0;
output [`DQMAX - 1:0] dqpad_r;

input [`AMAX - 1:0] add_micro;
input [`AMAX - 1:0] add_read;
input [`DQMAX - 1:0] dqpad_p;
input sect_en;
input micro_pgm_pulse;
input micro_ers_pulse;
input read;

reg [`DQMAX - 1:0] ARRAY [0:2047] ;
reg [`DQMAX - 1:0] ROW;
reg [`DQMAX - 1:0] RL_PROG;
reg [13:0] index;
reg fail_1su0_int;
reg [`DQMAX - 1:0] dqpad_r_int;

integer int_size;
integer i;

assign (strong1, pull0) fail_1su0 = (fail_1su0_int) ? 1'b1 : 1'b0;
assign dqpad_r = (sect_en == 1'b1) ? dqpad_r_int : `tristate_data;


///////////////////////////////////////////////////////////

// INITIALIZATION
initial
   begin
      #2;
      int_size = (64 * 1024)/32;
      for( i = 0; i< int_size ; i = i + 1)
         begin
         ARRAY[i] = 32'hFFFFFFFF;
         // ARRAY[i] = i;
         end
   end

initial
   begin
     fail_1su0_int = 1'b0;
     RL_PROG = 32'h00000000;
   end

//
// Read Section
//

always@(add_read or sect_en or read)
	begin : ASYNC_READ
		#1;
		index = add_read[10:0];
		ROW   = ARRAY[index];
		if ((sect_en == 1'b1) && (read == 1'b1))
			begin
				for ( i = 0 ; i <= 31 ; i = i + 1)
					dqpad_r_int[i] = ROW[i];

			end
		else
			dqpad_r_int[i] = `tristate_data;
	end

//
// Modify
//

always@(sect_en or add_micro or micro_pgm_pulse or micro_ers_pulse)
   begin: PROGRAMMING
     #1;
     if ((sect_en == 1'b1) && (micro_pgm_pulse == 1'b1))


      begin
          index = add_micro[10:0];

          ROW = ARRAY[index];
          #5;


               RL_PROG = ROW[31:0];
               for (i=0 ; i<32; i=i+1)
                   begin
                     if ((RL_PROG[i] == 1'b0) && (dqpad_p[i] == 1'b1))
                        begin
                          fail_1su0_int = 1'b1;
                        end
                     else
                        begin
                          fail_1su0_int = 1'b0;
                        end
                     RL_PROG[i] = ROW[i] && dqpad_p[i] ;
                   end

               ARRAY[index] = RL_PROG;


               end
       else if ((sect_en == 1'b1) &&(micro_ers_pulse == 1'b1))
              begin
                for (i = 0; i < int_size ; i = i + 1)
                    begin
                      ARRAY[i] = 32'hFFFFFFFF;

                    end



              end
     end

endmodule

`timescale 1ns/1ns

module m58bw16f_add_control (A_int, A);


output [`AMAX - 1:0] A_int;
input [`AMAX - 1:0] A;
assign A_int[13:0] = A[13:0];
assign A_int[`AMAX-1 :14] = (`top == 1'b1) ? A[`AMAX-1 :14] : (~A[`AMAX - 1:14]);
endmodule
`timescale 1ns/1ns

module m58bw16f_burst_conf_register (async_read_mcr, latency_mcr, ylatency_mcr, valid_R_mcr, valid_Kedge_mcr, wrap_mcr, burst_length_mcr, bcr_data, add_mod, set_bcr_reg, RP_);


input [`AMAX - 1:0] add_mod;
input set_bcr_reg;
input RP_;

output [`bcr_size - 1:0] bcr_data;
reg [`bcr_size - 1:0] bcr_data;

output async_read_mcr;
reg async_read_mcr;
output [2:0] latency_mcr;
reg [2:0] latency_mcr;
output ylatency_mcr;
reg ylatency_mcr;
output valid_R_mcr;
reg valid_R_mcr;
output valid_Kedge_mcr;
reg valid_Kedge_mcr;
output wrap_mcr;
reg wrap_mcr;
output [2:0] burst_length_mcr;
reg [2:0] burst_length_mcr;

reg [15:0] bcr_data_in;

always@(posedge set_bcr_reg)
   begin
      bcr_data_in = add_mod[15:0];
   end

always@(bcr_data)
   begin
     async_read_mcr = bcr_data[15];
     ylatency_mcr = bcr_data[9];
     valid_R_mcr = bcr_data[8];
     valid_Kedge_mcr = bcr_data[6];
     wrap_mcr = bcr_data[3];
   end

always@(bcr_data[13:11])
  begin
    case(bcr_data[13:11])
      3'b001: latency_mcr = bcr_data[13:11] + 3'b001;
      3'b010: latency_mcr = bcr_data[13:11] + 3'b001;
      3'b011: latency_mcr = bcr_data[13:11] + 3'b001;
      3'b100: latency_mcr = bcr_data[13:11] + 3'b001;
      3'b101: latency_mcr = bcr_data[13:11] + 3'b001;
      3'b110: latency_mcr = bcr_data[13:11] + 3'b001;
      default : latency_mcr = 3'bxxx;
    endcase
  end

always@(bcr_data[2:0])
  begin
    case(bcr_data[2:0])
      3'b001: burst_length_mcr = bcr_data[2:0];
      3'b010: burst_length_mcr = bcr_data[2:0];
      3'b111: burst_length_mcr = bcr_data[2:0];
      default : burst_length_mcr = 3'bxxx;
    endcase
  end

always@(RP_ or set_bcr_reg)
  begin
    #1;
    if (RP_ == 1'b0)
      begin
          bcr_data =`bcr_data_init;
      end
    else if (set_bcr_reg == 1'b1)
      begin
          bcr_data = bcr_data_in;
      end
  end

endmodule
`timescale 1ns / 1ns

module m58bw16f_burst_control (R, add_read, burst_clock, burst_add, burst_ready, B_, valid_Kedge_mcr, K, L_, latency_mcr, burst_length_mcr, ylatency_mcr, async_read_mcr, reset_por, valid_R_mcr);


output [`AMAX - 1:0] add_read;
output burst_clock;
output R;

input [`AMAX - 1:0] burst_add;
input burst_ready;
input B_;
input valid_Kedge_mcr;
input K;
input L_;
input [2:0] latency_mcr;
input [2:0] burst_length_mcr;
input ylatency_mcr;
input async_read_mcr;
input reset_por;
input valid_R_mcr;

wire B;
wire g_count_en;
wire g_count_rst;
wire [31:0] g_count;
wire lat_count_en;
wire lat_count_rst;
wire [31:0] lat_count;
reg [31:0] lat_offset;
wire [31:0] lat_count_end;

wire add_read_count_en;
wire add_read_count_rst;
wire [31:0] add_read_count;

wire allign_count_en;
wire allign_count_rst;
wire [31:0] allign_count;

wire [31:0] allign_begin;
wire [31:0] allign_end;
wire [31:0] allign_offset;
reg [31:0] allign_cycles;

reg page_count_en;

wire internal_clk;
wire R_latency;
wire R_mcr;
reg clock_div_two;

reg g_count_en_l ;
reg lat_count_en_l ;
reg add_read_count_en_l ;
reg allign_count_en_l ;
reg allign_count_en_l_l ;
reg allign_count_en_l_l_l ;
reg allign_en ;

reg [`AMAX - 1:0] add_read_count_rit;
reg [`AMAX - 1:0] burst_add_rit;

assign R_latency = ((lat_count_en == 1'b1) || (lat_count_en_l == 1'b1));
assign R_mcr = (valid_R_mcr == 1'b0) ? allign_count_en_l_l_l : allign_count_en_l;// to be checked the polarity

assign R = (burst_ready == 1'b1) ? ((R_latency == 1'b1) || (R_mcr == 1'b1)) : 1'bz;

m58bw16f_counter latency_count(lat_count, end_op, lat_count_rst, burst_clock, lat_count_en_l);
m58bw16f_counter allign_counter(allign_count, end_op, allign_count_rst, burst_clock, allign_count_en_l);
m58bw16f_burst_counter global_count(g_count, end_op, g_count_rst, burst_clock, g_count_en_l, burst_add);
m58bw16f_burst_counter add_read_counter(add_read_count, end_op, add_read_count_rst, burst_clock, add_read_count_en_l, burst_add);

assign g_count_rst = (burst_ready == 1'b0) ? 1'b1 : 1'b0;
assign g_count_en = ((burst_ready == 1'b1) && (B == 1'b1)) ? 1'b1 : 1'b0;

assign lat_count_end = (latency_mcr - lat_offset - 1);
assign lat_count_rst = (burst_ready == 1'b0) ? 1'b1 : 1'b0;
assign lat_count_en = ((burst_ready == 1'b1) && (lat_count <= lat_count_end)) ? 1'b1 : 1'b0;

assign add_read_count_rst = lat_count_en;
assign add_read_count_en = ((page_count_en == 1'b0) || (lat_count_en == 1'b1) || (allign_count_en == 1'b1)) ? 1'b0 : B;

assign allign_end = (allign_begin + allign_cycles);

assign allign_count_rst = lat_count_en;
assign allign_count_en = (((g_count >= allign_begin) && (g_count < allign_end)) && (lat_count_en == 1'b0) && (B == 1'b1)) ? allign_en : 1'b0;

assign B = (B_) ? 1'b0 : 1'b1;

assign internal_clk = (valid_Kedge_mcr == 1'b1) ? K : (~K);
assign burst_clock = (ylatency_mcr == 1'b0) ? internal_clk : clock_div_two;

assign add_read = (async_read_mcr == 1'b1) ? burst_add_rit : add_read_count_rit;

assign allign_offset = (valid_Kedge_mcr == 1'b1) ? 3'b001: 3'b010;
assign allign_begin = latency_mcr + `boundary + allign_offset - burst_add[4:0];

always@(burst_add[4:0])
  begin
    case (burst_add[4:0])
      5'b11101:
         begin
           allign_en = 1'b1;
           allign_cycles = 1;
         end
      5'b11110:
         begin
           allign_en = 1'b1;
           allign_cycles = 2;
         end
      5'b11111:
         begin
           allign_en = 1'b1;
           allign_cycles = 3;
         end
      default:
         begin
           allign_en = 1'b0;
           allign_cycles = 3;
         end
    endcase
  end

always@(burst_add)
  begin
    #42;
    burst_add_rit = burst_add;
  end

always@(add_read_count)
  begin
    #8;
    add_read_count_rit = add_read_count;
  end

always@(negedge burst_clock or async_read_mcr)
  begin
    if (async_read_mcr == 1'b1)
       begin
         g_count_en_l = 1'b0;
         lat_count_en_l = 1'b0;
         add_read_count_en_l = 1'b0;
         allign_count_en_l = 1'b0;
       end
    else
       begin
         g_count_en_l = g_count_en;
         lat_count_en_l = lat_count_en;
         add_read_count_en_l = add_read_count_en;
         allign_count_en_l = allign_count_en;
       end

  end

always@(posedge burst_clock or async_read_mcr)
  begin
    if (async_read_mcr == 1'b1)
       begin
         allign_count_en_l_l = 1'b0;
       end
    else
       begin
         allign_count_en_l_l = allign_count_en_l;
       end

  end

always@(negedge burst_clock or async_read_mcr)
  begin
    if (async_read_mcr == 1'b1)
       begin
         allign_count_en_l_l_l = 1'b0;
       end
    else
       begin
         allign_count_en_l_l_l = allign_count_en_l_l;
       end

  end



always@(L_ or burst_ready)
  begin
    if (burst_ready == 1'b0)
       lat_offset = 0;
    else
        if (L_ == 1'b0)
           lat_offset = 1;
        else
           lat_offset = 0;
  end

always@(negedge burst_clock or burst_length_mcr or add_read_count or reset_por or burst_add)
  begin
    if (reset_por == 1'b1)
       page_count_en = 1'b1;
    else
       page_count_en = 1'b1;
       case (burst_length_mcr)
          3'b001:
             begin
               if (add_read_count == 3'b011 + burst_add)
                  page_count_en = 1'b0;
             end
          3'b010:
             begin
               if (add_read_count == 3'b111 + burst_add)
                  page_count_en = 1'b0;
             end
          3'b111:
               page_count_en = 1'b1;
          default:
               page_count_en = 1'b1;
       endcase
  end

// Clock Div Two System


always@(posedge internal_clk or reset_por)
  begin
    if (reset_por == 1'b1)
       clock_div_two = 1'b1;
    else
       clock_div_two = ~clock_div_two;
  end

endmodule
`timescale 1ns/1ns

module m58bw16f_burst_counter (count, end_op, reset_count, micro_clk, enable_count, burst_add);


output [31:0] count;
reg [31:0] count;

input end_op;
input reset_count;
input micro_clk;
input enable_count;
input [`AMAX - 1:0] burst_add;

initial
   begin
     count = 0;
   end

//always@(posedge micro_clk or reset_count or enable_count)
always@(posedge micro_clk or reset_count)
  begin
      if (reset_count == 1'b1)
         count = burst_add;
      else if (enable_count == 1'b1)
         count = count + 1;
  end

endmodule
`timescale 1ns/1ns

module m58bw16f_cfi_sector(dqpad_cfi, add_read, read_cfi_cui);


output [`DQMAX - 1:0] dqpad_cfi;

input [`AMAX - 1:0] add_read;
input read_cfi_cui;

reg [`DQMAX - 1:0] ARRAY [0:16383] ;
reg [`DQMAX - 1:0] ROW;
reg [13:0] index;
reg [`DQMAX - 1:0] dqpad_cfi_int;

integer i;
integer int_size;

assign dqpad_cfi = (read_cfi_cui == 1'b1) ? dqpad_cfi_int : `tristate_data;


///////////////////////////////////////////////////////////

// INITIALIZATION
initial
   begin
      #2;
      int_size = (512 * 1024)/32;
      for( i = 0; i< int_size ; i = i + 1)
         begin
         ARRAY[i] = 32'hFFFFFFFF;
         end
   end

//
// Read Section
//

always@(add_read or read_cfi_cui)
  begin : READ
      #1;
      index = add_read[13:0];
		ROW = ARRAY[index];
		if (read_cfi_cui == 1'b1)
			begin
			  for ( i = 0 ; i <= 31 ; i = i + 1)
                              dqpad_cfi_int[i] = ROW[i];
			end
		else
                    dqpad_cfi_int[i] = `tristate_data;
  end

endmodule

`timescale 1ns / 1ns

module m58bw16f_controls (data_mod, add_read, add_mod, E_, K, L_, W_, B_, reset_por, A, latency_mcr, burst_length_mcr, async_read_mcr, DQ);


input E_;
input K;
input L_;
input W_;
input B_;
input reset_por;
input [`AMAX - 1:0] A;
//input [`AMAX - 1:0] A_int;
input [2:0] latency_mcr;
input [2:0] burst_length_mcr;
input async_read_mcr;
input [`DQMAX - 1:0] DQ;

output [`AMAX - 1:0] add_read;
reg [`AMAX - 1:0] add_read;
output [`AMAX - 1:0] add_mod;
reg [`AMAX - 1:0] add_mod;
output [`DQMAX - 1:0] data_mod;
reg [`DQMAX - 1:0] data_mod;


wire L;
wire wen;

reg burst_reset;
reg burst_ready;
reg burst_out;
reg page_end;
reg burst_end;
reg [1:0] allign_add;
reg [`AMAX - 1:0] add_sync;
reg [`AMAX - 1:0] add_async;


integer page_count;
integer add;

assign L = (L_) ? 1'b0 : 1'b1;
assign wen = (W_ || E_) ? 1'b1 : 1'b0;

always@(reset_por)
  begin
      if (reset_por==1'b1)
         begin
             burst_reset = 1'b1;
         end
  end

always@(posedge L)
      begin
        #1 burst_reset = 1'b0;
        #2 burst_reset = 1'b1;
        #1 burst_reset = 1'b0;
      end

always@(posedge L or posedge K or burst_reset)
  begin
      #1;
      if (burst_reset == 1'b1 )
        begin
          burst_ready = 1'b0;
        end
      else if ((K == 1'b1) || (L == 1'b1))
        begin
          burst_ready = 1'b1;
        end
  end

always@(posedge burst_ready or burst_reset)
  begin
      if (burst_reset == 1'b1)
         begin
        allign_add = A[1:0];
        add_sync = A;
        add_async = A;

           page_count = 0;
         end
      else
         begin
          allign_add = A[1:0];
          add_sync = A;
          add_async = A;
           page_count = 0;
         end
  end

always@(add_async or add_sync or async_read_mcr)
  begin
    if (async_read_mcr == 1'b1)
      begin
       #`tACC;
       add_read = add_async;
      end
    else
      begin
       #`tKHQV;
       add_read = add_sync;
      end
  end

always@(posedge K or burst_ready)
  begin
    if (burst_ready == 1'b0)
       add = 1;
    else
       add = add + 1;
  end

always@(add)
  begin
    if (burst_ready == 1'b0)
      burst_out = 1'b0;
    else if (1 <= add <= (latency_mcr - 1))
      burst_out = 1'b0;
    else if (latency_mcr <= add <= (`boundary - allign_add))
      burst_out = 1'b1;
    else if ((`boundary - allign_add) < add <= (`boundary + allign_add))
      burst_out = 1'b0;
    else
      burst_out = 1'b1;
  end

always@(posedge K or burst_out)
  begin
    if (burst_out == 1'b0)

      add_sync = A;
    else if ((burst_out == 1'b1) && (B_ == 1'b0) && (burst_end == 1'b0))
       add_sync = add_sync + 1;
    else
       add_sync = add_sync;
  end

always@(posedge K or burst_out)
  begin
      case (burst_length_mcr)
       3'b001: page_end = 4;
       3'b010: page_end = 8;
       default: page_end = 0; // continous
      endcase
  end

always@(posedge K or burst_out)
  begin
    if (page_count == 1'b0)
       page_count = 1;
    else if ((burst_out == 1'b1) && (B_ == 1'b0) && (burst_end == 1'b0))
       page_count = page_count + 1;
  end

always@(page_count)
  begin
    if (page_count == page_end)
       burst_end = 1'b1;
    else
       burst_end = 1'b0;
  end

// Write Section

always@(posedge wen or reset_por or A)
  begin
      if (reset_por==1'b1)
         begin
             add_mod = `initial_address;
         end
      else
         begin
         add_mod = A;
         end
  end

always@(posedge wen or reset_por or DQ)
  begin
      if (reset_por==1'b1)
         begin
             data_mod = `initial_data;
         end
      else
         begin
             data_mod = DQ;
         end
  end

endmodule
`timescale 1ns/1ns

module m58bw16f_counter (count, end_op, reset_count, micro_clk, enable_count);


output [31:0] count;
reg [31:0] count;
input end_op;
input reset_count;
input micro_clk;
input enable_count;

initial
   begin
     count = 0;
   end

always@(posedge micro_clk or reset_count)
  begin
      if (reset_count == 1'b1) begin
         count = 0;
      end
      else if (enable_count == 1'b1) begin

         count = count + 1;
      end
  end

endmodule
`timescale 1ns / 1ns

module m58bw16f_cui (holdsr7, wb_susp_cui, pgm_susp_cui, ers_susp_cui, read_array_cui, read_es_cui, read_cfi_cui, cmd_err, peon_cui, otp_prog_cui, erase_a_cui, program_cui, erase_cui, set_prot_reg_en, wb_resume_cui, ers_resume_cui, pgm_resume_cui, set_bcr_reg, wb_program_cui, wb_load_address_cui, wb_load_data_cui, wb_on_cui, set_prot_reg, clear_prot_reg, clear_sr_cui, read_sr, DQ, A, W_, E_, RP_, sr_reg5, sr_reg4, wb_end_load, modify, suspend, reset_por);


wire praddok;

output wb_resume_cui;
output ers_resume_cui;
output pgm_resume_cui;

output read_sr;
output clear_sr_cui;
output set_prot_reg;
output clear_prot_reg;
output wb_on_cui;
output peon_cui;
output wb_load_address_cui;
output wb_load_data_cui;
output wb_program_cui;
output set_bcr_reg;
output set_prot_reg_en;
output erase_cui;
output program_cui;
output erase_a_cui;
output otp_prog_cui;
output cmd_err;
output read_es_cui;
output read_cfi_cui;
output read_array_cui;
output ers_susp_cui;
output pgm_susp_cui;
output wb_susp_cui;
output holdsr7;

reg set_prot_reg_en;
reg peon_cui_int;
reg program_cui;
reg erase_cui;
reg erase_a_cui;
reg wb_program_cui;
reg otp_prog_cui;
reg cmd_err;
reg read_es_cui;
reg read_cfi_cui;
reg read_array_cui;
reg ers_susp_cui;
reg pgm_susp_cui;
reg wb_susp_cui;
reg ers_resume_int;
reg pgm_resume_int;
reg wb_resume_int;
reg holdsr7;

input [`AMAX - 1:0] A;
input [`DQMAX - 1:0] DQ;
input sr_reg4;
input sr_reg5;
input W_;
input E_;
input RP_;
input wb_end_load;
input modify;
input suspend;
input reset_por;

reg [`Cmd_Size - 1:0] cmdbus;
reg [`Cmd_Size - 1:0] addbus;
reg [7:0] memory_state;
reg [7:0] memory_next_state;
wire wen_cycle;
reg cui_clk;
wire sr45_fail;

reg read_sr_int;
reg clear_sr_int;
reg set_prot_reg_int;
reg clear_prot_reg_int;
reg wb_on_cui_int;
reg wb_load_address_cui_int;
reg wb_load_data_cui_int;

reg set_bcr_reg_int;
reg set_prot_reg_en_int;

//time startTime;
assign read_sr = read_sr_int;

assign wen_cycle = (RP_) ? ((W_ || E_) ? 1'b1 : 1'b0) : 1'b1;
assign sr45_fail = (sr_reg4 || sr_reg5) ? 1'b1 : 1'b0;
assign praddok = (A == 20'h00003) ? 1'b1 : 1'b0;

assign clear_sr_cui = clear_sr_int;
assign set_prot_reg = (cui_clk) ? set_prot_reg_int : 1'b0;
assign clear_prot_reg = (cui_clk) ? clear_prot_reg_int : 1'b0;
assign wb_on_cui = (cui_clk) ? wb_on_cui_int : 1'b0;
assign wb_load_address_cui = (cui_clk) ? wb_load_address_cui_int : 1'b0;
assign wb_load_data_cui = (cui_clk) ? wb_load_data_cui_int : 1'b0;
assign set_bcr_reg = (cui_clk) ? set_bcr_reg_int : 1'b0;
assign peon_cui = (cui_clk) ? peon_cui_int : 1'b0;
assign ers_resume_cui = (cui_clk) ? ers_resume_int : 1'b0;
assign pgm_resume_cui = (cui_clk) ? pgm_resume_int : 1'b0;
assign wb_resume_cui = (cui_clk) ? wb_resume_int : 1'b0;

// Task Definitions

task cui_cycle ;
begin
        #1;
        cui_clk = 1'b1 ;
        #3 ;
        cui_clk = 1'b0 ;
end
endtask

// Main Cui Commands

initial@(reset_por)
  begin
    #1;
    if (reset_por == 1'b0)
       begin
         memory_state = `READARRAY;
         memory_next_state = 8'h00;
         cui_clk = 1'b0;
       end
  end

always@(cui_clk)
  begin
    #1;

    if (cui_clk == 1'b1)
       memory_state = memory_next_state;
       set_prot_reg_en = set_prot_reg_en_int ;
  end

always@(wen_cycle or RP_)
  begin
    #1;
    if (RP_ == 1'b0)
       begin
          cmdbus = 8'hff;
          addbus = 8'h00;
       end
    else if (wen_cycle == 1'b0)
       begin
          cmdbus = DQ[`Cmd_Size - 1:0];
          addbus = A[`Cmd_Size - 1:0];
       end
  end

always@(posedge wen_cycle)
  begin
        cui_cycle ;
  end

always@(memory_state)
  begin
    if (memory_state == `READARRAY)
       read_array_cui = 1'b1;
    else
       read_array_cui = 1'b0;
  end

always@(posedge cui_clk or addbus or cmdbus or sr45_fail)
  begin
    read_sr_int = 1'b0;
    clear_sr_int = 1'b0;
    set_prot_reg_int = 1'b0;
    clear_prot_reg_int = 1'b0;
    wb_on_cui_int = 1'b0;
    wb_load_address_cui_int = 1'b0;
    wb_load_data_cui_int = 1'b0;
    set_bcr_reg_int = 1'b0;// da vedere
    set_prot_reg_en_int = 1'b0;
    erase_cui = 1'b0;
    program_cui = 1'b0;
    erase_a_cui = 1'b0;
    erase_cui = 1'b0;
    wb_program_cui = 1'b0;
    otp_prog_cui = 1'b0;
    peon_cui_int = 1'b0;
    cmd_err = 1'b0;
    read_es_cui = 1'b0;
    read_cfi_cui = 1'b0;
    ers_susp_cui = 1'b0;
    pgm_susp_cui = 1'b0;
    wb_susp_cui = 1'b0;
    wb_resume_int = 1'b0;
    ers_resume_int = 1'b0;
    pgm_resume_int = 1'b0;
    holdsr7 = 1'b0;
    case (memory_state)
    `READARRAY:
       begin // 8'hFF
         if (cmdbus === `dc20 && addbus === `dc55) // Erase
            begin
               memory_next_state = `ERASU;
               peon_cui_int = 1'b1;
            end
         else if (cmdbus == `dc80 && addbus == `dc55) // Bank Erase
            begin
               memory_next_state = `BKERASU;
               peon_cui_int = 1'b1;
            end
         else if ((cmdbus == `dc40 || cmdbus == `dc10) && addbus == `dcAA) // Program
            begin
               memory_next_state = `PROGSU;
               peon_cui_int = 1'b1;
            end
         else if (cmdbus == `dcE8 && addbus == `dcAA && (sr45_fail == 1'b0)) // Write To Buffer, not Accepted if SR4 or SR5
            begin
               memory_next_state = `WRBUFSU;
               wb_on_cui_int = 1'b1;
               read_sr_int = 1'b1;
            end
         else if (cmdbus == `dc49 && addbus == `dcAA) // OTP Protection Program
            begin
               memory_next_state = `OPPROGSU;
               peon_cui_int = 1'b1;
            end
         else if (cmdbus == `dc60) // set RCR, lock/unlock block
            begin
               memory_next_state = `RCRLOCKSU;
               set_prot_reg_en_int = 1'b1;
            end
         else if (cmdbus == `dc50) // Clear SR
            begin
               memory_next_state = `READARRAY;
               clear_sr_int = 1'b1;
            end
         else if (cmdbus == `dc70) // read SR
            begin
               memory_next_state = `READARRAY;
               read_sr_int = 1'b1;
            end
         else if (cmdbus == `dc90) // read Electronic Signature
            begin
               memory_next_state = `READARRAY;
               read_es_cui = 1'b1;
            end
         else if (cmdbus == `dc98) // read CFI
            begin
               memory_next_state = `READARRAY;
               read_cfi_cui = 1'b1;
            end
         else
               memory_next_state = `READARRAY;
       end
    `ERASU:
       begin
         if (cmdbus == `dcD0)
            begin
               memory_next_state = `ERA;
               read_sr_int = 1'b1;
               erase_cui = 1'b1;
            end
         else
            begin
               memory_next_state = `READARRAY;
               read_sr_int = 1'b1;
               cmd_err = 1'b1;
            end
       end
    `BKERASU:
       begin
         if (cmdbus == `dcD0 && addbus == `dcAA)
            begin
               memory_next_state = `BKERA;
               read_sr_int = 1'b1;
               erase_a_cui = 1'b1;
            end
         else
            begin
               memory_next_state = `READARRAY;
               read_sr_int = 1'b1;
               cmd_err = 1'b1;
            end
       end
    `ERA:
       begin
         if (cmdbus == `dcB0 && modify == 1'b1) // Erase suspend
            begin
               memory_next_state = `ESWAIT;
               read_sr_int = 1'b1;
               ers_susp_cui = 1'b1;
            end
         else if (modify == 1'b1) // Erase in Progress
            begin
               memory_next_state = `ERA;
               read_sr_int = 1'b1;
            end
         else if (cmdbus == `dc20 && addbus == `dc55) // Erase
            begin
               memory_next_state = `ERASU;
               peon_cui_int = 1'b1;
            end
         else if (cmdbus == `dc80 && addbus == `dc55) // Bank Erase
            begin
               memory_next_state = `BKERASU;
               peon_cui_int = 1'b1;
            end
         else if ((cmdbus == `dc40 || cmdbus == `dc10) && addbus == `dcAA) // Program
            begin
               memory_next_state = `PROGSU;
               peon_cui_int = 1'b1;
            end
         else if (cmdbus == `dcE8 && addbus == `dcAA && sr45_fail == 1'b0) // WB if SR45<>1
            begin
               memory_next_state = `WRBUFSU;
               read_sr_int = 1'b1;
               wb_on_cui_int = 1'b1;
            end
         else if (cmdbus == `dc49 && addbus == `dcAA) // OTP Prot Program
            begin
               memory_next_state = `OPPROGSU;
               peon_cui_int = 1'b1;
            end
         else if (cmdbus == `dc60) // Set_RCR
            begin
               memory_next_state = `RCRLOCKSU;
               set_prot_reg_en_int = 1'b1;
            end
         else if (cmdbus == `dc50) // clear_sr_int_reg
            begin
               memory_next_state = `READARRAY;
               clear_sr_int = 1'b1;
            end
         else if (cmdbus == `dc70) // read_sr_int
            begin
               memory_next_state = `READARRAY;
               read_sr_int = 1'b1;
            end
         else if (cmdbus == `dc90) // read Elect Sig
            begin
               memory_next_state = `READARRAY;
               read_es_cui = 1'b1;
            end
         else if (cmdbus == `dc98) // read CFI
            begin
               memory_next_state = `READARRAY;
               read_cfi_cui = 1'b1;
            end
         else
            begin
               memory_next_state = `READARRAY;
            end
       end
    `BKERA:
       begin
         if (modify == 1'b1) // Bank Erase In Progress
            begin
               read_sr_int = 1'b1;
               erase_a_cui = 1'b1;
               memory_next_state = `BKERA;
            end
         else if (cmdbus == `dc20 && addbus == `dc55) // Erase in Progress
            begin
               memory_next_state = `ERASU;
               peon_cui_int = 1'b1;
            end
         else if (cmdbus == `dc80 && addbus == `dc55) // bank erase
            begin
               memory_next_state = `ERASU;
               peon_cui_int = 1'b1;
            end
         else if ((cmdbus == `dc40 || cmdbus == `dc10) && addbus == `dcAA) // Program
            begin
               memory_next_state = `PROGSU;
               peon_cui_int = 1'b1;
            end
         else if (cmdbus == `dcE8 && addbus == `dcAA && sr45_fail == 1'b0) // WB if SR45<>1
            begin
               memory_next_state = `WRBUFSU;
               read_sr_int = 1'b1;
               wb_on_cui_int = 1'b1;
            end
         else if (cmdbus == `dc49 && addbus == `dcAA) // OTP Prot Program
            begin
               memory_next_state = `OPPROGSU;
               peon_cui_int = 1'b1;
            end
         else if (cmdbus == `dc60) // Set_RCR
            begin
               memory_next_state = `RCRLOCKSU;
               set_prot_reg_en_int = 1'b1;
            end
         else if (cmdbus == `dc50) // clear_sr_int_reg
            begin
               memory_next_state = `READARRAY;
               clear_sr_int = 1'b1;
            end
         else if (cmdbus == `dc70) // read_sr_int
            begin
               memory_next_state = `READARRAY;
               read_sr_int = 1'b1;
            end
         else if (cmdbus == `dc90) // read Elect Sig
            begin
               memory_next_state = `READARRAY;
               read_es_cui = 1'b1;
            end
         else if (cmdbus == `dc98) // read CFI
            begin
               memory_next_state = `READARRAY;
               read_cfi_cui = 1'b1;
            end
         else
            begin
               memory_next_state = `READARRAY;
            end
       end
    `ESWAIT:
       begin
         if (modify == 1'b0 && suspend == 1'b0 && cmdbus == `dcFF) // Bank Erase In Progress
            begin
               read_sr_int = 1'b1;
               memory_next_state = `READARRAY;
            end
         else if (suspend == 1'b0)
            begin
               memory_next_state = `ESWAIT;
               read_sr_int = 1'b1;
               ers_susp_cui = 1'b1;
            end
         else if (cmdbus == `dcD0) //Erase Resume
            begin
               memory_next_state = `ERA;
               read_sr_int = 1'b1;
               ers_resume_int = 1'b1;
               erase_cui = 1'b1;
               peon_cui_int = 1'b1;
            end
         else if ((cmdbus == `dc40 || cmdbus == `dc10) && addbus == `dcAA) //Program in Erase suspend
            begin
               memory_next_state = `ESPROGSU;
               ers_susp_cui = 1'b1;
               peon_cui_int = 1'b1;
            end
         else if (cmdbus == `dcE8 && addbus == `dcAA && sr45_fail == 1'b0) // WB if SR45<>1
            begin
               memory_next_state = `ESWRBUFSU;
               ers_susp_cui = 1'b1;
               read_sr_int = 1'b1;
               wb_on_cui_int = 1'b1;
            end
         else if (cmdbus == `dc60) // Set_RCR
            begin
               memory_next_state = `ESRCRLOCKSU;
               set_prot_reg_en_int = 1'b1;
            end
         else if (cmdbus == `dc50) // clear_sr_int_reg
            begin
               memory_next_state = `ESWAIT;
               clear_sr_int = 1'b1;
            end
         else if (cmdbus == `dc70) // read_sr_int
            begin
               memory_next_state = `ESWAIT;
               read_sr_int = 1'b1;
            end
         else if (cmdbus == `dc90) // read Elect Sig
            begin
               memory_next_state = `ESWAIT;
               read_es_cui = 1'b1;
            end
         else if (cmdbus == `dc98) // read CFI
            begin
               memory_next_state = `ESWAIT;
               read_cfi_cui = 1'b1;
            end
         else
            begin
               memory_next_state = `ESWAIT;
            end
       end
    `ESPROGSU:
       begin
          memory_next_state = `ESPROG;
          program_cui = 1'b1;
       end
    `ESPROG:
       begin
         if (cmdbus == `dcB0 && modify == 1'b1) // program suspend in erase suspend
            begin
               memory_next_state = `ESPSWAIT;
               read_sr_int = 1'b1;
               pgm_susp_cui = 1'b1;
            end
         else if (modify == 1'b1) // program suspend in erase suspend
            begin
               memory_next_state = `ESPROG;
               read_sr_int = 1'b1;
               program_cui = 1'b1; // to be checked
            end
         else if (cmdbus == `dcD0) // erase resume
            begin
               memory_next_state = `ERA;
               read_sr_int = 1'b1;
               erase_cui = 1'b1;
               peon_cui_int = 1'b1;
               ers_resume_int = 1'b1;
            end
         else if ((cmdbus == `dc40 || cmdbus == `dc10) && addbus == `dcAA) // program in erase suspend
            begin
              // memory_next_state = `ESPROGSU;
                memory_next_state = `PROGSU;

               peon_cui_int = 1'b1;
            end
         else if (cmdbus == `dcE8 && addbus == `dcAA && sr45_fail == 1'b0) // WB if SR45<>1
            begin
               memory_next_state = `ESWRBUFSU;
               read_sr_int = 1'b1;
               wb_on_cui_int = 1'b1;
            end
         else if (cmdbus == `dc50) // clear_sr_int_reg
            begin
               memory_next_state = `ESWAIT;
               clear_sr_int = 1'b1;
            end
         else if (cmdbus == `dc70) // read_sr_int
            begin
               memory_next_state = `ESWAIT;
               read_sr_int = 1'b1;
            end
         else if (cmdbus == `dc90) // read Elect Sig
            begin
               memory_next_state = `ESWAIT;
               read_es_cui = 1'b1;
            end
         else if (cmdbus == `dc98) // read CFI
            begin
               memory_next_state = `ESWAIT;
               read_cfi_cui = 1'b1;
            end
         else
            begin
               memory_next_state = `ESWAIT;
            end
       end
    `ESPSWAIT:
       begin
         if (cmdbus == `dcFF && modify == 1'b0 && suspend == 1'b0) // program suspend in erase suspend
            begin
               memory_next_state = `ESWAIT;
               ers_susp_cui = 1'b1;
            end
         else if (suspend == 1'b0)
            begin
               memory_next_state = `ESPSWAIT;
               read_sr_int = 1'b1;
               pgm_susp_cui = 1'b1;
            end
         else if (cmdbus == `dcD0) // Program Resume
            begin
               memory_next_state = `ESPROG;
               read_sr_int = 1'b1;
               program_cui = 1'b1; //to be checked
               peon_cui_int = 1'b1;
               pgm_resume_int = 1'b1;
            end
         else if (cmdbus == `dc50) // clear_sr_int_reg
            begin
               memory_next_state = `ESPSWAIT;
               clear_sr_int = 1'b1;
               pgm_susp_cui = 1'b1;
            end
         else if (cmdbus == `dc70) // read_sr_int
            begin
               memory_next_state = `ESPSWAIT;
               read_sr_int = 1'b1;
               pgm_susp_cui = 1'b1;
            end
         else if (cmdbus == `dc90) // read Elect Sig
            begin
               memory_next_state = `ESPSWAIT;
               pgm_susp_cui = 1'b1;
               read_es_cui = 1'b1;
            end
         else if (cmdbus == `dc98) // read CFI
            begin
               memory_next_state = `ESPSWAIT;
               pgm_susp_cui = 1'b1;
               read_cfi_cui = 1'b1;
            end
         else
            begin
               memory_next_state = `ESPSWAIT;
               pgm_susp_cui = 1'b1;
            end
       end
    `PROGSU:
        begin
          memory_next_state = `PROG;
          program_cui = 1'b1;
          read_sr_int = 1'b1;
        end
    `PROG:
       begin
         if (cmdbus == `dcB0 && modify == 1'b1) // Program suspend
            begin
               memory_next_state = `PSWAIT;
               read_sr_int = 1'b1;
               pgm_susp_cui = 1'b1;
            end
         else if (modify == 1'b1) // Program in Progress
            begin
               memory_next_state = `PROG;
               read_sr_int = 1'b1;
               program_cui = 1'b1;
            end
         else if (cmdbus == `dc20 && addbus == `dc55) // Erase
            begin
               memory_next_state = `ERASU;
               peon_cui_int = 1'b1;
            end
         else if (cmdbus == `dc80 && addbus == `dc55) // Bank Erase
            begin
               memory_next_state = `BKERASU;
               peon_cui_int = 1'b1;
            end
         else if ((cmdbus == `dc40 || cmdbus == `dc10) && addbus == `dcAA) // Program
            begin
               memory_next_state = `PROGSU;
               peon_cui_int = 1'b1;
            end
         else if (cmdbus == `dcE8 && addbus == `dcAA && sr45_fail == 1'b0) // WB if SR45<>1
            begin
               memory_next_state = `WRBUFSU;
               read_sr_int = 1'b1;
               wb_on_cui_int = 1'b1;
            end
         else if (cmdbus == `dc49 && addbus == `dcAA) // OTP Prot Program
            begin
               memory_next_state = `OPPROGSU;
               peon_cui_int = 1'b1;
            end
         else if (cmdbus == `dc60) // set_RCR
            begin
               memory_next_state = `RCRLOCKSU;
               set_prot_reg_en_int = 1'b1;
            end
         else if (cmdbus == `dc50) // clear_sr_int_reg
            begin
               memory_next_state = `READARRAY;
               clear_sr_int = 1'b1;
            end
         else if (cmdbus == `dc70) // read_sr_int
            begin
               memory_next_state = `READARRAY;
               read_sr_int = 1'b1;
            end
         else if (cmdbus == `dc90) // read Elect Sig
            begin
               memory_next_state = `READARRAY;
               read_es_cui = 1'b1;
            end
         else if (cmdbus == `dc98) // read CFI
            begin
               memory_next_state = `READARRAY;
               read_cfi_cui = 1'b1;
            end
         else
            begin
               memory_next_state = `READARRAY;
            end
       end
    `PSWAIT:
       begin
         if (cmdbus == `dcFF && modify == 1'b0 && suspend == 1'b0)
            begin
               memory_next_state = `READARRAY;
            end
         else if (suspend == 1'b0)
            begin
               memory_next_state = `PSWAIT;
               read_sr_int = 1'b1;
               pgm_susp_cui = 1'b1;
            end
         else if (cmdbus == `dcD0) // Program Resume
            begin
               memory_next_state = `PROG;
               read_sr_int = 1'b1;
               program_cui = 1'b1;
               peon_cui_int = 1'b1;
               pgm_resume_int = 1'b1;
            end
         else if (cmdbus == `dc50) // clear_sr_int_reg
            begin
               memory_next_state = `PSWAIT;
               clear_sr_int = 1'b1;
               pgm_susp_cui = 1'b1;
            end
         else if (cmdbus == `dc70) // read_sr_int
            begin
               memory_next_state = `PSWAIT;
               read_sr_int = 1'b1;
               pgm_susp_cui = 1'b1;
            end
         else if (cmdbus == `dc90) // read Elect Sig
            begin
               memory_next_state = `PSWAIT;
               pgm_susp_cui = 1'b1;
               read_es_cui = 1'b1;
            end
         else if (cmdbus == `dc98) // read Elect Sig
            begin
               memory_next_state = `PSWAIT;
               pgm_susp_cui = 1'b1;
               read_cfi_cui = 1'b1;
            end
         else
            begin
               memory_next_state = `PSWAIT;
            end
       end
    `RCRLOCKSU:
       begin
         if (cmdbus == `dc03) // set burst configuration register
            begin
               memory_next_state = `READARRAY;
               set_bcr_reg_int = 1'b1;
            end
         else if (cmdbus == `dc01) // set block lock
            begin
               memory_next_state = `READARRAY;
               read_sr_int = 1'b1;
               set_prot_reg_int = 1'b1;
               set_prot_reg_en_int = 1'b1;
            end
         else if (cmdbus == `dcD0) // unlock lock
            begin
               memory_next_state = `READARRAY;
               read_sr_int = 1'b1;
               clear_prot_reg_int = 1'b1;
               set_prot_reg_en_int = 1'b1;
            end
         else
            begin
               memory_next_state = `READARRAY;
               cmd_err = 1'b1;
               read_sr_int = 1'b1;
            end
       end
    `ESRCRLOCKSU:
       begin
         if (cmdbus == `dc03) // set burst configuration register
            begin
               memory_next_state = `ESWAIT;
               set_bcr_reg_int = 1'b1;
            end
         else if (cmdbus == `dc01) // set block lock
            begin
               memory_next_state = `ESWAIT;
               read_sr_int = 1'b1;
               set_prot_reg_int = 1'b1;
               set_prot_reg_en_int = 1'b1;
            end
         else if (cmdbus == `dcD0) // unlock lock
            begin
               memory_next_state = `ESWAIT;
               read_sr_int = 1'b1;
               clear_prot_reg_int = 1'b1;
               set_prot_reg_en_int = 1'b1;
            end
         else
            begin
               read_sr_int = 1'b1;
               cmd_err = 1'b1;
               memory_next_state = `ESWAIT;
            end
       end
    `WRBUFSU:
       begin
         memory_next_state = `WRBUF;
         wb_load_address_cui_int = 1'b1;
         peon_cui_int = 1'b1;
       end
    `WRBUF:
       begin
         if (cmdbus == `dcD0 && wb_end_load == 1'b1 && sr45_fail == 1'b0)
            begin
               memory_next_state = `PAGEPROG;
               wb_program_cui = 1'b1;

            end
         else if (wb_end_load == 1'b0 && sr45_fail == 1'b0)
            begin
               memory_next_state = `WRBUF;
               read_sr_int = 1'b1;
               //prova
               wb_load_data_cui_int = 1'b1;
            end
         else
            begin
               cmd_err = 1'b1;
               read_sr_int = 1'b1;
               memory_next_state = `READARRAY;
            end
       end
    `PAGEPROG:
       begin
         if (cmdbus == `dcB0 && modify == 1'b1) // Erase suspend
            begin
               memory_next_state = `PAGEPSWAIT;
               read_sr_int = 1'b1;
               wb_susp_cui = 1'b1;
            end
         else if (cmdbus == `dcE8 && addbus == `dcAA && sr45_fail == 1'b0 && modify == 1'b1) // WB if SR45<>1
            begin
               memory_next_state = `PAGEPROG;
               read_sr_int = 1'b1;
               wb_on_cui_int = 1'b1;
               holdsr7 = 1'b1;
            end
         else if (modify == 1'b1)
            begin
               memory_next_state = `PAGEPROG;
               read_sr_int = 1'b1;
            end
         else if (cmdbus == `dcE8 && addbus == `dcAA && sr45_fail == 1'b0) // WB if SR45<>1
            begin
               memory_next_state = `WRBUFSU;
               read_sr_int = 1'b1;
               wb_on_cui_int = 1'b1;
            end
         else if (cmdbus == `dc20 && addbus == `dc55) // erase
            begin
               memory_next_state = `ERASU;
               peon_cui_int = 1'b1;
            end
         else if (cmdbus == `dc80 && addbus == `dc55) // bank erase
            begin
               memory_next_state = `BKERASU;
               peon_cui_int = 1'b1;
            end
         else if ((cmdbus == `dc40 || cmdbus == `dc10) && addbus == `dcAA) // program
            begin
               memory_next_state = `PROGSU;
               peon_cui_int = 1'b1;
            end
         else if (cmdbus == `dc49 && addbus == `dcAA) // OTP Prot Program
            begin
               memory_next_state = `OPPROGSU;
               peon_cui_int = 1'b1;
            end
         else if (cmdbus == `dc60) // Set_RCR
            begin
               memory_next_state = `RCRLOCKSU;
               set_prot_reg_en_int = 1'b1;
               read_sr_int = 1'b1;
            end
         else if (cmdbus == `dc50) // clear_sr_int_reg
            begin
               memory_next_state = `READARRAY;
               clear_sr_int = 1'b1;
            end
         else if (cmdbus == `dc70) // read_sr_int
            begin
               memory_next_state = `READARRAY;
               read_sr_int = 1'b1;
            end
         else if (cmdbus == `dc90) // read Elect Sig
            begin
               memory_next_state = `READARRAY;
               read_es_cui = 1'b1;
            end
         else if (cmdbus == `dc98) // read Elect Sig
            begin
               memory_next_state = `READARRAY;
               read_cfi_cui = 1'b1;
            end
         else
            begin
               memory_next_state = `READARRAY;
            end
       end
    `PAGEPSWAIT:
       begin
         if (cmdbus == `dcFF && modify == 1'b0 && suspend == 1'b0) // Erase suspend
            begin
               memory_next_state = `READARRAY;
            end
         else if (suspend == 1'b0)
            begin
               memory_next_state = `PAGEPSWAIT;
               read_sr_int = 1'b1;
               wb_susp_cui = 1'b1;
            end
         else if (cmdbus == `dcD0)
            begin
               memory_next_state = `PAGEPROG;
               read_sr_int = 1'b1;
               wb_program_cui = 1'b1;
               peon_cui_int = 1'b1;
               wb_resume_int = 1'b1;
            end
         else if (cmdbus == `dc50) // clear_sr_int_reg
            begin
               memory_next_state = `PAGEPSWAIT;
               clear_sr_int = 1'b1;
            end
         else if (cmdbus == `dc70) // read_sr_int
            begin
               memory_next_state = `PAGEPROG;
               read_sr_int = 1'b1;
            end
         else if (cmdbus == `dc90) // read Elect Sig
            begin
               memory_next_state = `PAGEPSWAIT;
               read_es_cui = 1'b1;
            end
         else if (cmdbus == `dc98) // read Elect Sig
            begin
               memory_next_state = `PAGEPSWAIT;
               read_cfi_cui = 1'b1;
            end
         else
            begin
               memory_next_state = `PAGEPSWAIT;
            end
       end
    `ESWRBUFSU:
       begin
               memory_next_state = `ESWRBUF;
               read_sr_int = 1'b1;
               wb_load_address_cui_int = 1'b1;
               peon_cui_int = 1'b1;
       end
    `ESWRBUF:
       begin
         if (cmdbus == `dcD0 && wb_end_load == 1'b1 && sr45_fail == 1'b0)
            begin
               memory_next_state = `ESPAGEPROG;
               read_sr_int = 1'b1;
               wb_program_cui = 1'b1;
            end
         else if (wb_end_load == 1'b0 && sr45_fail == 1'b0)
            begin
               memory_next_state = `ESWRBUF;
               read_sr_int = 1'b1;
               wb_load_data_cui_int = 1'b1;
            end
         else
            begin
               cmd_err = 1'b1;
               read_sr_int = 1'b1;
               memory_next_state = `ESWAIT;
            end
       end
    `ESPAGEPROG:
       begin
         if (cmdbus == `dcB0 && modify == 1'b1)
            begin
               memory_next_state = `ESPAGEPSWAIT;
               read_sr_int = 1'b1;
               wb_susp_cui = 1'b1;
            end
         else if (cmdbus == `dcE8 && addbus == `dcAA && modify == 1'b1 && sr45_fail == 1'b0)
            begin
               memory_next_state = `ESPAGEPROG;
               read_sr_int = 1'b1;
               wb_program_cui = 1'b1;
               holdsr7 = 1'b1;
            end
         else if (modify == 1'b1)
            begin
               memory_next_state = `ESPAGEPROG;
               read_sr_int = 1'b1;
               wb_program_cui = 1'b1;
            end
         else if (cmdbus == `dcE8 && addbus == `dcAA && sr45_fail == 1'b0)
            begin
               memory_next_state = `ESWRBUFSU;
               read_sr_int = 1'b1;
               wb_on_cui_int = 1'b1;
               // sr7 =1'b1;
            end
         else if (cmdbus == `dcD0)
            begin
               memory_next_state = `ERA;
               read_sr_int = 1'b1;
               erase_cui = 1'b1;
               ers_resume_int = 1'b1;
               peon_cui_int = 1'b1;
            end
         else if ((cmdbus == `dc40 || cmdbus == `dc10) && addbus == `dcAA)
            begin
               //memory_next_state = `ESPROGSU;
               memory_next_state = `PROGSU;
               read_sr_int = 1'b1;
               peon_cui_int = 1'b1;
            end
         else if (cmdbus == `dc50) // clear_sr_int_reg
            begin
               memory_next_state = `ESWAIT;
               clear_sr_int = 1'b1;
            end
         else if (cmdbus == `dc70) // read_sr_int
            begin
               memory_next_state = `ESWAIT;
               read_sr_int = 1'b1;
            end
         else if (cmdbus == `dc90) // read Elect Sig
            begin
               memory_next_state = `ESWAIT;
               read_es_cui = 1'b1;
            end
         else if (cmdbus == `dc98) // read Elect Sig
            begin
               memory_next_state = `ESWAIT;
               read_cfi_cui = 1'b1;
            end
         else
            begin
               memory_next_state = `ESWAIT;
            end
       end
    `ESPAGEPSWAIT:
       begin
         if (cmdbus == `dcFF && modify == 1'b0 && suspend == 1'b0)
            begin
               memory_next_state = `ESWAIT;
            end
         else if (suspend == 1'b0)
            begin
               memory_next_state = `ESPAGEPSWAIT;
               read_sr_int = 1'b1;
               wb_susp_cui = 1'b1;
            end
         else if (cmdbus == `dcD0)
            begin
               memory_next_state = `ESPAGEPROG;
               read_sr_int = 1'b1;
               wb_program_cui = 1'b1;
               wb_resume_int = 1'b1;
               peon_cui_int = 1'b1;
            end
         else if (cmdbus == `dc50) // clear_sr_int_reg
            begin
               memory_next_state = `ESPAGEPSWAIT;
               clear_sr_int = 1'b1;
            end
         else if (cmdbus == `dc70) // read_sr_int
            begin
               memory_next_state = `ESPAGEPSWAIT;
               read_sr_int = 1'b1;
            end
         else if (cmdbus == `dc90) // read Elect Sig
            begin
               memory_next_state = `ESPAGEPSWAIT;
               read_es_cui = 1'b1;
            end
         else if (cmdbus == `dc98) // read Elect Sig
            begin
               memory_next_state = `ESPAGEPSWAIT;
               read_cfi_cui = 1'b1;
            end
         else
            begin
               memory_next_state = `ESPAGEPSWAIT;
            end
       end
    `OPPROGSU:
       begin
         if (praddok == 1'b1)
            begin
               memory_next_state = `OPPROG;
               read_sr_int = 1'b1;
               otp_prog_cui = 1'b1;
            end
         else
            begin
               memory_next_state = `READARRAY;
               read_sr_int = 1'b1;
               cmd_err = 1'b1;
            end
       end
    `OPPROG:
       begin
         if (modify == 1'b1)
            begin
               memory_next_state = `OPPROG;
               read_sr_int = 1'b1;
            end
         else if (cmdbus == `dc20 && addbus == `dc55)
            begin
               memory_next_state = `ERASU;
               peon_cui_int = 1'b1;
            end
         else if (cmdbus == `dc80 && addbus == `dc55)
            begin
               memory_next_state = `BKERASU;
               peon_cui_int = 1'b1;
            end
         else if ((cmdbus == `dc40 || cmdbus == `dc10) && addbus == `dcAA)
            begin
               memory_next_state = `PROGSU;
               peon_cui_int = 1'b1;
            end
         else if (cmdbus == `dcE8 && addbus == `dcAA && sr45_fail == 1'b0)
            begin
               memory_next_state = `OPPROGSU;
               wb_on_cui_int = 1'b1;
               read_sr_int = 1'b1;
            end
         else if (cmdbus == `dc49 && addbus == `dcAA)
            begin
               memory_next_state = `OPPROGSU;
               peon_cui_int = 1'b1;
            end
         else if (cmdbus == `dc60)
            begin
               memory_next_state = `RCRLOCKSU;
               set_prot_reg_en_int = 1'b1;
            end
         else if (cmdbus == `dc50)
            begin
               memory_next_state = `READARRAY;
               clear_sr_int = 1'b1;
            end
         else if (cmdbus == `dc70)
            begin
               memory_next_state = `READARRAY;
               read_sr_int = 1'b1;
            end
         else if (cmdbus == `dc90)
            begin
               memory_next_state = `READARRAY;
               read_es_cui = 1'b1;
            end
         else if (cmdbus == `dc98)
            begin
               memory_next_state = `READARRAY;
               read_cfi_cui = 1'b1;
            end
         else
            begin
               memory_next_state = `READARRAY;
            end
       end
    default:
       begin
               memory_next_state = `READARRAY;
       end
   endcase
  end

endmodule
`timescale 1ns/1ns

module m58bw16f_decode (en_sect, add_micro);
`include "m58bw16f_functions.v"

output [`sect_number - 1:0] en_sect;
reg [`sect_number - 1:0] en_sect;
input [`AMAX - 1:0] add_micro;

integer i;

reg [31:0] index;
wire [31:0] index_main; //512Kbit
wire [31:0] index_bparam; //128kbit
wire [31:0] index_sparam;//64Kbit

assign index_main =  sect_index_main(add_micro[`AMAX - 1: 14]);
assign index_sparam =  sect_index_sparam(add_micro[13:11]);
assign index_bparam =  sect_index_bparam(add_micro[13:12]);

always@(index_main or index_bparam or index_sparam)
  begin
  if (index_main < 31)
       index = index_main;
else if ((index_main + index_sparam) <39)
    index = 31+ index_sparam;

  end

always@(index)
  begin
      for(i = 0; i < `sect_number; i = i + 1)
         begin
             en_sect = `sect_no_en;
             if (i == index)
                en_sect[i] = 1'b1;
         end
  end

endmodule
`timescale 1ns/1ns

module m58bw16f_dqpad_manager (dqpad, dqpad_sr, dqpad_cfi, dqpad_es, dqpad_r, read_es_cui, read_sr, read_cfi_cui, read_array_cui, E_, G_, GD_, burst_ready);


output [`DQMAX - 1:0] dqpad;
reg [`DQMAX - 1:0] dqpad;

input [`DQMAX - 1:0] dqpad_sr;
input [`DQMAX - 1:0] dqpad_cfi;
input [`DQMAX - 1:0] dqpad_es;
input [`DQMAX - 1:0] dqpad_r;
input read_es_cui;
input read_sr;
input read_cfi_cui;
input read_array_cui;
input E_;
input G_;
input GD_;
input burst_ready;

wire sr_latch;
reg [`DQMAX - 1:0] dqpad_sr_l;

wire [4:0] read_vect;
assign read_vect = {burst_ready, read_array_cui, read_es_cui, read_sr, read_cfi_cui};
assign sr_latch = ((E_ == 1'b1) || (G_ == 1'b1) || (GD_ == 1'b0)) ? 1'b1 : 1'b0;

always@(sr_latch or dqpad_sr)
  begin
    if (sr_latch == 1'b1)
       dqpad_sr_l = dqpad_sr;
  end

always@(read_vect or dqpad_sr_l or dqpad_cfi or dqpad_es or dqpad_r)
  begin
    case (read_vect)
      5'b01001: dqpad = dqpad_cfi;
      5'b01010: dqpad = dqpad_sr_l;
      5'b01100: dqpad = dqpad_es;
      5'b01000: dqpad = dqpad_r;
      5'b11001: dqpad = dqpad_cfi;
      5'b11010: dqpad = dqpad_sr_l;
      5'b11100: dqpad = dqpad_es;
      5'b11000: dqpad = dqpad_r;
      default: dqpad = `tristate_data;
    endcase
  end

endmodule

`timescale 1ns/1ns

module m58bw16f_erase_counter (count, end_op, reset_count, micro_clk, enable_count, first_sect);


output [31:0] count;
reg [31:0] count;
input end_op;
input reset_count;
input micro_clk;
input enable_count;
input [31:0] first_sect;

initial
   begin
     count = 0;
   end

//always@(posedge micro_clk or reset_count or enable_count)
always@(posedge micro_clk or reset_count)
  begin
      if (reset_count == 1'b1)
         count = first_sect;
      else if (enable_count == 1'b1)
         count = count + 1;
     end

endmodule
`timescale 1ns / 1ns

module m58bw16f_latch_control (data_mod, add_mod, burst_add, burst_ready, E_, burst_clock, L_, W_, A, DQ, reset_por, async_read_mcr);
//!module m58bw16f_latch_control (data_mod, add_mod, burst_add, burst_ready, E_, burst_clock, L_, W_, A_int, DQ, reset_por, async_read_mcr);

output [`DQMAX - 1:0] data_mod;
reg [`DQMAX - 1:0] data_mod;
output [`AMAX - 1:0] add_mod;
reg [`AMAX - 1:0] add_mod;
output [`AMAX - 1:0] burst_add;
reg [`AMAX - 1:0] burst_add;
output burst_ready;

input E_;
input burst_clock;
input L_;
input W_;
input [`AMAX - 1:0] A;
//!input [`AMAX - 1:0] A_int;
input [`DQMAX - 1:0] DQ;
input reset_por;
input async_read_mcr;

wire L;
wire wen;
wire E;
wire burst_ready_en;
reg burst_ready_K;

reg burst_reset;

assign L = (L_) ? 1'b0 : 1'b1;
assign E = (E_) ? 1'b0 : 1'b1;
assign wen = (W_ || E_) ? 1'b1 : 1'b0;

assign burst_ready = (burst_ready_en == 1'b1) ? 1'b1 : 1'b0;

assign burst_ready_en = (async_read_mcr== 1'b0) ? (((burst_ready_K == 1'b1) || (L_ == 1'b1)) && (E_ == 1'b0)) : ((L_ == 1'b1) && (E_ == 1'b0));

initial@(reset_por)
  begin
    burst_reset = 1'b1;
    burst_ready_K = 1'b0;
  end

always@(posedge L or E_)
      begin
        if (E_ == 1'b1)
           burst_reset = 1'b1;
        else
           begin
             #1 burst_reset = 1'b0;
             #2 burst_reset = 1'b1;
             #1 burst_reset = 1'b0;
           end
      end

always@(posedge burst_clock or burst_reset)
  begin
    if (burst_reset == 1'b1)
       burst_ready_K = 1'b0;
    else
       burst_ready_K = ~L;
  end

//always@(posedge burst_ready or burst_reset or A)
always@(posedge burst_ready or burst_reset)
  begin
    if (burst_reset == 1'b1)
       burst_add = `initial_address;
    else
     burst_add = A;
//!      burst_add = A_int;

  end

// Write Section
always@(posedge wen or reset_por)
  begin
    if (reset_por==1'b1)
      begin
        add_mod = `initial_address;
        data_mod = `initial_data;
      end
    else
      begin
      add_mod = A;

//!      add_mod = A_int;
        data_mod = DQ;
      end
  end

endmodule
`timescale 1ns/1ns

module m58bw16f_matrix(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, micro_pgm_pulse, micro_ers_pulse, read);


output fail_1su0;
output [`DQMAX - 1:0] dqpad_r;

input [`AMAX - 1:0] add_micro;
input [`AMAX - 1:0] add_read;
input [`DQMAX - 1:0] dqpad_p;
input micro_pgm_pulse;
input micro_ers_pulse;
input read;

reg [`DQMAX - 1:0] ARRAY [0:16383] ;
reg [`DQMAX - 1:0] ROW;
reg [`DQMAX - 1:0] RL_PROG;
//!reg [13:0] index;

//reg [31:0] sect_main_en;
reg [`sect_number - 1:0] sect_main_en;

integer i;


///////////////////////////////////////////////////////////

//wire [31:0] index_main;
reg [31:0] index_main;

reg [31:0] index_sparam;//64Kbit
//prova
reg [31:0] index;
//
always@(add_read) begin
index_main =sect_index_main(add_read[`AMAX - 1:14]);
 index_sparam =  sect_index_sparam(add_read[13:11]);
end

always@(add_micro) begin
index_main =sect_index_main(add_micro[`AMAX - 1:14]);
index_sparam =  sect_index_sparam(add_micro[13:11]);

end

always@(index_main or index_sparam) begin
  if (index_main < 31)
       index = index_main;
else if ((index_main + index_sparam) <39)
    index = 31+ index_sparam;
             sect_main_en = `sect_no_en;
                sect_main_en [index] = 1'b1;
  end


// Matrix Definitions


m58bw16f_512k_sector sect_0(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[0], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_1(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[1], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_2(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[2], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_3(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[3], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_4(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[4], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_5(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[5], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_6(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[6], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_7(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[7], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_8(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[8], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_9(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[9], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_10(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[10], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_11(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[11], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_12(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[12], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_13(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[13], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_14(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[14], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_15(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[15], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_16(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[16], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_17(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[17], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_18(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[18], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_19(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[19], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_20(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[20], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_21(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[21], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_22(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[22], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_23(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[23], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_24(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[24], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_25(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[25], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_26(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[26], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_27(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[27], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_28(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[28], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_29(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[29], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_512k_sector sect_30(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[30], micro_pgm_pulse, micro_ers_pulse, read);

m58bw16f_64k_sector sect_31(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[31], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_64k_sector sect_32(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[32], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_64k_sector sect_33(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[33], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_64k_sector sect_34(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[34], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_64k_sector sect_35(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[35], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_64k_sector sect_36(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[36], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_64k_sector sect_37(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[37], micro_pgm_pulse, micro_ers_pulse, read);
m58bw16f_64k_sector sect_38(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, sect_main_en[38], micro_pgm_pulse, micro_ers_pulse, read);


endmodule
`timescale 1ns/1ns

module m58bw16f_micro (wb_suspend, pgm_suspend, era_suspend, micro_pen_fail, micro_protect_fail, micro_otp_protect_fail, suspend, micro_otp_pulse, micro_wb_data, micro_wb_add, micro_dword, data_micro, add_micro, micro_ers_pulse, micro_pgm_pulse, modify, end_op, micro_osc, peon_cui, pgm_susp_cui, program_cui, erase_cui, otp_prog_cui, wb_program_cui, protect, otp_protect, reset_por, add_mod, data_mod, ers_susp_cui, erase_a_cui, n_final, wb_add_out, wb_data_out, PEN, cmd_err, era_resume_cui, pgm_resume_cui, wb_resume_cui, wb_susp_cui);

//

output [`DQMAX - 1:0] data_micro;
output [`AMAX - 1:0] add_micro;
output [`DQMAX - 1:0] micro_dword;
output micro_ers_pulse;
reg micro_ers_pulse;
output micro_pgm_pulse;
reg micro_pgm_pulse;
output micro_osc;
reg micro_osc;
output end_op;
reg end_op;
output modify;
reg modify;
output micro_wb_add;
reg micro_wb_add;
output micro_wb_data;
reg micro_wb_data;
output micro_otp_pulse;
reg micro_otp_pulse;
output suspend;
output micro_protect_fail;
reg micro_protect_fail;
output micro_otp_protect_fail;
reg micro_otp_protect_fail;
output micro_pen_fail;
reg micro_pen_fail;
output pgm_suspend;
reg pgm_suspend;
output era_suspend;
reg era_suspend;
output wb_suspend;
reg wb_suspend;

input peon_cui;
input pgm_susp_cui;
input program_cui;
input erase_cui;
input otp_prog_cui;
input wb_program_cui;
input protect;
input otp_protect;
input reset_por;
input [`AMAX - 1:0] add_mod;
input [`DQMAX - 1:0] data_mod;
input ers_susp_cui;
input erase_a_cui;
input [`DQMAX - 1:0] n_final;
input [`AMAX - 1:0] wb_add_out;
input [`DQMAX - 1:0]  wb_data_out;
input PEN;
input cmd_err;
input era_resume_cui;
input pgm_resume_cui;
input wb_resume_cui;
input wb_susp_cui;

wire [`DQMAX - 1:0] pgm_count;
wire [`DQMAX - 1:0] ers_count;
wire [`DQMAX - 1:0] sect_count;

reg reset_pgm_count;
reg reset_ers_count;
reg reset_sect_count;
reg reset_wb_count;

reg inc_sect;
reg inc_wb;

reg enable_pgm_count;
reg enable_ers_count;
reg enable_sect_count;
reg enable_wb_count;

reg micro_load_pgm_add;
reg micro_load_pgm_data;
reg micro_load_ers_add;
reg micro_erase_a_add_load;
reg micro_wb_load;

reg [7:0] micro_state;
reg [7:0] micro_next_state;

reg [`AMAX - 1:0] add_micro;
reg [`AMAX - 1:0] add_ers_susp;
reg [`AMAX - 1:0] add_pgm_susp;
reg [`AMAX - 1:0] add_wb_susp;
reg [`AMAX - 1:0] add_ers;
reg [`AMAX - 1:0] add_pgm;
reg [`DQMAX - 1:0] data_pgm;
reg [`DQMAX - 1:0] data_micro;
reg [`DQMAX - 1:0] data_pgm_susp;
reg [`DQMAX - 1:0] data_wb_susp;
reg [`DQMAX - 1:0] data_ers_susp;

wire last_wb_dword;
assign last_wb_dword = ((n_final - micro_dword + 1) == 0) ? 1'b1 : 1'b0;

wire last_sect;
assign last_sect = (sect_count == `last_main_sect) ? 1'b1 : 1'b0;

wire reset_seq;
assign reset_seq = ((end_op == 1'b1) || (reset_por == 1'b1)) ? 1'b1 : 1'b0;

wire [4:0] internal_op;
assign internal_op = {erase_cui, erase_a_cui, otp_prog_cui, program_cui, wb_program_cui};

reg [4:0] internal_op_l;

reg micro_latch_op;
reg micro_ers_susp_store;
reg micro_pgm_susp_store;
reg micro_wb_susp_store;
reg era_resume;
reg pgm_resume;
reg wb_resume;
reg micro_end_resume;
reg micro_end_pgm_resume;
reg micro_end_wb_resume;
reg micro_susp_ers_load_add;
reg micro_susp_pgm_load_add;
reg micro_susp_wb_load_add;
//time delayTime;
//time startTime;
//time delayTime_susp=0;

// ---------------
// ---------------

assign suspend = ((wb_suspend == 1'b1) || (pgm_suspend == 1'b1) || (era_suspend == 1'b1)) ? 1'b1 : 1'b0;

m58bw16f_counter pgm_counter(pgm_count, end_op, reset_pgm_count, micro_osc, enable_pgm_count);
m58bw16f_erase_counter ers_counter(ers_count, end_op, reset_ers_count, micro_osc, enable_ers_count, `first_main);
m58bw16f_counter sect_counter(sect_count, end_op, reset_sect_count, inc_sect, enable_sect_count);
m58bw16f_counter wb_counter(micro_dword, end_op, reset_wb_count, inc_wb, enable_wb_count);

always@(posedge micro_latch_op or reset_seq)
  begin
    if (reset_seq == 1'b1)
       internal_op_l = 5'b00000;
    else

       internal_op_l = internal_op;
  end

always@(micro_load_pgm_add or micro_load_ers_add or micro_erase_a_add_load or add_mod or modify or micro_wb_load or micro_susp_ers_load_add or micro_susp_pgm_load_add or add_pgm_susp or micro_susp_wb_load_add or add_wb_susp or add_ers_susp)
  begin
  //prova
    if (modify == 1'b0) begin
       add_micro = add_mod;

       end
    else if (micro_load_pgm_add == 1'b1) begin
       add_micro = add_pgm;
    end
    else if (micro_load_ers_add == 1'b1) begin
       add_micro = add_ers;
    end
    else if (micro_erase_a_add_load == 1'b1) begin
       add_micro = sect_count * `main_sect_size;
    end
    else if (micro_wb_load == 1'b1) begin
       add_micro = wb_add_out;
     end
    else if (micro_susp_ers_load_add == 1'b1)
       add_micro = add_ers_susp;
    else if (micro_susp_pgm_load_add == 1'b1)
       add_micro = add_pgm_susp;
    else if (micro_susp_wb_load_add == 1'b1)
       add_micro = add_wb_susp;
  end

always@(micro_load_pgm_data or micro_wb_load or micro_susp_pgm_load_add or data_pgm_susp or micro_susp_pgm_load_add or data_wb_susp or micro_susp_wb_load_add)
  begin
    if (micro_load_pgm_data == 1'b1)
       data_micro = data_pgm;
    else if (micro_wb_load == 1'b1) begin
       data_micro = wb_data_out;
       end
    else if (micro_susp_pgm_load_add == 1'b1)
       data_micro = data_ers_susp;
    else if (micro_susp_pgm_load_add == 1'b1)
       data_micro = data_pgm_susp;
    else if (micro_susp_wb_load_add == 1'b1)
       data_micro = data_wb_susp;
  end

always@(micro_ers_susp_store)
  begin
    if (micro_ers_susp_store == 1'b1)
       add_ers_susp = add_micro;
  end

always@(micro_pgm_susp_store)
  begin
    if (micro_pgm_susp_store == 1'b1)
       begin
          add_pgm_susp = add_micro;
          data_pgm_susp = data_micro;
       end
  end

always@(micro_wb_susp_store)
  begin
    if (micro_wb_susp_store == 1'b1)
       begin
          add_wb_susp = add_micro;
          data_wb_susp = data_micro;
       end
  end


always@(internal_op or reset_por or add_mod or data_mod)
  begin
    #1;
    if (reset_por == 1'b1)
       begin
         data_pgm = `initial_data;
         add_pgm = `initial_address;
         add_ers = `initial_address;
       end
    else
       case (internal_op)
          'b00001:
               begin
                 data_pgm = wb_data_out;
                 add_pgm = wb_add_out;
               end
          'b00010:
               begin
                 data_pgm = data_mod;
                 add_pgm = add_mod;
               end
          'b01000:
               begin
                 add_ers = add_mod;
               end
          'b10000:
               begin
                 add_ers = add_mod;

               end
          default:
               begin
                 data_pgm = `initial_data;
                 add_pgm = `initial_address;
                 add_ers = `initial_address;
               end
       endcase
  end

initial@(reset_por)
  begin
    if (reset_por == 1'b1)
       begin
          end_op = 1'b0;
          reset_pgm_count = 1'b0;
          reset_ers_count = 1'b0;
          reset_sect_count = 1'b0;
          reset_wb_count = 1'b0;
          inc_sect = 1'b0;
          inc_wb = 1'b0;
          enable_pgm_count = 1'b0;
          enable_ers_count = 1'b0;
          enable_sect_count = 1'b0;
          enable_wb_count = 1'b0;
          modify = 1'b0;
          micro_osc = 1'b0;
          micro_load_pgm_add = 1'b0;
          micro_load_pgm_data = 1'b0;
          micro_load_ers_add = 1'b0;
          micro_wb_add = 1'b0;
          micro_wb_data = 1'b0;
          micro_wb_load = 1'b0;
          micro_otp_pulse = 1'b0;
          pgm_suspend = 1'b0;
          era_suspend = 1'b0;
          wb_suspend = 1'b0;
          pgm_resume = 1'b0;
          era_resume = 1'b0;
          wb_resume = 1'b0;
          micro_protect_fail = 1'b0;
          micro_otp_protect_fail = 1'b0;
          micro_pen_fail = 1'b0;
          era_resume = 1'b0;
          micro_end_resume = 1'b0;
          micro_end_pgm_resume = 1'b0;
          micro_susp_pgm_load_add = 1'b0;
          micro_susp_wb_load_add = 1'b0;
          micro_wb_susp_store = 1'b0;
       end
  end

always@(peon_cui or end_op)
  begin
    #1;
    if (peon_cui == 1'b1) begin
       modify = 1'b1;


    end
    else if (end_op == 1'b1) begin
       modify = 1'b0;
    end
  end

//!prova
always
  wait(modify)
     begin
        #5 micro_osc = 1'b0;
        #50 micro_osc = 1'b1;
        #45 micro_osc = 1'b0;
     end

always@(posedge micro_osc or modify)
begin
      if (modify == 1'b0)
         begin
             micro_state = `micro_wait;
         end
      else
         begin
             micro_state = micro_next_state;
         end
  end

always@(pgm_susp_cui or pgm_resume_cui)
  begin
    if (pgm_susp_cui == 1'b1)
       pgm_suspend = 1'b1;
    else if (pgm_resume_cui == 1'b1)
       pgm_suspend = 1'b0;
  end

always@(ers_susp_cui or era_resume_cui)
  begin
    if (ers_susp_cui == 1'b1)
       era_suspend = 1'b1;
    else if (era_resume_cui == 1'b1)
       era_suspend = 1'b0;
  end

always@(wb_susp_cui or wb_resume_cui)
  begin
    if (wb_susp_cui == 1'b1)
       wb_suspend = 1'b1;
    else if (wb_resume_cui == 1'b1)
       wb_suspend = 1'b0;
  end

always@(micro_end_resume or era_resume_cui)
  begin
    if (micro_end_resume == 1'b1)
       era_resume = 1'b0;
    else if (era_resume_cui == 1'b1)
       era_resume = 1'b1;
  end

always@(micro_end_pgm_resume or pgm_resume_cui)
  begin
    if (micro_end_pgm_resume == 1'b1)
       pgm_resume = 1'b0;
    else if (pgm_resume_cui == 1'b1)
       pgm_resume = 1'b1;
  end

always@(micro_end_wb_resume or wb_resume_cui)
  begin
    if (micro_end_wb_resume == 1'b1)
       wb_resume = 1'b0;
    else if (wb_resume_cui == 1'b1)
       wb_resume = 1'b1;
  end

always@(sect_count or ers_count or micro_dword or pgm_count or micro_state or internal_op_l or PEN or cmd_err or wb_suspend or pgm_suspend or era_suspend or era_resume or wb_resume or pgm_resume)
   begin
      end_op = 1'b0;
      reset_pgm_count = 1'b0;
      reset_ers_count = 1'b0;
      reset_sect_count = 1'b0;
      reset_wb_count = 1'b0;
      inc_sect = 1'b0;
      inc_wb = 1'b0;
      enable_pgm_count = 1'b0;
      enable_ers_count = 1'b0;
      enable_sect_count = 1'b0;
      enable_wb_count = 1'b0;
      micro_load_pgm_add = 1'b0;
      micro_load_pgm_data = 1'b0;
      micro_load_ers_add = 1'b0;
      micro_pgm_pulse = 1'b0;
      micro_ers_pulse = 1'b0;
      micro_erase_a_add_load = 1'b0;
      micro_wb_add = 1'b0;
      micro_wb_data = 1'b0;
      micro_wb_load = 1'b0;
      micro_otp_pulse = 1'b0;
      micro_protect_fail = 1'b0;
      micro_otp_protect_fail = 1'b0;
      micro_pen_fail = 1'b0;
      micro_latch_op = 1'b0;
      micro_ers_susp_store = 1'b0;
      micro_pgm_susp_store = 1'b0;
      micro_wb_susp_store = 1'b0;
      micro_susp_pgm_load_add = 1'b0;
      micro_susp_ers_load_add = 1'b0;
      micro_susp_wb_load_add = 1'b0;
      micro_end_wb_resume = 1'b0;
      micro_end_resume = 1'b0;
      micro_end_pgm_resume = 1'b0;
      case(micro_state)
          `micro_wait:
             begin
                 if (PEN == 1'b1)
                    micro_next_state = `micro_op_latch;
                 else
                    micro_next_state = `micro_pen_error;
             end
          `micro_op_latch:
             begin
                 micro_latch_op = 1'b1;
                 if (internal_op == 5'b00000)
                    micro_next_state = `micro_wait;
                 else
                    micro_next_state = `micro_idle;
             end
          `micro_pen_error:
             begin
                 micro_next_state = `micro_end_op;
                 micro_pen_fail = 1'b1;
             end
          `micro_idle:
             begin
                 if (internal_op_l[1] == 1'b1)
                    micro_next_state = `micro_program_s;
                 else if (internal_op_l[4] == 1'b1)
                    micro_next_state = `micro_erase_s;
                 else if (internal_op_l[3] == 1'b1)
                    micro_next_state = `micro_erase_all;
                 else if (internal_op_l[2] == 1'b1)
                    micro_next_state = `micro_lotp;
                 else if (internal_op_l[0] == 1'b1)
                    micro_next_state = `micro_wb_prog;
                 else if (cmd_err == 1'b1)
                    micro_next_state = `micro_end_op;
                 else
                    micro_next_state = `micro_idle;
             end
//--------------
          `micro_program_s:
             begin
                 if (pgm_resume == 1'b1)
                    begin
                       micro_next_state = `micro_suspend_pgm_load_add;    //suspend branch
                    end
                 else
                    micro_next_state = `micro_reset_counter;
             end
          `micro_suspend_pgm_load_add:
             begin
                 micro_next_state = `micro_pgm_protection;
                 micro_susp_pgm_load_add = 1'b1;
                 micro_end_pgm_resume = 1'b1;
             end
          `micro_reset_counter:
             begin
                 micro_next_state = `micro_load_pgm_add;
                 reset_pgm_count = 1'b1;
             end
          `micro_load_pgm_add:
             begin
                 micro_next_state = `micro_load_pgm_data;
                 micro_load_pgm_add = 1'b1;
             end
          `micro_load_pgm_data:
             begin
                 micro_next_state = `micro_pgm_protection;
                 micro_load_pgm_data = 1'b1;
             end
          `micro_pgm_protection:
             begin
                 if (protect == 1'b1)
                    micro_next_state = `micro_protect_fail;
                 else if (otp_protect == 1'b1)
                    micro_next_state = `micro_otp_protect_fail;
                 else
                    micro_next_state = `micro_modify_pgm_sect;
             end
          `micro_modify_pgm_sect:
             begin

                 enable_pgm_count = 1'b1;

                 micro_next_state = `micro_wait_busy_pgm_end;
             end
          `micro_wait_busy_pgm_end:
             begin
                                  enable_pgm_count = 1'b1;
                  if (pgm_count >= (`tPROGDWORD-1000)/100)
                    begin
                       micro_next_state = `micro_program_pulse;

                    end
                 else  begin
                    micro_next_state = `micro_busy_pgm_end;
                    end
             end
          `micro_busy_pgm_end:
             begin
                 enable_pgm_count = 1'b1;

                 if (pgm_suspend == 1'b1)
                    begin
                       micro_next_state = `micro_pgm_susp_branch;    //suspend branch



                    end
                 else
                    micro_next_state = `micro_wait_busy_pgm_end;
             end
          `micro_program_pulse:
             begin
                 micro_pgm_pulse = 1'b1;
                 micro_next_state = `micro_end_op;
             end
//--------------
          `micro_protect_fail:
             begin
                 micro_next_state = `micro_end_op;
                 micro_protect_fail = 1'b1;
             end
//--------------
          `micro_otp_protect_fail:
             begin
                 micro_next_state = `micro_end_op;
                 micro_otp_protect_fail = 1'b1;
             end
//--------------
          `micro_erase_s:
             begin
                 if (era_resume == 1'b1)
                    begin

                       micro_next_state = `micro_suspend_ers_load_add;    //suspend branch

                   end
                 else
                    micro_next_state = `micro_reset_ers_counter;
             end
          `micro_suspend_ers_load_add:
             begin
                 micro_next_state = `micro_ers_protection;
                 micro_susp_ers_load_add = 1'b1;
                 micro_end_resume = 1'b1;
             end
          `micro_reset_ers_counter:
             begin
                 micro_next_state = `micro_load_ers_add;
                 reset_ers_count = 1'b1;
             end
          `micro_load_ers_add:
             begin
                 micro_next_state = `micro_ers_protection;
                 micro_load_ers_add = 1'b1;
             end
          `micro_ers_protection:
             begin
                 if (protect == 1'b1)
                    micro_next_state = `micro_protect_fail;
                 else if (otp_protect == 1'b1)
                    micro_next_state = `micro_otp_protect_fail;
                 else
                    micro_next_state = `micro_modify_ers_sect;
             end
          `micro_modify_ers_sect:
             begin
                 enable_ers_count = 1'b1;
                 micro_next_state = `micro_wait_busy_ers_end;
             end
          `micro_wait_busy_ers_end:
             begin
                 enable_ers_count = 1'b1;

                 if (2*ers_count+9 >= `tERASESECT/100)
                    begin

                        micro_next_state = `micro_erase_pulse;
                    end
                 else
                    begin

                       micro_next_state = `micro_busy_ers_end;
                    end
             end
          `micro_busy_ers_end:
             begin
                enable_ers_count = 1'b1;
                 if (era_suspend == 1'b1) begin
                       micro_next_state = `micro_era_susp_branch;    //suspend branch
                 end
                 else
                    micro_next_state = `micro_wait_busy_ers_end;

             end
          `micro_erase_pulse:
             begin
                 micro_ers_pulse = 1'b1;
                 micro_next_state = `micro_end_op;
             end
//--------------
          `micro_erase_all:
             begin
                 micro_next_state = `micro_erase_a_reset;
                 reset_sect_count = 1'b1;
             end
          `micro_erase_a_reset:
             begin
                 reset_ers_count = 1'b1;
                 micro_next_state = `micro_erase_a_load_add;
             end
          `micro_erase_a_load_add:
             begin
                 micro_next_state = `micro_erase_a_last_add;
                 micro_erase_a_add_load = 1'b1;
             end
          `micro_erase_a_last_add:
             begin
                 if (last_sect == 1'b0)
                     micro_next_state = `micro_erase_a_prot_check;
                 else
                     micro_next_state = `micro_end_op;
             end
          `micro_erase_a_prot_check:
             begin
                 if (protect == 1'b1)
                    micro_next_state = `micro_erase_a_protect_fail;
                 else if (otp_protect == 1'b1)
                    micro_next_state = `micro_erase_a_otp_protect_fail;
                 else
                    micro_next_state = `micro_erase_a_modify_sect;
             end
          `micro_erase_a_protect_fail:
             begin
                 micro_next_state = `micro_erase_a_rst_inc_sect;
                 micro_protect_fail = 1'b1;
             end
          `micro_erase_a_otp_protect_fail:
             begin
                 micro_next_state = `micro_erase_a_rst_inc_sect;
                 micro_otp_protect_fail = 1'b1;
             end
          `micro_erase_a_modify_sect:
             begin
                 enable_ers_count = 1'b1;
                 micro_next_state = `micro_erase_a_wait_busy_end;
             end
          `micro_erase_a_wait_busy_end:
             begin
                 enable_ers_count = 1'b1;
                 if (ers_count >= (`tERASESECT-800-3*(`last_main_sect+1)*100)/100)
                    begin
                       micro_next_state = `micro_erase_a_pulse;
                   end
                 else
                    begin
                      micro_next_state = `micro_erase_a_busy_end;
                   end
             end
          `micro_erase_a_busy_end:
             begin
                 enable_ers_count = 1'b1;
                 micro_next_state = `micro_erase_a_wait_busy_end;
             end
          `micro_erase_a_pulse:
             begin
                 micro_ers_pulse = 1'b1;
                 micro_next_state = `micro_erase_a_rst_inc_sect;
             end
          `micro_erase_a_rst_inc_sect:
             begin
                 micro_next_state = `micro_erase_a_inc_add;
                 enable_sect_count = 1'b1;
             end
          `micro_erase_a_inc_add:
             begin //prova mia
                 if(sect_count<`last_main_sect)
                 begin
                 inc_sect = 1'b1;
                 enable_sect_count = 1'b1;
                 micro_erase_a_add_load = 1'b1;
                 micro_next_state = `micro_erase_a_pulse;
                end
                 else begin
                 micro_ers_pulse= 1'b1;
                 micro_erase_a_add_load = 1'b1;
                 micro_next_state = `micro_erase_a_reset;
                 end
             end
//-------------
          `micro_lotp:
             begin
                 micro_next_state = `micro_lock_pulse;
                 reset_pgm_count = 1'b1;
             end
          `micro_lock_pulse:
             begin
                 micro_next_state = `micro_wait_end;
                 enable_pgm_count = 1'b1;
             end
          `micro_wait_end:
             begin
                 enable_pgm_count = 1'b1;
                 if (pgm_count >= (`tPROGDWORD-1000)/100)
                    micro_next_state = `micro_otp_pgm_pulse;
                 else
                    micro_next_state = `micro_wait_end;
             end
          `micro_otp_pgm_pulse:
             begin
                 micro_otp_pulse = 1'b1;
                 micro_next_state = `micro_end_op;
             end
//--------------
          `micro_wb_prog:
             begin
                 if (wb_resume == 1'b1)
                    begin
                       micro_next_state = `micro_suspend_wb_load_add;    //suspend branch
                    end
                 else
                    micro_next_state = `micro_wb_reset;

             end
          `micro_suspend_wb_load_add:
             begin
                 micro_next_state = `micro_wb_prot_check;
                 micro_susp_wb_load_add = 1'b1;
                 micro_end_wb_resume = 1'b1;
             end
          `micro_wb_reset:
             begin
                 micro_next_state = `micro_wb_last_add;
                 reset_wb_count = 1'b1;
             end
          `micro_wb_last_add:
             begin
                 reset_pgm_count = 1'b1;
                 if (last_wb_dword == 1'b0)
                    micro_next_state = `micro_wb_load_add;
                 else
                    micro_next_state = `micro_end_op;
             end
          `micro_wb_load_add:
             begin
                 micro_next_state = `micro_wb_load_data;
                 micro_wb_add = 1'b1;
             end
          `micro_wb_load_data:
             begin
                 micro_next_state = `micro_wb_load_address;
                 micro_wb_data = 1'b1;
             end
          `micro_wb_load_address:
             begin
                 micro_next_state = `micro_wb_prot_check;
                 micro_wb_load = 1'b1;
             end
          `micro_wb_prot_check:
             begin
                 if (protect == 1'b1)
                    micro_next_state = `micro_wb_prot_fail;
                 else if (otp_protect == 1'b1)
                    micro_next_state = `micro_wb_otp_fail;
                 else
                    micro_next_state = `micro_modify_wb;
             end
          `micro_wb_prot_fail:
             begin
                 enable_wb_count = 1'b1;
                 inc_wb = 1'b1;
                 micro_protect_fail = 1'b1;
                 micro_next_state = `micro_wb_last_add;
             end
          `micro_wb_otp_fail:
             begin
                 enable_wb_count = 1'b1;
                 inc_wb = 1'b1;
                 micro_otp_protect_fail = 1'b1;
                 micro_next_state = `micro_wb_last_add;
             end
          `micro_modify_wb:
             begin
                 enable_pgm_count = 1'b1;
                 micro_next_state = `micro_wait_busy_wb_end;
             end
          `micro_wait_busy_wb_end:
             begin
                 enable_pgm_count = 1'b1;
                  if (pgm_count >= (`tPROGDWORD-1000)/100) begin
                    micro_next_state = `micro_wb_pulse;
                    end
                 else
                    micro_next_state = `micro_busy_wb_end;
             end
          `micro_busy_wb_end:
             begin
                 enable_pgm_count = 1'b1;
                 if (wb_suspend == 1'b1)
                    begin
                       micro_next_state = `micro_wb_susp_branch;    //suspend branch
                    end
                 else
                 micro_next_state = `micro_wait_busy_wb_end;
             end
          `micro_wb_pulse:
             begin
                 enable_wb_count = 1'b1;
                 micro_pgm_pulse = 1'b1;
                 micro_next_state = `micro_wb_inc;
             end
          `micro_wb_inc:
             begin
                 enable_wb_count = 1'b1;
                 inc_wb = 1'b1;
                 micro_next_state = `micro_wb_last_add;
             end
//--------------
          `micro_era_susp_branch:
             begin
                 micro_ers_susp_store = 1'b1;
                 micro_next_state = `micro_end_op;
             end
          `micro_pgm_susp_branch:
             begin
                 micro_pgm_susp_store = 1'b1;
                 micro_next_state = `micro_end_op;
             end
          `micro_wb_susp_branch:
             begin
                 micro_wb_susp_store = 1'b1;
                 micro_next_state = `micro_end_op;
             end
//--------------
          `micro_end_op:
             begin
                 micro_next_state = `micro_exit;
             end
          `micro_exit:
             begin
                 micro_next_state = `micro_wait;
                 end_op = 1'b1;
             end

          default:
             micro_next_state = `micro_wait;
      endcase
   end

endmodule
`timescale 1ns/1ns

module m58bw16f_otp_register (otp_protect, add_micro, micro_otp_pulse, reset_por);


output otp_protect;

input [`AMAX - 1:0] add_micro;
input micro_otp_pulse;
input reset_por;

reg [`sect_number - 1:0] otp_sect;

reg [31:0] index;
wire [31:0] index_main;
wire [31:0] index_bparam;
wire [31:0] index_sparam;
assign index_main =  sect_index_main(add_micro[`AMAX - 1: 14]);
assign index_sparam =  sect_index_sparam(add_micro[13:11]);
assign index_bparam =  sect_index_bparam(add_micro[13:12]);

always@(posedge micro_otp_pulse or reset_por)
  begin
    #1;
    if (reset_por == 1'b1)
       otp_sect = `initial_otp_data;
    else if (micro_otp_pulse == 1'b1)
       begin
          otp_sect[`otp_sect_1] = 1'b1;
          otp_sect[`otp_sect_2] = 1'b1;
       end
  end

always@(index_main or index_bparam or index_sparam)
  begin
//!    if (index_main < 62)
if (index_main < 31)
       index = index_main;
//!    else if ((index_main + index_sparam) < 70)
//!       index = 62 + index_sparam;
//!    else
//!       index = 70 + index_bparam;
else if ((index_main + index_sparam) <39)
    index = 31+ index_sparam;


  end

assign otp_protect = otp_sect[index];

endmodule

`timescale 1ns / 1ns

module m58bw16f_por_logic (reset_por, VDD, VDDQIN, VDDQ, RP_);


output reset_por;
reg reset_por;

input RP_;
input VDD;
input VDDQ;
input VDDQIN;

wire vddok;

assign vddok = (VDD && VDDQ && VDDQIN) ? 1'b1 : 1'b0;

always@(RP_ or vddok)
  begin
    #1;
    if (vddok == 1'b0)
       begin
           reset_por = 1'b1;
       end
    else if (RP_ == 1'b0)
       begin
           reset_por = 1'b1;
       end
    else if (RP_ == 1'b1)
       begin
           reset_por = 1'b0;
       end
  end


endmodule
`timescale 1ns/1ns

module m58bw16f_prot_register (protect_sect, protect, add_micro, set_prot_reg, clear_prot_reg, set_prot_reg_en, PEN, WP_, RP_, reset_por);


input [`AMAX - 1:0] add_micro;
input set_prot_reg;
input clear_prot_reg;
input set_prot_reg_en;
input PEN;
input WP_;
input RP_;
input reset_por;

output protect;
output [`sect_number - 1:0] protect_sect;
reg [`sect_number - 1:0] protect_sect;


wire enable_protection;
wire wp_asserted;

integer i;

reg [31:0] index;

// address decoding
integer main;
integer bpar;
integer spar;

always@(add_micro[`AMAX - 1:0])
   begin
   #0;
    main = add_micro[`AMAX - 1:14];
    bpar = add_micro[13:12];
    spar = add_micro[13:11];

   end

always@(main or spar or bpar or reset_por)
  begin
    if (reset_por == 1'b1)
       index = 0;
    else
       begin
          if (main == 31)
               index =31 + spar;
          else
               index = main;
       end
  end

//

always@(reset_por)
  begin
    protect_sect = `initial_prot_data;
  end

always@(clear_prot_reg or set_prot_reg or set_prot_reg_en)
  begin
    #1;
    if ((clear_prot_reg == 1'b1) && (set_prot_reg_en == 1'b1)) begin
       protect_sect[index] = 1'b0;
   end
    else if ((set_prot_reg == 1'b1) && (set_prot_reg_en == 1'b1)) begin
       protect_sect[index] = 1'b1;
   end
  end

assign enable_protection = ((RP_ == 1'b0) || (PEN == 1'b0)) ? 1'b1 : 1'b0;
assign wp_asserted = (WP_ == 1'b0) ? 1'b1 : 1'b0;

assign protect = (enable_protection) ? 1'b0 : ((wp_asserted) ? 1'b1 : protect_sect[index]);

endmodule

`timescale 1ns/1ns

module m58bw16f_read_es_mod (dqpad_es, add_mod, protect_sect, read_es_cui, bcr_data, reset_por);


output [`DQMAX - 1:0] dqpad_es;
reg [`DQMAX - 1:0] dqpad_es;

input [`AMAX - 1:0] add_mod;
input [`bcr_size - 1:0] bcr_data;
input [`sect_number - 1:0] protect_sect;
input reset_por;
input read_es_cui;

reg [31:0] index;
reg [31:0] dqpad_bcr;

wire bcrok;
assign bcrok = (add_mod[`AMAX - 1:0] == 5) ? 1'b1 : 1'b0;
wire prhaddok;
assign prhaddok = (add_mod[10:2] == 0) ? 1'b1 : 1'b0;
wire praddok;
assign praddok = (add_mod[1:0] == 2) ? 1'b1 : 1'b0;
wire idok;
assign idok = (add_mod[`AMAX - 1:0] == 1) ? 1'b1 : 1'b0;
wire mfgok;
assign mfgok = (add_mod[`AMAX - 1:0] == 0) ? 1'b1 : 1'b0;
wire [4:0] es_array;
assign es_array = {read_es_cui, (praddok && prhaddok), bcrok, mfgok, idok};


wire [`DQMAX - 1:0] idcode;
assign idcode = (`top == 1'b1) ? (`idcode_top) : (`idcode_bottom);

reg [`DQMAX - 1:0] dqpad_pr;
wire protect_bit;
assign protect_bit = protect_sect[index];

// address decoding
integer main;
integer bpar;
integer spar;

always@(add_mod[`AMAX - 1:0])
   begin
    main = add_mod[`AMAX - 1:14];
    bpar = add_mod[13:12];
    spar = add_mod[13:11];
   end
//

always@(index or add_mod)
  begin
    dqpad_pr = 32'h00000000;
    #2;
    dqpad_pr[0] = protect_sect[index];
  end

always@(bcr_data)
  begin
    dqpad_bcr = 32'h00000000;
    #2;
    dqpad_bcr[15:0] = bcr_data;
  end

always@(main or spar or bpar or praddok or reset_por)
  begin
    if (reset_por == 1'b1)
       index = 0;
    else if (praddok == 1'b1)
    begin
//!          if (main == 63)
//!               index = 70 + bpar;
//!          else if (main == 62)
//!               index = 62 + spar;
//!          else
//!               index = main;
            if (main == 31)
               index =31 + spar;
          else
               index = main;
    end
  end

always@(es_array or reset_por or dqpad_bcr or dqpad_pr)
  begin
    if (reset_por == 1'b1)
       dqpad_es = `initial_data;
    else
       case (es_array)
           5'b10001: dqpad_es = idcode;
           5'b10010: dqpad_es = 32'h00000020;
           5'b10100: dqpad_es = dqpad_bcr;
           5'b11000: dqpad_es = dqpad_pr;
           default: dqpad_es =`tristate_data;
       endcase
  end

endmodule
`timescale 1ns/1ns

module m58bw16f_status_reg (dqpad_sr, modify, suspend, micro_protect_fail, micro_otp_protect_fail, micro_pen_fail, reset_por, clear_sr_cui, fail_1su0, wb_err, micro_pen_fail, fail_1su0, pgm_suspend, era_suspend, holdsr7);


output [`DQMAX - 1:0] dqpad_sr;

input modify;
input suspend;
input micro_protect_fail;
input micro_otp_protect_fail;
input micro_pen_fail;
input wb_err;
input reset_por;
input clear_sr_cui;
input fail_1su0;
input pgm_suspend;
input era_suspend;
input holdsr7;

wire protect;

wire sr_7;
wire sr_6;
wire sr_2;
wire sr_0;
reg sr_5;
reg sr_4;
reg sr_3;
reg sr_1;

assign dqpad_sr = {sr_7, sr_6, sr_5, sr_4, sr_3, sr_2, sr_1, sr_0};

assign protect = ((micro_protect_fail == 1'b1) || (micro_otp_protect_fail == 1'b1)) ? 1'b1 : 1'b0;

assign sr_7 = ((modify == 1'b1) || (holdsr7 == 1'b1)) ? 1'b0 : 1'b1;
assign sr_6 = (era_suspend) ? 1'b1 : 1'b0;
assign sr_2 = (pgm_suspend) ? 1'b1 : 1'b0;
assign sr_0 = (modify) ? 1'b1 : 1'b1;

always@(protect or clear_sr_cui or reset_por)
  begin
    #1;
    if (reset_por == 1'b1)
       sr_1 = 1'b0;
    else if (protect == 1'b1)
       sr_1 = 1'b1;
    else if (clear_sr_cui == 1'b1)
       sr_1 = 1'b0;
  end

always@(micro_pen_fail or clear_sr_cui or reset_por)
  begin
    #1;
    if (reset_por == 1'b1)
       sr_3 = 1'b0;
    else if (micro_pen_fail == 1'b1)
       sr_3 = 1'b1;
    else if (clear_sr_cui == 1'b1)
       sr_3 = 1'b0;
  end

always@(fail_1su0 or clear_sr_cui or reset_por or wb_err)
  begin
    #1;
    if (reset_por == 1'b1)
       sr_4 = 1'b0;
    else if ((fail_1su0 == 1'b1) || (wb_err == 1'b1))
       sr_4 = 1'b1;
    else if (clear_sr_cui == 1'b1)
       sr_4 = 1'b0;
  end

always@(wb_err or clear_sr_cui or reset_por)
  begin
    #1;
    if (reset_por == 1'b1)
       sr_5 = 1'b0;
    else if (wb_err == 1'b1)
       sr_5 = 1'b1;
    else if (clear_sr_cui == 1'b1)
       sr_5 = 1'b0;
  end

// sr_5 is Erase Status and it is equal to '1'
// when:
// Erase is not successfully ended
// wb out of range
// Deleted by Clear_Status_Reg

// sr_4 is Program Status and it is equal to '1'
// when:
// Program Fail
// Write to Buffer and Program Fail
// wb out of range
// Deleted by Clear_Status_Reg

// sr_3 is PEN Status and it is equal to '1'
// when:
// PEN is equal to '0'
// Deleted by Clear_Status_Reg

// sr_2 is Suspend Status
// when:
// Suspend System
// Cleared:
// Resume

// sr_1 is Block Protection
// when:
// a modify Operation is done on a locked block
// Cleared:
// Deleted by Clear_Status_Reg

endmodule

`timescale 1ns / 1ns

// STMicroelectronics
// Flash Memory Model draft release
// All the rights are reserved
// for any issue or support, please contact:
// alberto.troia@st.com

// rev 1.0 vs draft release: fixed page mode behavioural(x4/x8)
// rev 1.0 vs draft release: enabled R valid edge configuration bit
// rev 1.0 vs draft release: tested and fixed the nested suspend/resume function
// rev 1.0 vs draft release: wrap mode alligned to the datasheet

module m58bw16f_top (R, DQ, A, E_, K, PEN, L_, RP_, G_, GD_, W_, WP_, B_, VDD, VDDQ, VDDQIN, VSS, VSSQ);


input [`AMAX - 1:0] A;
input E_;
input K;
input PEN;
input L_;
input RP_;
input G_;
input GD_;
input W_;
input WP_;
input B_;

input VDD;
input VDDQ;
input VDDQIN;
input VSS;
input VSSQ;

inout [`DQMAX - 1:0] DQ;

output R;

//--------------
wire [`AMAX - 1:0] add_mod;
wire [`AMAX - 1:0] add_read;
wire [`AMAX - 1:0] wb_add_out;
wire [`AMAX - 1:0] A_int;
wire [`DQMAX - 1:0] data_mod;
wire [`DQMAX - 1:0] dqpad_r;
wire [`DQMAX - 1:0] dqpad_p;
wire [`DQMAX - 1:0] data_micro;
wire [`DQMAX - 1:0] micro_dword;
wire [`DQMAX - 1:0] n_final;
wire [`DQMAX - 1:0] wb_data_out;
wire [`DQMAX - 1:0] dqpad_sr;
wire [`DQMAX - 1:0] dqpad_es;
wire [`DQMAX - 1:0] dqpad_cfi;
wire [`DQMAX - 1:0] dqpad;
wire [`sect_number - 1:0] protect_sect;
//aggiunta
wire [`sect_number - 1:0] en_sect;
wire [15:0] bcr_data;
wire [2:0] latency_mcr;
wire [2:0] burst_length_mcr;
wire [`AMAX - 1:0] burst_add;
wire read;
wire burst_ready;
wire async_read_mcr;
assign read = (async_read_mcr == 1'b1) ? 1'b1 : burst_ready;
wire sr_reg5;
assign sr_reg5 = dqpad_sr[5];
wire sr_reg4;
assign sr_reg4 = dqpad_sr[4];
wire output_enable = ((G_ == 1'b0) && (GD_== 1'b1) && (E_ == 1'b0)) ? 1'b1 : 1'b0;
//--------------
assign DQ = (output_enable == 1'b1) ? dqpad : `tristate_data;
//prova
assign  dqpad_p = data_micro;

wire [`AMAX - 1:0] add_micro;
wire protect;

m58bw16f_por_logic por_logic(reset_por, VDD, VDDQIN, VDDQ, RP_);

m58bw16f_prot_register prot_reg(protect_sect, protect, add_micro, set_prot_reg, clear_prot_reg, set_prot_reg_en, PEN, WP_, RP_, reset_por);

m58bw16f_otp_register otp (otp_protect, add_micro, micro_otp_pulse, reset_por);

m58bw16f_micro micro (wb_suspend, pgm_suspend, era_suspend, micro_pen_fail, micro_protect_fail, micro_otp_protect_fail, suspend, micro_otp_pulse, micro_wb_data, micro_wb_add, micro_dword, data_micro, add_micro, micro_ers_pulse, micro_pgm_pulse, modify, end_op, micro_osc, peon_cui, pgm_susp_cui, program_cui, erase_cui, otp_prog_cui, wb_program_cui, protect, otp_protect, reset_por, add_mod, data_mod, ers_susp_cui, erase_a_cui, n_final, wb_add_out, wb_data_out, PEN, cmd_err, era_resume_cui, pgm_resume_cui, wb_resume_cui, wb_susp_cui);

m58bw16f_matrix matrix(fail_1su0, dqpad_r, add_micro, add_read, dqpad_p, micro_pgm_pulse, micro_ers_pulse, read);

m58bw16f_cui cui (holdsr7, wb_susp_cui, pgm_susp_cui, ers_susp_cui, read_array_cui, read_es_cui, read_cfi_cui, cmd_err, peon_cui, otp_prog_cui, erase_a_cui, program_cui, erase_cui, set_prot_reg_en, wb_resume_cui, era_resume_cui, pgm_resume_cui, set_bcr_reg, wb_program_cui, wb_load_address_cui, wb_load_data_cui, wb_on_cui, set_prot_reg, clear_prot_reg, clear_sr_cui, read_sr, DQ, A, W_, E_, RP_, sr_reg5, sr_reg4, wb_end_load, modify, suspend, reset_por);

m58bw16f_wb_logic wb_logic (wb_err, n_final, wb_add_out, wb_data_out, wb_end_load, data_mod, add_mod, wb_on_cui, wb_load_address_cui, wb_load_data_cui, reset_por, micro_dword, micro_wb_add, micro_wb_data, end_op);

m58bw16f_status_reg status_reg (dqpad_sr, modify, suspend, micro_protect_fail, micro_otp_protect_fail, micro_pen_fail, reset_por, clear_sr_cui, fail_1su0, wb_err, micro_pen_fail, fail_1su0, pgm_suspend, era_suspend, holdsr7);

m58bw16f_burst_conf_register conf_register(async_read_mcr, latency_mcr, ylatency_mcr, valid_R_mcr, valid_Kedge_mcr, wrap_mcr, burst_length_mcr, bcr_data, add_mod, set_bcr_reg, RP_);

m58bw16f_read_es_mod read_es_mod(dqpad_es, add_read, protect_sect, read_es_cui, bcr_data, reset_por);

m58bw16f_cfi_sector cfi_sector(dqpad_cfi, add_read, read_cfi_cui);

m58bw16f_burst_control burst_control(R, add_read, burst_clock, burst_add, burst_ready, B_, valid_Kedge_mcr, K, L_, latency_mcr, burst_length_mcr, ylatency_mcr, async_read_mcr, reset_por, valid_R_mcr);

m58bw16f_latch_control latch_control (data_mod, add_mod, burst_add, burst_ready, E_, burst_clock, L_, W_, A_int, DQ, reset_por, async_read_mcr);

m58bw16f_dqpad_manager dqpad_manager(dqpad, dqpad_sr, dqpad_cfi, dqpad_es, dqpad_r, read_es_cui, read_sr, read_cfi_cui, read_array_cui, E_, G_, GD_, burst_ready);

m58bw16f_add_control add_control (A_int, A);



//!m58bw16f_decode decode(en_sect, add_micro);

endmodule
`timescale 1ns / 1ns

module m58bw16f_wb_logic (wb_err, max_dword, wb_add_out, wb_data_out, wb_end_load, data_in, add_mod, wb_on_cui, wb_load_address_cui, wb_load_data_cui, reset_por, micro_dword, micro_wb_add, micro_wb_data, end_op);


output [`DQMAX - 1:0]  max_dword;
reg [`DQMAX - 1:0]  max_dword;
output [`AMAX - 1:0] wb_add_out;
reg [`AMAX - 1:0] wb_add_out;
output [`DQMAX - 1:0] wb_data_out;
reg [`DQMAX - 1:0] wb_data_out;
output wb_end_load;
output wb_err;
reg wb_err;

input [`AMAX - 1:0] add_mod;
input [`DQMAX - 1:0] data_in;

input wb_on_cui;
input wb_load_address_cui;
input wb_load_data_cui;
input reset_por;
input [`DQMAX - 1:0] micro_dword;
input micro_wb_add;
input micro_wb_data;
input end_op;

reg wb_load_data_en;
wire [`DQMAX - 1:0] n_count;

reg [`AMAX - 1:0] bank_address;

reg [`DQMAX - 1:0] data_buffer [0:`Write_Buffer_Size - 1];
reg [`AMAX - 1:0] add_buffer [0:`Write_Buffer_Size - 1];
reg [`AMAX - 1:0] index;
reg [`DQMAX - 1:0] data_tmp;
reg [`AMAX - 1:0] add_tmp;

assign wb_end_load = (max_dword == (n_count - 2)) ? 1'b1 : 1'b0;
wire counter_reset;
assign counter_reset = end_op || wb_load_address_cui;
wire inc_count;
assign inc_count = (wb_load_data_cui) ? 1'b1 : 1'b0;

m58bw16f_counter wb_upload(n_count, end_op, counter_reset, inc_count, wb_load_data_en);

initial
   begin
     bank_address = `initial_address;
     wb_err = 1'b0;
   end


always@(posedge wb_load_address_cui or reset_por)
  begin
    if (reset_por == 1'b1)
       begin
          max_dword = 0;
          bank_address = `initial_address;
       end
    else if (wb_load_address_cui == 1'b1)
       begin
          max_dword = data_in;
          bank_address = add_mod;
       end
  end

always@(negedge wb_load_data_cui or wb_end_load or reset_por)
  begin
    #1;
    if (reset_por == 1'b1)
       wb_load_data_en = 1'b0;
    else
      if (wb_end_load == 1'b0)
         wb_load_data_en = 1'b1;
      else
         wb_load_data_en = 1'b0;
  end

always@(posedge wb_load_data_cui)
  begin
    data_buffer[n_count - 1] = data_in;
    add_buffer[n_count - 1] = add_mod;
  end

// Upload to Micro

always@(micro_wb_add or micro_dword)
  begin
     #1;
     if (micro_wb_add == 1'b1)
        begin

        wb_add_out = add_buffer[micro_dword];
        end
  end

always@(micro_wb_add or micro_dword)
  begin
     #1;
     if (micro_wb_add == 1'b1)
        begin
        wb_data_out = data_buffer[micro_dword];
        end
  end


// Error Checking

always@(negedge wb_load_data_cui or end_op)
   begin
     add_tmp = add_buffer[n_count - 2];
     #5;
     if (end_op == 1'b1)
        wb_err = 1'b0;
     else if ((0 <= add_tmp[18:14] <= 61) && (wb_load_data_cui == 1'b0))
        begin
          if (add_tmp[18:14] == bank_address[18:14])
             wb_err = 1'b0;
          else
             wb_err = 1'b1;
        end
     else if ((add_tmp[18:14] == 63) && (wb_load_data_cui == 1'b0))
        begin
          if ((add_tmp[13:11] == bank_address[13:11]))
             wb_err = 1'b0;
          else
             wb_err = 1'b1;
        end
     else if ((add_tmp[18:14] == 64) && (wb_load_data_cui == 1'b0))
        begin
          if ((add_tmp[13:12] == bank_address[13:12]))
             wb_err = 1'b0;
          else
             wb_err = 1'b1;
        end
   end

endmodule
