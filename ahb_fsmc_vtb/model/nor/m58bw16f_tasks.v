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
//inout [31:0] DQ;
//in [19:0] A;
//in E_;
//in K;
//in PEN;
//in L_;
//in RP_;
//in G_;
//in GD_;
//in W_;
//in WP_;
//in B_;
//out R;

task power_supply_on;
  begin
    DQ_int = 32'hzzzzzzzz;
    A = 20'hzzzzz;
    E_ = 1'bz;
    K = 1'bz;
    PEN = 1'bz;
    L_ = 1'bz;
    RP_ = 1'bz;
    G_ = 1'bz;
    GD_ = 1'bz;
    W_ = 1'bz;
    WP_ = 1'bz;
    B_ = 1'bz;
    VDD = 1'b0;
    VDDQ = 1'b0;
    VDDQIN = 1'b0;
    VSS = 1'b0;
    VSSQ = 1'b0;
    #10;
    VDD = 1'b1;
    VDDQ = 1'b1;
    VDDQIN = 1'b1;
    RP_ = 1'b0;
    #1;
  end
endtask

task end_power_on;
  begin
    #50;
    RP_ = 1'b1;
  end
endtask

task signal_init;
  begin
    DQ_int = 32'hzzzzzzzz;
    A = 20'hzzzzz;
    E_ = 1'b1;
    K = 1'b1;
    PEN = 1'b1;
    L_ = 1'b1;
    RP_ = 1'b0;
    G_ = 1'b1;
    GD_ = 1'b1;
    W_ = 1'b1;
    WP_ = 1'b1;
    B_ = 1'b1;
  end
endtask

task write_cycle ;

input [31:0] data_in ;
input [19:0] add_in ;

  begin
    E_ = 1'b0;
    A = add_in;
    #1;
    G_ = 1'b1;
    GD_ = 1'b1;
    #1;
    #`tELWL;
    W_ = 1'b0;
    DQ_int = data_in ;
    #`tWLWH;
    W_ = 1'b1;
    #`tWHWL;
  end
endtask

task add_latch ;
input [19:0] add_in ;
  begin
    E_ = 1'b0;
    A = add_in;
    #`tELWL;
    L_ = 1'b0;
    #`tLLLH;
    L_ = 1'b1;
    #`tLHLL;
  end
endtask

task clock_cycle ;
input [31:0] clocks ;
integer i ;
  begin
    for (i = 0 ; i <= clocks - 1 ; i = i + 1)
       begin
         K = 1'b0;
         #7;
         K = 1'b1;
         #13;
         K = 1'b0;
         #7;
       end
  end
endtask

task add_latch_clock ;
input [19:0] add_in ;
  begin
    E_ = 1'b0;
    K = 1'b0;
    A = add_in;
    L_ = 1'b0;
    #7;
    K = 1'b1;
    #7;
    K = 1'b0;    
    L_ = 1'b1;
  end
endtask


task read_cycle ;
input [19:0] add_in ;
  begin
    E_ = 1'b0;
    #1;
    add_latch(add_in);
    DQ_int = `tristate_data;
    #1;
    G_ = 1'b0;
    #1;
    GD_ = 1'b1;
    #10;
  end
endtask
