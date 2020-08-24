@echo off
set author=luo_k
set rtl_path=.\rtl_407
set res_file=fsmc_407.v


if exist %res_file%  (
    del %res_file%
  )

copy  %rtl_path%\*.v  %res_file%
echo //          finished  file  %res_file%           // >> %res_file%
