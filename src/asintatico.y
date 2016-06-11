/* Verificando a sintaxe de programas segundo nossa GLC-exemplo */
/* considerando notacao polonesa para expressoes */
%{
#include <stdio.h>
#include <string.h>
#include "src/vector.h"
#define ERRO_UNDEF "nao declarado"
#define WRNG_NUSED "nao usado"
#define ERROR_2DEF "declarado mais de uma vez"

#define SINTATICAMENTE_CORRETO "O programa esta sintaticamente correto"
#define SEMANTICAMENTE_CORRETO "O programa esta semanticamento correto"
//RO INSTRUCTIONS
//RO r,s,t
#define HALT "HALT"
#define IN "IN"
#define OUT "OUT"
#define ADD "ADD"
#define SUB "SUB"
#define MUL "MUL"
#define DIV "DIV"
//RM INSTRUCTIONS
//RM r,d(s)
#define LD "LD"
#define LDA "LDA"
#define LDC "LDC"
#define ST "ST"
#define JLT "JLT"
#define JLE "JLE"
#define JGE "JGE"
#define JGT "JGT"
#define JEQ "JEQ"
#define JNE "JNE"

#define ac 0
#define ac1 1
#define gp 5
#define mp 6
#define pcreg 7
extern yylineno;
int cont_declr_var_linha = 0;
int cont_declr_tot = 0;
int instruction_counter = 0;
int memoffset = 0;
int need = 0;
FILE *intermediario;
typedef struct _simbolo{
	char id[9];
	char tipo[6];
	int declarado;
	int usado;
	char kind[6];
	int linha;
}Simbolo;
vector_p TS;
vector_p expres;
//CRIACAO DE CODIGO
void do_popExpression(int need);
void do_popVAR(char* id);
void storeVAR(char *id);
void loadVAR(char *id);
void emitRO(char* opcode, int r, int s, int t);
void emitRM(char* opcode, int r, int offset, int s);
//TABELA DE SIMBOLOS MANAGER
void cria_Simbolo(char* id,char* kind);
void insereTS(Simbolo s);
int busca_Simbolo(char *name, char *kind);
//REPORTS
void report(int sint_erro);
//
//
void emitRO(char* opcode, int r, int s, int t)
{
	fprintf(intermediario,"%3d: %5s %d,%d,%d\n",instruction_counter++,opcode,r,s,t);
}
void emitRM(char* opcode, int r, int offset, int s)
{
	fprintf(intermediario,"%3d: %5s %d,%d(%d)\n",instruction_counter++,opcode,r,offset,s);
}
void storeVAR(char *id)
{
	int posicao = busca_Simbolo(id,"var");
	if(posicao!=-1)
	{
		Simbolo *s = (Simbolo *)vector_get(TS,posicao);
		emitRM(LD,ac,++memoffset,mp);
		emitRM(ST,ac,posicao,gp);
	}
}

void do_popVAR(char* id)
{
	if(expres->length>0)
	{
		int *i = (int*)vector_get(expres,expres->length-1);
		emitRM(LDC,ac,*i,0);
	}
}
void do_popExpression(int need)
{
	if(need<=2)
	{
		int *i;
		if(expres->length>1)
		{
			i = (int*)vector_get(expres,expres->length-1);
			emitRM(LDC,ac,*i,0);
			i = NULL;
			vector_remove(expres,expres->length-1);
		}
		emitRM(ST,ac,memoffset--,mp);
		emitRM(LD,ac1,++memoffset,mp);
		if(expres->length>0)
		{
			i = (int*)vector_get(expres,expres->length-1);
			emitRM(LDC,ac,*i,0);
			i=NULL;
			vector_remove(expres,expres->length-1);
		}
	}
	else
	{
		emitRM(LD,ac,++memoffset,mp);
		emitRM(LD,ac1,++memoffset,mp);
		need=0;
	}
}

void loadVAR(char* id)
{
	int posicao = busca_Simbolo(id,"var");
	Simbolo *s = (Simbolo *)vector_get(TS,posicao);
	emitRM(LD,ac,posicao,gp);
}

void insereTS(Simbolo s)
{
	vector_add(TS,(void*)&s,sizeof(Simbolo));
}

void cria_Simbolo(char * id,char *kind)
{
	int posicao = busca_Simbolo(id,kind);
	if(posicao==-1) //Adiciona na lista
	{
		if(strcmp(kind,"var")==0)
			cont_declr_var_linha++;
		else
			cont_declr_tot++;
		Simbolo s;
		strcpy(s.tipo,"undef");
		strcpy(s.id,id);
		strcpy(s.kind,kind);
		s.declarado = 1;
		s.usado = 0;
		s.linha = yylineno;
		insereTS(s);
	}
	else //Se ja existe marca que foi declarado mais de uma vez
	{
		Simbolo *s = (Simbolo*)vector_get(TS,posicao);
		s->declarado++;
	}
}

void marcausado_Simbolo(char* id, char *kind)
{
	int posicao = busca_Simbolo(id,kind);
	if(posicao == -1) //Se o simbolo nao existe fala que foi usado sem declarar
	{
		Simbolo s;
		strcpy(s.id,id);
		strcpy(s.kind,kind);
		strcpy(s.tipo,"undef");
		s.declarado = 0;
		s.usado = 1;
		s.linha = yylineno;
		cont_declr_tot++;
		insereTS(s);
	}
	else //Se ja existe marca usado
	{
		Simbolo *s = (Simbolo *)vector_get(TS,posicao);
		s->usado = 1;
	}
}

int busca_Simbolo(char *name,char *kind)
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
char *operador;
int inum;
}

