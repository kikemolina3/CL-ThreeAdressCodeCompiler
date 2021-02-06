%{
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <stdlib.h>
#include <math.h>
#include <stdarg.h>
#include "symtab.h"

extern FILE* yyin;
extern int yylineno;

int yylex();
%}

%code requires {
    #include "library.h"
}

%define parse.error verbose

%union {
    structure var;
};

%token ASIGN OPEN CLOSE TTRUE TFALSE AND OR NOT DO DONE IF THEN FI ELSE WHILE UNTIL DOUBLEPOINT IN FOR
%token <var> ADD SUB MUL DIV POW MOD GT LT GE LE EQ NE VAR BOOLEAN_ID ARITHMETIC_ID INTRO REPEAT 
%type <var> expression arithmetic_op1 arithmetic_op2 arithmetic_exp sum mul pow instructions instruction header boolean_op boolean_exp and not top_bool m n else p

%start program

%%


program: instructions					{ 	complete($1.next_list, next_quad); 
								emit(1, "HALT");
							} 

instructions: instructions m instruction           	{ 	
								complete($1.next_list, $2.repeat); 
								$$.next_list = $3.next_list;
							}
    | instruction                             		
;

instruction: ARITHMETIC_ID ASIGN expression INTRO 	{ sym_enter($1.string, &$3); emit(3, $1.string, " := " ,$3.place); }
    | expression INTRO                        		{ put($1); }
    | header DO INTRO instructions DONE INTRO		{ 	// C3A DE REPEAT
    								/*char* aux = malloc(sizeof(int));
    								sprintf(aux, "%i", $1.repeat);*/
    								char* aux2 = malloc(sizeof(int));
    								sprintf(aux2, "%i", $1.integer);
    								emit(4, $1.place, " := ", $1.place, " ADDI 1");
     								emit(6, "IF ", $1.place, " LTI ", $1.string, " GOTO ", aux2);
     							}
    | IF OPEN boolean_exp CLOSE 
    THEN INTRO m instructions else FI INTRO    		{ 	complete($3.true_list, $7.repeat);
    								if ($9.repeat == -1)
									$$.next_list = fuse_list($3.false_list, $8.next_list);
								else {
									$$.next_list = fuse_list($8.next_list, $9.next_list); 
    									complete($3.false_list, $9.repeat); 
								}
    							}
    | WHILE OPEN m boolean_exp CLOSE DO 
    INTRO m instructions DONE INTRO     		{ 		complete($4.true_list, $8.repeat); 
								complete($9.next_list, $3.repeat); 
								$$.next_list = $4.false_list; 
								char* aux = malloc(5); 
								sprintf(aux, "%i", $3.repeat);
								emit(2, "GOTO ", aux);
    						        } 
    | DO INTRO m instructions UNTIL OPEN 
    boolean_exp CLOSE INTRO        			{ 	complete($7.true_list, $3.repeat); 
								$$.next_list = fuse_list($7.false_list, $4.next_list); 
						   	} 
    | p DO INTRO instructions DONE INTRO             	{	complete($4.next_list, next_quad); 
								char *aux = malloc(6);
								emit(4, $1.string, " := ", $1.string, " ADDI 1");  
								sprintf(aux, "%i", $1.integer); 
								emit(2, "GOTO ", aux); 
								$$.next_list = $1.next_list; 
    							}   							
;
     							
header: REPEAT arithmetic_exp				{ 	$$.place = new_temp(); 
								emit(2, $$.place, " := 0");
								$$.integer = next_quad; 
								$$.string = $2.place;
							};
							
p: FOR OPEN ARITHMETIC_ID IN arithmetic_exp 
DOUBLEPOINT arithmetic_exp CLOSE                   { 	

								structure s; 
								emit(3, $3.string, " := ", $5.place);
								$$.place = $5.place; 
								$$.integer = next_quad; 
								char *aux = malloc(6);
								sprintf(aux, "%i", $$.integer+2); 
								emit(6, "IF ", $3.string, " LEI ", $7.place, " GOTO ", aux); 
								$$.next_list = create_list(next_quad); 
								emit(1, "GOTO"); 
								$$.string = $3.string;
					    		}
					    		
else: 							{ $$.repeat = -1; }
    | ELSE INTRO n m instructions 			{ 	$$.next_list = fuse_list($3.next_list, $5.next_list); 
    								$$.repeat = $4.repeat; 
    							}		

expression: arithmetic_exp | boolean_exp;

arithmetic_exp: arithmetic_exp arithmetic_op1 sum	{ 	$$ = calculate($1, $2, $3); 
								$$.place = new_temp(); 
								emit(5, $$.place, " := ", $1.place, $2.string, $3.place);
							} 
    | sum                                  
;

