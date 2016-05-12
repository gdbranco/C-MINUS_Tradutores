/* Verificando a sintaxe de programas segundo nossa GLC-exemplo */
/* considerando notacao polonesa para expressoes */
%{
#include <stdio.h>
#include <string.h>
#include "vector.h"
#define ERRO_VAR_UNDEF "Variavel nao declarada"

extern yylineno;
int cont_declr_var_linha = 0;
int cont_declr_tot = 0;
typedef struct _simbolo{
	char id[9];
	char tipo[6];
	int declarado;
	char kind[6];
	int linha;
}Simbolo;
vector_p TS;
void insereTS(Simbolo s);
void setTS(Simbolo s,size_t index);
int nameinTS(char *name, char *kind);
int getIndexTS(Simbolo b);
void setTS(Simbolo s, size_t index)
{
	vector_set(TS, index, (void*)&s,sizeof(Simbolo));
}
void insereTS(Simbolo s)
{
	vector_add(TS,(void*)&s,sizeof(Simbolo));
}
int getIndexTS(Simbolo b)
{
	return vector_index(TS,(void*)&b,sizeof(Simbolo));
}
int nameinTS(char *name,char *kind)
{
	int i=0;
	for(i=0;i<TS->length;i++)
	{
		Simbolo *s = (Simbolo*)vector_get(TS,i);
		if(strcmp(name,s->id)==0 && strcmp(s->kind,kind)==0)
		{
			return i;
		}
	}
	return -1;
}

%}
%union {
char *cadeia;
char *tipo;
float fnum;
int inum;
}

%token <cadeia> id
%token <fnum> flutuante
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
%token <tipo> tipo

%%
/* Regras definindo a GLC e acoes correspondentes */
programa: lista_declaracao {;};

lista_declaracao: declaracao {;}
| lista_declaracao declaracao {;};

declaracao: declaracao_var {;}
| declaracao_fun {;};

declaracao_var: tipo lista_declaracao_var 
{
	cont_declr_tot += cont_declr_var_linha;
	int i=0;
	for(i=0;i<cont_declr_var_linha;i++)
	{
		Simbolo *s = (Simbolo*)vector_get(TS,cont_declr_tot - i - 1);
		strcpy(s->tipo,$1);
		strcpy(s->kind,"var");
		s->declarado = 1;
		s->linha = yylineno;
		setTS(*s,cont_declr_tot - i - 1);
	}
	cont_declr_var_linha = 0;
};

lista_declaracao_var: 
	id ';' 
	{
		cont_declr_var_linha++;
		Simbolo s;
		strcpy(s.id,$1);
		insereTS(s);
	}
	| id ',' lista_declaracao_var 
	{
		cont_declr_var_linha++;
		Simbolo s;
		strcpy(s.id,$1);
		insereTS(s);
	};

declaracao_fun:
	tipo id '('')' cmpst_statement
	{
		Simbolo s;
		strcpy(s.tipo,$1);
		strcpy(s.id,$2);
		strcpy(s.kind,"fun");
		s.linha = -1;
		s.declarado = 1;
		cont_declr_tot++;
		insereTS(s);
	};

cmpst_statement: del_bloco_abre lista_statement del_bloco_fecha{;};

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

var: 
	id
	{
		Simbolo s;
		strcpy(s.id,$1);
		if(nameinTS($1,"var")==-1)
		{
			strcpy(s.tipo,"undef");
			strcpy(s.kind,"var");
			s.linha = yylineno;
			s.declarado = 0;
			insereTS(s);
		}
	};

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

call: 
	id '('')' 
	{
		Simbolo s;
		if(nameinTS($1,"fun")==-1)
		{
			strcpy(s.kind,"fun");
			strcpy(s.tipo,"undef");
			strcpy(s.id,$1);
			s.declarado = 0;
			s.linha = yylineno;
			insereTS(s);
		}
		printf("Utilizando id fun %s\n",$1);
	};
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
	TS = create_vector();
	yyin = fopen(argv[1],"r");
	if(yyin)
	{
		erro = yyparse();
		if(!erro)
			printf("PROGRAMA TA MASSA\n");
	}
	int i = 0;
	printf("----REPORT----\nPrograma com %d linhas\nHouveram %d declaracoes\n",yylineno-1,cont_declr_tot);
	printf("KIND\tTIPO\tID\tDECLARADO\tLINHA\n");
	for(i=0;i<TS->length;i++)
	{
		Simbolo *s = (Simbolo*)vector_get(TS,i);
		printf("%s\t%s\t%s\t%d\t\t%d\n",s->kind,s->tipo,s->id,s->declarado,s->linha);
	}
	destroy_vector(TS);
	return 0;
}
yyerror (s) /* Called by yyparse on error */
{
	printf ("Problema com a analise sintatica!\n");
}
