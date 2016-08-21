#!/usr/bin/env bash

# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# IPP - cst - veřejné mytesty - 2012/2013
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
# Činnost: 
# - vytvoří výstupy studentovy úlohy v daném interpretu na základě sady mytestů
# =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

TASK=cst
INTERPRETER=perl
EXTENSION=pl
#INTERPRETER=python3
#EXTENSION=py

# cesta pro ukládání chybového výstupu studentského skriptu
LOCAL_OUT_PATH="."  
LOG_PATH="."


# mytest01: Zobrazeni napovedy; Expected output: mytest01.out; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION --help > $LOCAL_OUT_PATH/mytest01.out 2> $LOG_PATH/mytest01.err
echo -n $? > mytest01.!!!

# mytest02: Parametr -o; Expected output: mytest02.out; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION --input=dir/file.c --output=$LOCAL_OUT_PATH/mytest02.out -o 2> $LOG_PATH/mytest02.err
echo -n $? > mytest02.!!!

# mytest03: Parametr -k; Expected output: mytest03.out; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION --input=dir/ --output=$LOCAL_OUT_PATH/mytest03.out -k 2> $LOG_PATH/mytest03.err
echo -n $? > mytest03.!!!

# mytest04: Prazdny adresar; Expected output: mytest04.out; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION --input=dir/emptydir --output=$LOCAL_OUT_PATH/mytest04.out -k 2> $LOG_PATH/mytest04.err
echo -n $? > mytest04.!!!

# mytest05: Parametr -i; Expected output: mytest05.out; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION --input=dir/ --output=$LOCAL_OUT_PATH/mytest05.out -i 2> $LOG_PATH/mytest05.err
echo -n $? > mytest05.!!!

# mytest06: Parametr -c; Expected output: mytest06.out; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION --input=dir/file.c -c > $LOCAL_OUT_PATH/mytest06.out 2> $LOG_PATH/mytest06.err
echo -n $? > mytest06.!!!

# mytest07: Parametr -w; Expected output: mytest07.out; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION -w=ZZ > $LOCAL_OUT_PATH/mytest07.out 2> $LOG_PATH/mytest07.err
echo -n $? > mytest07.!!!

# mytest08: Parametr -p; Expected output: mytest08.out; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION -w=ZZ -p --output=$LOCAL_OUT_PATH/mytest08.out 2> $LOG_PATH/mytest08.err
echo -n $? > mytest08.!!!

# mytest09: Neznamy parametr; Expected output: mytest09.out; Expected return code: 1
$INTERPRETER $TASK.$EXTENSION --unknown-parameter > $LOCAL_OUT_PATH/mytest09.out 2> $LOG_PATH/mytest09.err
echo -n $? > mytest09.!!!

# mytest10: Neplatna kombinace parametru; Expected output: mytest10.out; Expected return code: 1
$INTERPRETER $TASK.$EXTENSION -k -o > $LOCAL_OUT_PATH/mytest10.out 2> $LOG_PATH/mytest10.err
echo -n $? > mytest10.!!!

# mytest11: Nelze otevrit vstupni soubor; Expected output: mytest11.out; Expected return code: 2
$INTERPRETER $TASK.$EXTENSION --input=/path/to/a/hopefully/nonexistent/file -o > $LOCAL_OUT_PATH/mytest11.out 2> $LOG_PATH/mytest11.err
echo -n $? > mytest11.!!!

# mytest12: Nelze otevrit vystupni soubor; Expected output: mytest12.out; Expected return code: 3
$INTERPRETER $TASK.$EXTENSION --output=/hopefully-no-write-permissions -o > $LOCAL_OUT_PATH/mytest12.out 2> $LOG_PATH/mytest12.err
echo -n $? > mytest12.!!!

# mytest13: Parametr -k kombinovany s --nosubdir; Expected output: mytest13.out; Expected return code: 0
$INTERPRETER $TASK.$EXTENSION --input=dir/ --output=mytest13.out -k --nosubdir 2> mytest13.err
echo -n $? > mytest13.!!!

