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
// task Read_Status_Reg(address);
// task Clear_Status_Reg;
// task Read_Array(read_address, read_data);
// task Read_Electronic_Signature(read_address, read_data);
// task Read_Status_Reg(read_address);
// task Read_Query(read_address, read_data);
// task Block_Erase(Block_Erase);
// task Erase_All_Main_Blocks;
// task Program_dc40(pgm_address, pgm_data);
// task Program_dc10(pgm_address, pgm_data);
// task Program_OTP(pgm_OTP_address, pgm_OTP_data);
// task Program_Lock_OTP;
// task Program_WB(pgm_wb_addresses, pgm_wb_data, number_of_words);
// task Program_Suspend(add);
// task Erase_Suspend(add);
// task Program_Resume(add);
// task Erase_Resume(add);
// task Set_Burst_CR(BCR_Data);
// task Set_Block_Prot_Reg(Block_Address);
// task Clear_Block_Prot_Reg(Block_Address);
// task Polling_Status(till_end);

task power_on;
  begin
    power_supply_on;
    signal_init;
    end_power_on;
  end
endtask

task Read_Status_Reg;
input [19:0] add_int;
  begin
    write_cycle(32'h00000070, add_int);
  end
endtask

task Clear_Status_Reg;
  begin
    write_cycle(32'h00000050, 20'h00000);
  end
endtask

// ----------------------------------------------

task Read_Array;
input [19:0] add_int;
  begin
    write_cycle(32'h000000FF, 20'h00000);
    read_cycle(add_int);
  end
endtask

task Read_Electronic_Signature;
input [19:0] add_int;
  begin
    write_cycle(32'h00000090, 20'h12345);
    read_cycle(add_int);
  end
endtask

task Read_Query;
input [19:0] add_int;
  begin
    write_cycle(32'h00000098, add_int);
    read_cycle(add_int);
  end
endtask

// ----------------------------------------------

task Block_Erase;
input [19:0] add_int;
  begin
    write_cycle(32'h00000020, 20'h00055);
    write_cycle(32'h000000D0, add_int);
  end
endtask

task Erase_All_Main_Blocks;
  begin
    write_cycle(32'h00000080, 20'h00055);
    write_cycle(32'h000000D0, 20'h000AA);
  end
endtask

// ----------------------------------------------

task Program_dc40;
input [19:0] add_int;
input [31:0] data_int;
  begin
    write_cycle(32'h00000040, 20'h000AA);
    write_cycle(data_int, add_int);
  end
endtask

task Program_dc10;
input [19:0] add_int;
input [31:0] data_int;
  begin
    write_cycle(32'h00000010, 20'h000AA);
    write_cycle(data_int, add_int);
  end
endtask

task Program_OTP;
input [19:0] add_int;
input [31:0] data_int;
  begin
    write_cycle(32'h00000040, 20'h000AA);
    write_cycle(data_int, add_int);
  end
endtask

task Program_Lock_OTP;
  begin
    write_cycle(32'h00000049, 20'h000AA);
    write_cycle(32'h00000000, 20'h00003);
  end
endtask

task Program_WB;
input [159:0] add_int;
input [255:0] data_int;
input [31:0] n_int;

integer i;
integer j;
  begin
    write_cycle(32'h000000E8, 20'h000AA);
    write_cycle(n_int, add_int);

    case (n_int)
        4'h0:
            begin
              write_cycle(data_int[31:0], add_int[19:0]);
            end
        4'h1:
            begin
              write_cycle(data_int[31:0], add_int[19:0]);
              write_cycle(data_int[63:32], add_int[39:20]);

            end
        4'h2:
            begin
              write_cycle(data_int[31:0], add_int[19:0]);
              write_cycle(data_int[63:32], add_int[39:20]);
              write_cycle(data_int[95:64], add_int[59:40]);


            end
        4'h3:
            begin
              write_cycle(data_int[31:0], add_int[19:0]);
              write_cycle(data_int[63:32], add_int[39:20]);
              write_cycle(data_int[95:64], add_int[59:40]);
              write_cycle(data_int[127:96], add_int[79:60]);
            end
        4'h4:
            begin
              write_cycle(data_int[31:0], add_int[19:0]);
              write_cycle(data_int[63:32], add_int[39:20]);
              write_cycle(data_int[95:64], add_int[59:40]);
              write_cycle(data_int[127:96], add_int[79:60]);
              write_cycle(data_int[159:128], add_int[99:80]);
            end
        4'h5:
            begin
              write_cycle(data_int[31:0], add_int[19:0]);
              write_cycle(data_int[63:32], add_int[39:20]);
              write_cycle(data_int[95:64], add_int[59:40]);
              write_cycle(data_int[127:96], add_int[79:60]);
              write_cycle(data_int[159:128], add_int[99:80]);
              write_cycle(data_int[191:160], add_int[119:100]);
            end
        4'h6:
            begin
              write_cycle(data_int[31:0], add_int[19:0]);
              write_cycle(data_int[63:32], add_int[39:20]);
              write_cycle(data_int[95:64], add_int[59:40]);
              write_cycle(data_int[127:96], add_int[79:60]);
              write_cycle(data_int[159:128], add_int[99:80]);
              write_cycle(data_int[191:160], add_int[119:100]);
              write_cycle(data_int[223:192], add_int[139:120]);
            end
        4'h7:
            begin
              write_cycle(data_int[31:0], add_int[19:0]);
              write_cycle(data_int[63:32], add_int[39:20]);
              write_cycle(data_int[95:64], add_int[59:40]);
              write_cycle(data_int[127:96], add_int[79:60]);
              write_cycle(data_int[159:128], add_int[99:80]);
              write_cycle(data_int[191:160], add_int[119:100]);
              write_cycle(data_int[223:192], add_int[139:120]);
              write_cycle(data_int[255:224], add_int[159:140]);
            end
        default:
            begin
              write_cycle(data_int[31:0], add_int[19:0]);
            end
    endcase
    // manca ciclo for per caricamento
    write_cycle(32'h000000D0, 20'hAAAAA);
  end
endtask

task Program_Suspend;
input [19:0] add_int;
  begin
    write_cycle(32'h000000B0, add_int);
  end
endtask

task Erase_Suspend;
input [19:0] add_int;
  begin
    write_cycle(32'h000000B0, add_int);
  end
endtask

task Program_Resume;
input [19:0] add_int;
  begin
    write_cycle(32'h000000D0, add_int);
  end
endtask

task Erase_Resume;
input [19:0] add_int;
  begin
    write_cycle(32'h000000D0, add_int);
  end
endtask

// ----------------------------------------------

task Set_Burst_CR;
input [19:0] add_int;
  begin
    write_cycle(32'h00000060, 20'h00000);
    write_cycle(32'h00000003, add_int);
    // manca read cycle
  end
endtask

task Set_Block_Prot_Reg;
input [19:0] add_int;
  begin
    write_cycle(32'h00000060, 20'h00000);
    write_cycle(32'h00000001, add_int);
  end
endtask

task Clear_Block_Prot_Reg;
input [19:0] add_int;
  begin
    write_cycle(32'h00000060, 20'h00000);
    write_cycle(32'h000000D0, add_int);
  end
endtask

// ----------------------------------------------

// task Polling_Status(till_end);
// task Polling_Status;
// input till_end;
// integer i;
//   begin
//     #10;
//     G_ = 1'b0;
//     GD_ = 1'b1;
//     #10;
//     read_cycle(20'h00081);
//     #100;
//     while (top.dqpad_manager.dqpad_sr[7] == 1'b0)
//           begin
//             G_ = 1'b1;
//             #100;
//             G_ = 1'b0;
//             #100;
//             G_ = 1'b1;
//           end
//   end
// endtask
