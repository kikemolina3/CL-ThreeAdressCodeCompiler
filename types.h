#include <stdbool.h>
#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#ifndef typesH
#define typesH

#define INT 0
#define FLOAT 1
#define STRING 2
#define BOOLEAN 3

typedef struct quadx
{
	int n_quad;
	struct quadx* next_q;
} quad;

typedef struct{
    char *string;
    int integer;
    float real;
    bool boolean;
    char type;
    char *place;
    int repeat;
    quad* true_list;
    quad* false_list;
    quad* next_list;
} structure;

int next_temp;
int next_quad;
char **quads;

#endif
