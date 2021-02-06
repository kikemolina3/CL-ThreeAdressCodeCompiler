#include "library.h"

structure negate(structure value) {
    if(value.type == INT){
    	value.integer = -value.integer;
    	sprintf(value.string, " CHSI ");
    } 	
    if(value.type == FLOAT){
    	value.real = -value.real;
    	sprintf(value.string, " CHSF ");
    } 	
    return value;
}

structure check_boolean(structure op1, structure operator, structure op2) {
    if (op1.type == STRING || op2.type == STRING)
        yyerror("Strings comparation not allowed");

    char *op = operator.string;
    structure r;
    r.type = BOOLEAN;
    float r1, r2;
    
    if (op1.type == INT) 	r1 = op1.integer;
    if (op1.type == FLOAT) 	r1 = op1.real;
    if (op2.type == INT) 	r2 = op2.integer;
    if (op2.type == FLOAT) 	r2 = op2.real;

    char* aux = malloc(7);
    if (strlen(op) == 1) {
        if(op[0] == '>') { r.boolean = r1 > r2; sprintf(aux, " GT"); }
        if(op[0] == '<') { r.boolean = r1 < r2; sprintf(aux, " LT"); }
    } 
    else {
        if(op[0] == '>' && op[1] == '=') { r.boolean = r1 >= r2; sprintf(aux, " GE"); }
        if(op[0] == '<' && op[1] == '=') { r.boolean = r1 <= r2; sprintf(aux, " LE"); }
        if(op[0] == '=' && op[1] == '=') { r.boolean = r1 == r2; sprintf(aux, " EQ"); }
        if(op[0] == '<' && op[1] == '>') { r.boolean = r1 != r2; sprintf(aux, " NE"); }
    }
    if (op1.type == INT && op2.type == INT) strcat(aux, "I ");
    else strcat(aux, "F ");
    
    strcpy(operator.string, aux);
       
    return set_place(r);
}

structure calculate(structure op1, structure operator, structure op2) {
    structure r;
    float r1, r2, number;
    char op = (operator.string)[0];
    char *aux;
    
    if (op1.type == INT) r1 = op1.integer;
    if (op1.type == FLOAT) r1 = op1.real;
    if (op2.type == INT) r2 = op2.integer;
    if (op2.type == FLOAT) r2 = op2.real;
    
    if (op1.type == INT && op2.type == INT) {
    	r.type = INT;
    	if (op == '+') sprintf(operator.string, " ADDI ");
    	if (op == '-') sprintf(operator.string, " SUBI ");
    	if (op == '*') sprintf(operator.string, " MULI ");
    	if (op == '/') sprintf(operator.string, " DIVI ");
    }
    else  {
    	r.type = FLOAT;
    	if (op == '+') sprintf(operator.string, " ADDF ");
    	if (op == '-') sprintf(operator.string, " SUBF ");
    	if (op == '*') sprintf(operator.string, " MULF ");
    	if (op == '/') sprintf(operator.string, " DIVF ");
    }
    
    if (op == '+') number = r1 + r2;
    if (op == '-') number = r1 - r2;
    if (op == '*') number = r1 * r2;
    if (op == '/') number = r1 / r2;
    if (op == '^') number = pow(r1, r2);
    if (op == '%') {
        if (op1.type == INT && op2.type == INT) number = (int)r1 % (int)r2;
        else yyerror("MOD operation require only integers");
    }
    
    if (op1.type == INT && op2.type == INT){
    	r.integer = number;
    }
    else
    	r.real = number;
    	
    return set_place(r);
}

void put(structure r) {
    emit(2, "PARAM ", r.place);
    if (r.type == INT) 		emit(1, "CALL PUTI, 1");
    if (r.type == FLOAT) 	emit(1, "CALL PUTF, 1");
}

structure set_place(structure r){
    char* aux;
    if (r.type == INT) {
    	aux = malloc(sizeof(int));
    	sprintf(aux, "%i", r.integer);
    }
    else if(r.type == FLOAT) {
    	aux = malloc(sizeof(float));
    	sprintf(aux, "%f", r.real);
    }
    /*else if(r.type == BOOLEAN) {
    	aux = malloc(sizeof(float));
    	sprintf(aux, "%i", r.boolean);
    }*/
    r.place = aux;  
    return r;
}

char* new_temp(){
    char* intro = malloc(6);
    char* number = malloc(4);
    sprintf(number, "%i", next_temp);
    strcpy(intro, "$t");
    strcat(intro, number);
    next_temp++;
    return intro;
}

void emit(int nargs, ...){
    char * quad = malloc(50);
    strcpy(quad, "");
    char* aux;
    int i;
    va_list ap;
    va_start(ap, nargs);
    for(i=0; i<nargs; i++){
    	aux = va_arg(ap, char*);
    	strcat(quad, aux);
    }
    va_end(ap);
    quads[next_quad-1] = malloc(50);
    sprintf(quads[next_quad-1], "%d: %s", next_quad, quad);
    quads = realloc(quads, 50 * (next_quad + 1));
    next_quad++;
}

quad* create_list(int sq)
{
    quad q;
    quad* list;
    q.n_quad = sq;
    q.next_q = NULL;
    list = malloc(sizeof(quad));
    list[0] = q;
    return list;
}

quad* fuse_list(quad *l1, quad *l2)
{
    quad *aux;
    if(l1 == NULL) aux = l2;
    else {
        aux = l1;
        while(l1->next_q != NULL) 
            l1 = l1->next_q; 
        l1->next_q = l2;
    }
    return aux;
}

void complete(quad *l, int n_quad)
{   
    char* aux;
    while(l != NULL) {
        aux = quads[l->n_quad-1];
        sprintf(quads[l->n_quad-1], "%s %d", aux, n_quad);
        l = l->next_q;
    }
}

