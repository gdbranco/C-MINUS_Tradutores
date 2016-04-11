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
programa: del_bloco_abre lista_cmds del_bloco_fecha {;}
| variaveis del_bloco_abre lista_cmds del_bloco_fecha {;};

variaveis: var del_bloco_abre lista_decl_var del_bloco_fecha {;};

lista_decl_var: declaracao_var {;}
| declaracao_var ';' lista_decl_var {;};

declaracao_var: tipo id {;}
| tipo id exp_atrib {;};

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