%token <cadeia> ID
%token <inum> INTEIRO
%token PRINT
%token READ
%token ASSIGN
%token <operador>OADD
%token <operador>OMULT
%token <operador>REL
%token RPT
%token IF
%nonassoc IFX
%nonassoc ELSE
%token DEL_BLOCO_ABRE
%token DEL_BLOCO_FECHA
%token <tipo> TIPO

%%
/* Regras definindo a GLC e acoes correspondentes */
programa:
	lista_declaracao {;};

lista_declaracao:
	declaracao {;}
	| lista_declaracao declaracao {;};

declaracao:
	declaracao_var {;}
	| declaracao_fun {;};

declaracao_var:
	TIPO lista_declaracao_var 
	{
		cont_declr_tot += cont_declr_var_linha;
		int i=0;
		for(i=0;i<cont_declr_var_linha;i++) //update variavel com seu tipo
		{
			Simbolo *s = (Simbolo*)vector_get(TS,cont_declr_tot - i - 1);
			strcpy(s->tipo,$TIPO);
		}
		cont_declr_var_linha = 0;
	};

lista_declaracao_var: 
	ID ';' 
	{
		cria_Simbolo($ID,"var");
	}
	| ID ',' lista_declaracao_var 
	{
		cria_Simbolo($ID,"var");
	};

declaracao_fun:
	ID '('')'
	{
		cria_Simbolo($ID,"fun");
	} cmpst_statement{;};

cmpst_statement:
	DEL_BLOCO_ABRE lista_statement DEL_BLOCO_FECHA{;};

lista_statement:
	statement {;}
	| statement lista_statement {;};

statement:
	exp_statement {;}
	| sel_statement {;}
	| rpt_statement {;}
	| print_statement {;}
	| read_statement {;}
	| cmpst_statement {;};

print_statement:
	PRINT '(' exp ')' ';' 
	{
//		emitRO(OUT,ac,0,0);
//		emitRM(LD,ac,++memoffset,mp);
	};

read_statement:
	READ '(' ID ')' ';'
	{
		marcausado_Simbolo($ID,"var");
//		insereVAR($ID);
//		emitRO(IN,ac,0,0);
//		storeVAR($ID);
	};