sum: sum arithmetic_op2 mul                            	{ 	$$ = calculate($1, $2, $3); 
								$$.place = new_temp(); 
								emit(5, $$.place, " := ", $1.place, $2.string, $3.place);
							} 
    | SUB VAR                              		{ 	$2 = set_place($2); 
    								$$ = negate($2); 
    								char* number = $$.place; 
    								$$.place = new_temp(); 
    								emit(4, $$.place, " :=", $$.string, number);
    							}
    | SUB ARITHMETIC_ID                     		{ 	structure s; 
    								if(sym_lookup($2.string, &s) == SYMTAB_NOT_FOUND) 
    									yyerror("Identifier not exist"); 
    								s = set_place(s); 
    								$$ = negate(s);
    								char* number = $2.string; 
    								$$.place = new_temp(); 
    								emit(4, $$.place, " :=", $$.string, number); 
    							}
    | mul                                   
;

mul: mul POW pow                            		{ 	// C3A DE POTENCIA
								char* cont = new_temp(); 
								char *pow = new_temp();
								emit(2, pow, " := 1");
								int line = next_quad;
								$$ = calculate($1, $2, $3);
								emit(5, pow, " := ", pow, " MULI ", $1.place);
								char* aux = malloc(sizeof(int));
    								sprintf(aux, "%i", $3.integer);
    								char* aux2 = malloc(sizeof(int));
    								sprintf(aux2, "%i", line);
    								emit(4, cont, " := ", cont, " ADDI 1");
								emit(6, "IF ", cont, " LTI ", aux, " GOTO ", aux2);
								$$.place = pow;
								
							} 
    | pow                                 
;

pow: ARITHMETIC_ID                           		{ 	if(sym_lookup($1.string, &$$) == SYMTAB_NOT_FOUND) 
									yyerror("Identifier not exist"); 
								else 
									$$.place = $1.string;
							}
    | VAR                                   		{ $$ = set_place($1); }
    | OPEN arithmetic_exp CLOSE                  	{ $$ = $2; }
;

boolean_exp: boolean_exp OR m and               	{ 	$$.boolean = $1.boolean || $3.boolean; 
								$$.type = BOOLEAN;
								$$.true_list = fuse_list($1.true_list, $4.true_list); 
								$$.false_list = $4.false_list; 
								complete($1.false_list, $3.repeat); 
							}
    | and                                    
;

and: and AND m not                          		{ 	$$.boolean = $1.boolean && $3.boolean; 
								$$.type = BOOLEAN; 
								$$.true_list = $4.true_list; 
								$1.false_list = fuse_list($1.false_list, $4.false_list); 
								complete($1.true_list, $3.repeat);
							}
    | not                                   
;

not: NOT top_bool                                	{ 	$$ = $2; 
								$$.boolean = !$$.boolean; 
								$$.type = BOOLEAN;
								$$.true_list = $2.false_list; 
								$$.false_list = $2.true_list;
							}
    | top_bool                                  
;

top_bool: arithmetic_exp boolean_op arithmetic_exp  	{ 	$$ = check_boolean($1, $2, $3);
								$$.true_list = create_list(next_quad);
								emit(5, "IF ", $1.place, $2.string, $3.place, " GOTO");
								$$.false_list = create_list(next_quad);
								emit(1, "GOTO");
							} 
    | TTRUE                                  		{ 	$$.boolean = true; 
    								$$.type = BOOLEAN;
    								$$.place = "TRUE";
    								$$.true_list = create_list(next_quad);
    								$$.false_list = NULL;
    								emit(1, "GOTO");
    							}
    | TFALSE                                  		{ 	$$.boolean = false; 
    								$$.type = BOOLEAN;
    								$$.place = "FALSE";
    								$$.true_list = NULL;
    								$$.false_list = create_list(next_quad);
    								emit(1, "GOTO");
    							}
    | OPEN boolean_exp CLOSE                 		{ $$ = $2; }
    | BOOLEAN_ID                            		{ if(sym_lookup($1.string, &$$) == SYMTAB_NOT_FOUND) yyerror("Identifier not exist"); }
;

m: { $$.repeat = next_quad; }

n: { $$.next_list = create_list(next_quad); emit(1, "GOTO"); }

arithmetic_op1: ADD | SUB;                                

arithmetic_op2: MUL | DIV | MOD;   

boolean_op: GT | LT | GE | LE | EQ | NE;


%%

void yyerror(const char *err)
{
    printf("ERROR!: (%s), line: %i", err, yylineno);
    exit(1);
}

int main(int argc, char **argv)
{
    quads = (char **) malloc(50);
    next_quad = 1;
    next_temp = 1;
    if (argc > 1)
        yyin = fopen(argv[1],"r");
    else
        yyin = stdin;
    yyparse();
    for (int i = 0; i < next_quad-1; i++)
        printf("%s\n", quads[i]);
    return 0;
}
