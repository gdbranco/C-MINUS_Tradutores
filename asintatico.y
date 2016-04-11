/* Verificando a sintaxe de programas segundo nossa GLC-exemplo */
/* considerando notacao polonesa para expressoes */
%{
#include <stdio.h> 
%}
%token id
%token flutuante
%token op_atrib
%token op_arit
%token op_relacional
%token del_bloco

%%
/* Regras definindo a GLC e acoes correspondentes */
/* neste nosso exemplo quase todas as acoes estao vazias */
input: /* empty */
| input line;

line:'\n'
| programa '\n'  { printf ("Programa sintaticamente correto!\n"); };

programa: del_bloco lista_cmds del_bloco {;};

lista_cmds:	cmd	{;}
| cmd ';' lista_cmds {;};

cmd: id op_atrib exp {;};

exp: flutuante {;}
| id {;}
| exp exp op_atrib {;};
%%

main () 
{
	yyparse ();
}
yyerror (s) /* Called by yyparse on error */
	char *s;
{
	printf ("Problema com a analise sintatica!\n");
}