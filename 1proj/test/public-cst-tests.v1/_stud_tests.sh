#!/usr/bin/env bash

# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# IPP - cst - veřejné testy - 2012/2013
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# Činnost: 
# - vytvoří výstupy studentovy úlohy v daném interpretu na základě sady testů
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

TASK=cst
INTERPRETER=perl
EXTENSION=pl
#INTERPRETER=python3
#EXTENSION=py

# cesta pro ukládání chybového výstupu studentského skriptu
LOCAL_OUT_PATH="."  
LOG_PATH="."


# test01: Zobrazeni napovedy; Expected output: test01.out; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION --help > $LOCAL_OUT_PATH/test01.out 2> $LOG_PATH/test01.err
echo -n $? > test01.!!!

# test02: Parametr -o; Expected output: test02.out; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION --input=dir/file.c --output=$LOCAL_OUT_PATH/test02.out -o 2> $LOG_PATH/test02.err
echo -n $? > test02.!!!

# test03: Parametr -k; Expected output: test03.out; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION --input=dir/ --output=$LOCAL_OUT_PATH/test03.out -k 2> $LOG_PATH/test03.err
echo -n $? > test03.!!!

# test04: Prazdny adresar; Expected output: test04.out; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION --input=dir/emptydir --output=$LOCAL_OUT_PATH/test04.out -k 2> $LOG_PATH/test04.err
echo -n $? > test04.!!!

# test05: Parametr -i; Expected output: test05.out; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION --input=dir/ --output=$LOCAL_OUT_PATH/test05.out -i 2> $LOG_PATH/test05.err
echo -n $? > test05.!!!

# test06: Parametr -c; Expected output: test06.out; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION --input=dir/file.c -c > $LOCAL_OUT_PATH/test06.out 2> $LOG_PATH/test06.err
echo -n $? > test06.!!!

# test07: Parametr -w; Expected output: test07.out; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION -w=ZZ > $LOCAL_OUT_PATH/test07.out 2> $LOG_PATH/test07.err
echo -n $? > test07.!!!

# test08: Parametr -p; Expected output: test08.out; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION -w=ZZ -p --output=$LOCAL_OUT_PATH/test08.out 2> $LOG_PATH/test08.err
echo -n $? > test08.!!!

# test09: Neznamy parametr; Expected output: test09.out; Expected return code: 1
$INTERPRETER $TASK.$EXTENSION --unknown-parameter > $LOCAL_OUT_PATH/test09.out 2> $LOG_PATH/test09.err
echo -n $? > test09.!!!

# test10: Neplatna kombinace parametru; Expected output: test10.out; Expected return code: 1
$INTERPRETER $TASK.$EXTENSION -k -o > $LOCAL_OUT_PATH/test10.out 2> $LOG_PATH/test10.err
echo -n $? > test10.!!!

# test11: Nelze otevrit vstupni soubor; Expected output: test11.out; Expected return code: 2
$INTERPRETER $TASK.$EXTENSION --input=/path/to/a/hopefully/nonexistent/file -o > $LOCAL_OUT_PATH/test11.out 2> $LOG_PATH/test11.err
echo -n $? > test11.!!!

# test12: Nelze otevrit vystupni soubor; Expected output: test12.out; Expected return code: 3
$INTERPRETER $TASK.$EXTENSION --output=/hopefully-no-write-permissions -o > $LOCAL_OUT_PATH/test12.out 2> $LOG_PATH/test12.err
echo -n $? > test12.!!!

# test13: Parametr -k kombinovany s --nosubdir; Expected output: test13.out; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION --input=dir/ --output=$LOCAL_OUT_PATH/test13.out -k --nosubdir 2> test13.err
echo -n $? > test13.!!!

