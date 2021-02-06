#ifndef functionsH
#define functionsH

#include "types.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include "symtab.h"

structure check_boolean(structure op1, structure operator, structure op2);
structure calculate(structure op1, structure operator, structure op2);
structure negate(structure value);
structure set_place(structure r);
void emit(int nargs, ...);
void put(structure result);
void yyerror(const char *msg);
char* new_temp();
quad* create_list(int sq);
quad* fuse_list(quad *l1, quad *l2);
void complete(quad *l, int n_quad);

#endif
