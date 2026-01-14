@echo off
set COMPILER=C:\mingw64\bin\gcc
                set CXXCOMPILER=C:\mingw64\bin\g++
                set COMPFLAGS=-c -fexceptions -fno-omit-frame-pointer -m64 -DMATLAB_MEX_FILE  -DMATLAB_MEX_FILE 
                set CXXCOMPFLAGS=-c -fexceptions -fno-omit-frame-pointer -m64 -DMATLAB_MEX_FILE  -DMATLAB_MEX_FILE 
                set OPTIMFLAGS=-O2 -fwrapv -DNDEBUG
                set DEBUGFLAGS=-g
                set LINKER=C:\mingw64\bin\gcc
                set CXXLINKER=C:\mingw64\bin\g++
                set LINKFLAGS=-m64 -Wl,--no-undefined -shared -static -L"C:\Program Files\MATLAB\R2025a\extern\lib\win64\mingw64" -llibmx -llibmex -llibmat -lm -llibmwlapack -llibmwblas -Wl,"C:\Program Files\MATLAB\R2025a/extern/lib/win64/mingw64/mexFunction.def"
                set LINKDEBUGFLAGS=-g
                set NAME_OUTPUT=-o "%OUTDIR%%MEX_NAME%%MEX_EXT%"
set PATH=C:\mingw64\bin;C:\Program Files\MATLAB\R2025a\extern\include\win64;C:\Program Files\MATLAB\R2025a\extern\include;C:\Program Files\MATLAB\R2025a\simulink\include;C:\Program Files\MATLAB\R2025a\lib\win64;%MATLAB_BIN%;%PATH%
set INCLUDE=C:\mingw64\include;;%INCLUDE%
set LIB=C:\mingw64\lib;;%LIB%
set LIBPATH=C:\Program Files\MATLAB\R2025a\extern\lib\win64;%LIBPATH%

gmake SHELL="cmd" -f Simulacion_cgxe.gmk
