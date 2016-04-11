/* Verificando a sintaxe de programas segundo nossa GLC-exemplo */
/* considerando notacao polonesa para expressoes */
%{
#include <stdio.h> 
%}
%token id
%token flutuante
%token op_atrib
%token op_arit
%left op_arit
%token op_relacional
%left op_relacional
%token del_bloco_abre
%token del_bloco_fecha
%token tipo
%token var
%token branco

%%
/* Regras definindo a GLC e acoes correspondentes */
programa: lista_func {;}
| var del_bloco_abre lista_var del_bloco_fecha lista_func {;};

lista_var: declaracao_var {;}
| declaracao_var lista_var {;};

lista_func: declaracao_fun {;}
| declaracao_fun lista_func {;};

declaracao_var: tipo id {;}
| tipo id exp_atrib {;};

declaracao_fun: tipo id del_bloco_abre lista_cmds del_bloco_fecha{;}

lista_cmds:	cmd	{;}
| cmd ';' lista_cmds {;};

cmd: id exp_atrib {;} ;

exp_atrib: op_atrib exp {;}

exp: flutuante {;}
| id {;}
| exp op_arit exp {;}
| relacao {;}; 

relacao: exp op_relacional exp {;}
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
