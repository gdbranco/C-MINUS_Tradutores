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

%%
/* Regras definindo a GLC e acoes correspondentes */
/* neste nosso exemplo quase todas as acoes estao vazias */
input: /* empty */
| input line;

line:'\n'
| programa '\n'  { printf ("Programa sintaticamente correto!\n"); };

programa: del_bloco_abre lista_cmds del_bloco_fecha {;};

lista_cmds:	cmd	{;}
| cmd ';' lista_cmds {;};

cmd: id exp_atrib {;}
| declaracao {;};

exp_atrib: op_atrib exp {;}

exp: flutuante {;}
| id {;}
| exp op_arit exp {;}
| relacao {;}; 

relacao: exp op_relacional exp {;}

declaracao: tipo id {;}
| tipo id exp_atrib {;};
%%

void file_string(char* arquivo)
{
	FILE* fp;
	fp = fopen(arquivo,"r");
	if(fp)
	{
		const size_t line_size = 300;
		char* line = malloc(line_size);
		while (fgets(line, line_size, fp) != NULL)
		{
	    		func(line);
		}
		free(line);    // dont forget to free heap memory
	}
}

int main (int argc, char *argv[]) 
{
	if(argc < 2)
	{
		perror("Too few argc\n");
		return -1;
	}
	file_string(argv[1]);
	return 0;
}
yyerror (s) /* Called by yyparse on error */
	char *s;
{
	printf ("Problema com a analise sintatica!\n");
}
