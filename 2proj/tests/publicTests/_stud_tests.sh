#!/usr/bin/env bash

# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# IPP - cha - veřejné testy - 2012/2013
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# Činnost: 
# - vytvoří výstupy studentovy úlohy v daném interpretu na základě sady testů
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

TASK=cha
#INTERPRETER=perl
#EXTENSION=pl
INTERPRETER=python3
EXTENSION=py

# cesta pro ukládání chybového výstupu studentského skriptu
LOCAL_OUT_PATH="./myout"
LOG_PATH="./myout"


# test01: Cannot open output file; Expected output: test01; Expected return code: 3
$INTERPRETER $TASK.$EXTENSION --output=/hopefully-no-write-permissions > $LOCAL_OUT_PATH/test01.out 2> $LOG_PATH/test01.err
echo -n $? > test01.!!!
###OK

# test02: Non-existent input file; Expected output: test02; Expected return code: 2
$INTERPRETER $TASK.$EXTENSION --input=/path/to/a/hopefully/nonexistent/file > $LOCAL_OUT_PATH/test02.out 2> $LOG_PATH/test02.err
echo -n $? > test02.!!!
###OK

# test03: Analysis of a trivial header file; Expected output: test03; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION --input=basic/trivial.h --output=$LOCAL_OUT_PATH/test03.out 2> $LOG_PATH/test03.err
echo -n $? > test03.!!!
###OK

# test04: Analysis of functions which are not declared as inline; Expected output: test04; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION --input=basic/subdir/subsubdir/ --output=$LOCAL_OUT_PATH/test04.out --no-inline --pretty-xml=0 2> $LOG_PATH/test04.err
echo -n $? > test04.!!!
###OK

# test05: Analysis of the whole current directory; Expected output: test05; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION --pretty-xml > $LOCAL_OUT_PATH/test05.out 2> $LOG_PATH/test05.err
echo -n $? > test05.!!!
###OK

# test06: Analysis of functions with at most one parameter; Expected output: test06; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION --input=basic/trivial.h --output=$LOCAL_OUT_PATH/test06.out --max-par=1 --pretty-xml=3 2> $LOG_PATH/test06.err
echo -n $? > test06.!!!
###OK

# test07: Analysis of a file where a function is declared more than once; Expected output: test07; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION --input=basic/more.h --output=$LOCAL_OUT_PATH/test07.out --no-duplicates 2> $LOG_PATH/test07.err
echo -n $? > test07.!!!
###OK

# test08: Reduction of the number of whitespace in types; Expected output: test08; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION --input=basic/subdir/subsubdir/whitespace.h --remove-whitespace --output=$LOCAL_OUT_PATH/test08.out 2> $LOG_PATH/test08.err
echo -n $? > test08.!!!
###OK

# test09: Unknown program argument; Expected output: test09; Expected return code: 1
$INTERPRETER $TASK.$EXTENSION --unknown-argument > $LOCAL_OUT_PATH/test09.out 2> $LOG_PATH/test09.err
echo -n $? > test09.!!!
###OK

# test10: Display program help; Expected output: test10; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION --help > $LOCAL_OUT_PATH/test10.out 2> $LOG_PATH/test10.err
echo -n $? > test10.!!!
###OK

# test11: Analysis of functions with rather complex data types (the FUN extension); Expected output: test11; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION --pretty-xml --output=$LOCAL_OUT_PATH/test11.out --input=ext/FUN.h 2> $LOG_PATH/test11.err
echo -n $? > test11.!!!

# test12: Analysis of functions with missing parameter names (the PAR extension); Expected output: test12; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION --pretty-xml --output=$LOCAL_OUT_PATH/test12.out --input=ext/PAR.h 2> $LOG_PATH/test12.err
echo -n $? > test12.!!!

