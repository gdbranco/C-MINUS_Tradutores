/* Verificando a sintaxe de programas segundo nossa GLC-exemplo */
/* considerando notacao polonesa para expressoes */
%{
#include <stdio.h> 
%}
%token id
%token flutuante
%token op_atrib
%token op_add
%token op_mult
%token op_relacional
%token op_rpt
%token op_if
%nonassoc IFX
%nonassoc op_else
%token del_bloco_abre
%token del_bloco_fecha
%token sub
%token tipo
%token branco

%%
/* Regras definindo a GLC e acoes correspondentes */
programa: lista_declaracao {;};

lista_declaracao: declaracao {;}
| lista_declaracao declaracao {;};

declaracao: declaracao_var {;}
| declaracao_fun {;};

declaracao_var: tipo lista_declaracao_var {;};

lista_declaracao_var: id ';' {;}
| id ',' lista_declaracao_var {;};

declaracao_fun: tipo id '('')' cmpst_statement {;} ;

cmpst_statement: del_bloco_abre lista_statement del_bloco_fecha;

lista_statement: statement {;}
| statement lista_statement {;};

statement: exp_statement {;} 
| sel_statement {;}
| rpt_statement {;}
| cmpst_statement {;};

sel_statement: op_if '(' exp ')' statement %prec IFX{;} 
| op_if '(' exp ')' statement op_else statement {;};

rpt_statement: op_rpt '(' exp ')' statement {;};

exp_statement:  exp ';' {;} ;

exp: var op_atrib exp {;}
| exp_simples {;};

var: id {;};

exp_simples: exp_add op_relacional exp_add {;}
| exp_add {;};

exp_add: exp_add op_add term {;}
| term {;};

term: term op_mult fator {;}
| fator {;};

fator: '(' exp ')' {;}
| call {;}
| var {;}
| flutuante {;};

call: id '('')' {;};
%%
extern FILE *yyin;
int main (int argc, char *argv[]) 
{
	int erro;
	if(argc < 2)
	{
		perror("Too few argc\n");
		return -1;
	}
	yyin = fopen(argv[1],"r");
	if(yyin)
	{
		erro = yyparse();
		if(!erro)
			printf("PROGRAMA TA MASSA\n");
	}
	return 0;
}
yyerror (s) /* Called by yyparse on error */
{
	printf ("Problema com a analise sintatica!\n");
}
