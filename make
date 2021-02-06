#!/bin/bash
[ "$1" = "clean" ] && rm *.tab.* *.yy.c *.o && exit
[ "$1" = "run" ] && ./prac1.o "input.txt" && exit
[ $# -eq 0 ] && flex lexic.l & bison -d syntax.y && gcc lex.yy.c syntax.tab.c symtab.c library.c -o prac1.o -lm
