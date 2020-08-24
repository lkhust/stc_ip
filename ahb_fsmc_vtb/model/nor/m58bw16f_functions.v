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
////inout [31:0] DQ;
////in [19:0] A;
////in E_;
////in K;
////in PEN;
////in L_;
////in RP_;
////in G_;
////in GD_;
////in W_;
////in WP_;
////in B_;
////out R;

function [31:0] sect_index_main;

  input [5:0] add;

  sect_index_main = add[0]*1 + add[1]*2 + add[2]*4 + add[3]*8 + add[4]*16 + add[5]*32;
endfunction

function [31:0] sect_index_sparam;
  input [2:0] add;

  sect_index_sparam = add[0]*1 + add[1]*2 + add[2]*4;

endfunction

//!task sectinfo;
//!input [31:0] sect_index;
//!$display("[%0t ns] settore %d",sect_index);
//!endtask

function [31:0] sect_index_bparam;
  input [1:0] add;

  sect_index_bparam = add[0]*1 + add[1]*2;

endfunction

///////////

function [31:0] sector_index;
  input [19:0] add_mod;

//1111 11 11 0000
  if (add_mod[19:14] == 8'h3E)
    sector_index = 8'h3E + add_mod[13:11];
  else if (add_mod[19:14] == 8'h3F)
    sector_index = 8'h46 + add_mod[12:11];
  else
    sector_index = add_mod[19:14];
endfunction