sel_statement:
	IF '(' exp ')' statement %prec IFX{;} 
	| IF '(' exp ')' statement ELSE statement {;};

rpt_statement:
	RPT '(' exp ')' statement {;};

exp_statement:
	exp ';' {;};

exp:
	ID ASSIGN exp
	{
		marcausado_Simbolo($ID,"var");
//		storeVAR($ID);
	}
	| exp_simples {;};

exp_simples:
	exp_add REL exp_add {;}
	| exp_add
	{
		//guarda o resultado da expressao num temporario
//		emitRM(ST,ac,memoffset--,mp);
	};

exp_add:
	exp_add OADD term
	{
//		do_popExpression(need);
//		if(strcmp($OADD,"+")==0)
//		{
//			emitRO(ADD,ac,ac1,ac);
//		}
//		else
//		{
//			emitRO(SUB,ac,ac1,ac);
//		}
	}
	| term {;};

term:
	term OMULT fator
	{
//		do_popExpression(need);
//		if(strcmp($OMULT,"*")==0)
//		{
//			emitRO(MUL,ac,ac1,ac);
//		}
//		else
//		{
//			emitRO(DIV,ac,ac1,ac);
//		}
	}
	| fator {;};

fator:
	'(' exp ')'
	{
		//need++;
	}
	| call {;}
	| ID
	{
		marcausado_Simbolo($ID,"var");
		//loadVAR($ID);
	}
	| INTEIRO
	{
//		int num = $INTEIRO;
//		vector_add(expres,(void*)&num,sizeof(int));
	};

call:
	ID '('')' 
	{
		//printf("Chamando funcao %s\n",$id);
		marcausado_Simbolo($ID,"fun");
	};
%%
extern FILE *yyin;
int main (int argc, char *argv[]) 
{
	int sint_erro;
	if(argc < 2)
	{
		perror("Too few argc\n");
		return -1;
	}
	TS = create_vector();
	expres = create_vector();
	yyin = fopen(argv[1],"r");
	intermediario = fopen("a.tm","w");
	if(yyin)
	{
		emitRM(LD,6,0,0);
		emitRM(ST,0,0,0);
		sint_erro = yyparse();
	}
	report(sint_erro);
	destroy_vector(TS);
	destroy_vector(expres);
	return 0;
}

void report(int sint_erro)
{
	int erros;
	if(!sint_erro)
		printf("%s\n",SINTATICAMENTE_CORRETO);
	int i = 0;
	for(i=0;i<TS->length;i++)
	{
		Simbolo *s = (Simbolo*)vector_get(TS,i);
		if(!s->declarado)
		{
			erros++;
			printf("[l.%d] ERROR : %s %s\n",s->linha,s->id,ERRO_UNDEF);
		}
		else
		{
			if(s->declarado>1)
			{
				erros++;
				printf("[l.%d] ERROR : %s %s\n",s->linha,s->id,ERROR_2DEF);
			}
			if(!s->usado && strcmp(s->id,"main"))
			{
				printf("[l.%d] WARNING: %s %s\n",s->linha,s->id,WRNG_NUSED);
			}
		}
	}
	
	printf("----REPORT SEMANTICO----\nPrograma com %d linhas\nHouveram %d declaracoes\nHouveram %d erros\n",yylineno-1,cont_declr_tot,erros);
	printf("KIND\tTIPO\tID\tDECLARADO\tUSADO\tLINHA\n");
	for(i=0;i<TS->length;i++)
	{
		Simbolo *s = (Simbolo*)vector_get(TS,i);
		printf("%s\t%s\t%s\t%d\t\t%d\t%d\n",s->kind,s->tipo,s->id,s->declarado,s->usado,s->linha);
	}
	if(!erros)
	{
		printf("%s\n",SEMANTICAMENTE_CORRETO);
		//emitRO(HALT,0,0,0);
	}
}

yyerror (s) /* Called by yyparse on error */
{
	printf ("Problema com a analise sintatica!\n");
}
