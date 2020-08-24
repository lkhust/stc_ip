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
//
//
`define DQMAX 32
`define AMAX  19
`define sr_size 8
`define Write_Buffer_Size 32
`define top 1'b1
`define MCR_default 16'h8000
`define SR_default 8'h81
`define ADD_Erase 8'h55
`define ADD_Pgm 8'hAA
`define Cmd_Size 8
`define SR_Size 8
`define nr_main_blocks 31
`define step_add 128;
`define half_clk_int 1
`define boundary 6'b100000

`define MAIN_SECT 512
//`define PARAG_SECT 128
//`define PARAP_SECT 180
`define tPROG_DWORD 15
`define sector_size 16384
`define tSUSPEND 20
`define tPROTEXIT 8
`define tLLKH 5
`define tAVQV 40
`define tKHQV 8
`define tELWL 5
`define tWLWH 20
`define tWHWL 20
`define tACC 40
`define tLHLL 10
`define tLLLH 10

`define tERASE_MAIN_SECT 1000000000
`define tERASE_PARAG_SECT 800000000
`define tERASE_PARAP_SECT 600000000


`define m58bw16f 1'b1
//!`define sect_number 74
`define sect_number 39
`define bcr_size 16
`define initial_address 20'h00000
`define tristate_address 20'hzzzzz
`define initial_prot_data 39'b1
`define clear_prot_data 39'h0000000000000000000
`define bcr_data_init 16'h8040
`define initial_data 32'h00000000
`define tristate_data 32'hzzzzzzzz
`define tristate_add 20'hzzzzz
`define init_all_ers_sect 20'h00000
`define modify_end_const 39'h000000000000000
`define sector_busy_const 39'h000000000000000
`define suspend_sect_const 39'h000000000000000
`define fail_1su0_const 39'h000000000000000
`define modify_pulse_const 39'h000000000000000
`define OTP_Init 39'h000000000000000
`define prg_no_susp 39'h000000000000000
`define ers_no_susp 39'h000000000000000

`define modify_vect_const 6'b000000
`define modify_sect_size 6

`define wb_sm 3
`define wb_sm_a 3'b000
`define wb_sm_b 3'b001
`define wb_sm_c 3'b011
`define wb_sm_d 3'b010
`define wb_sm_e 3'b110
`define wb_sm_f 3'b100
`define wb_sm_g 3'b101
`define wb_sm_h 3'b111


// Commands
`define dcFF 8'hFF
`define dc90 8'h90
`define dc70 8'h70
`define dc98 8'h98
`define dc50 8'h50
`define dc20 8'h20
`define dc80 8'h80
`define dcD0 8'hD0
`define dc40 8'h40
`define dc10 8'h10
`define dcE8 8'hE8
`define dcB0 8'hB0
`define dcD0 8'hD0
`define dc60 8'h60
`define dc03 8'h03
`define dc60 8'h60
`define dc01 8'h01
`define dc60 8'h60
`define dcD0 8'hD0

`define dc49 8'h49
`define dc55 8'h55
`define dcAA 8'hAA

// Cui States

`define READARRAY 8'h00
`define ERASU 8'h01
`define BKERASU 8'h02
`define PROGSU 8'h03
`define WRBUFSR 8'h04
`define OPPROGSU 8'h05
`define RCRLOCKSU 8'h06
`define ERA 8'h07
`define ESWAIT 8'h08
`define WRBUFSU 8'h09
`define BKERA 8'h0A
`define ESPROGSU 8'h0B
`define ESWRBUFSU 8'h0C
`define ESRCRLOCK 8'h0D
`define ESPROG 8'h0E
`define ESPSWAIT 8'h0F
`define PROG 8'h10
`define PSWAIT 8'h11
`define ESRCRLOCKSU 8'h12
`define WRBUF 8'h13
`define PAGEPROG 8'h14
`define PAGEPSWAIT 8'h15
`define ESWRBUF 8'h16
`define OPPROG 8'h17
`define ESPAGEPSWAIT 8'h18
`define ESPAGEPROG 8'h19

//-------------------------------

`define micro_idle 8'h00
`define micro_program_s 8'h01
`define micro_load_pgm_add 8'h02
`define micro_load_pgm_data 8'h03
`define micro_pgm_protection 8'h04
`define micro_modify_pgm_sect 8'h05
`define micro_wait_busy_pgm_end 8'h06
`define micro_busy_pgm_end 8'h07
`define micro_program_pulse 8'h08
`define micro_protect_fail 8'h09
`define micro_otp_protect_fail 8'h0A
`define micro_erase_s 8'h0B
`define micro_load_ers_add 8'h0C
`define micro_ers_protection 8'h0D
`define micro_modify_ers_sect 8'h0E
`define micro_wait_busy_ers_end 8'h0F
`define micro_busy_ers_end 8'h10
`define micro_erase_pulse 8'h11
//
`define micro_erase_all 8'h12
`define micro_erase_a_reset 8'h13
`define micro_erase_a_load_add 8'h14
`define micro_erase_a_last_add 8'h15
`define micro_erase_a_inc_add 8'h16
`define micro_erase_a_prot_check 8'h17
`define micro_erase_a_protect_fail 8'h18
`define micro_erase_a_prot_err 8'h19
`define micro_erase_a_otp_protect_fail 8'h1A
`define micro_erase_a_otp_err 8'h1B
`define micro_erase_a_modify_sect 8'h1D
`define micro_erase_a_wait_busy_end 8'h1E
`define micro_erase_a_busy_end 8'h1F
`define micro_erase_a_pulse 8'h20
//
`define micro_lotp 8'h21
`define micro_lock_pulse 8'h22
`define micro_wait_end 8'h23
`define micro_wb_prog 8'h24
`define micro_wb_reset 8'h25
`define micro_wb_load_add 8'h27
`define micro_wb_load_data 8'h28
`define micro_wb_inc 8'h29
`define micro_prot_check 8'h2A
`define micro_wb_prot_fail 8'h2B
`define micro_wb_otp_fail 8'h2C
`define micro_modify_wb 8'h2D
`define micro_wait_busy_wb_end 8'h2E
`define micro_busy_wb_end 8'h2F
`define micro_wb_pulse 8'h30
`define micro_reset_counter 8'h31
`define micro_wb_last_add 8'h33
`define micro_wb_prot_check 8'h34
`define micro_end_op 8'h35
`define micro_reset_ers_counter 8'h36
`define micro_wait 8'h37
`define micro_erase_a_rst_inc_sect 8'h38
`define micro_otp_pgm_pulse 8'h39
`define micro_wb_load_address 8'h3A
`define micro_pen_error 8'h3B
`define micro_op_latch 8'h3C
`define micro_era_susp_branch 8'h3D
`define micro_suspend_ers_load_add 8'h3E
`define micro_suspend_pgm_load_add 8'h3F
`define micro_pgm_susp_branch 8'h40
`define micro_wb_susp_branch 8'h41
`define micro_suspend_wb_load_add  8'h42
`define micro_exit 8'hFF


`define tPROGDWORD 15000
`define initial_otp_data 39'b0
`define otp_sect_1 36
`define otp_sect_2 35
`define sect_no_en 39'h00


`define last_main_sect 30
`define first_main 0

`define last_64k_sect 7
`define first_64k 0
`define idcode_top 32'h0000883A
`define idcode_bottom 32'h00008839

`define main_sect_size 16384
`define tERASESECT 800000000


