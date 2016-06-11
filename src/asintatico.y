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
//INSTRUCTIONS TYPE
#define RO 0
#define RM 1
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
vector_p TS;
vector_p Instruction_list;
FILE *intermediario;
typedef struct _instruction{
	char op[5];
	int kind;
	int r;
	int s;
	int t;
}Instruction;
Instruction cria_Instruction(int kind,char *op , int r, int s, int t);
Instruction cria_Instruction(int kind, char *op, int r, int s, int t)
{
	Instruction i;
	i.kind = kind;
	strcpy(i.op,op);
	i.r = r;
	i.s = s;
	i.t = t;
	return i;
}
typedef struct _simbolo{
	char id[9];
	char tipo[6];
	int declarado;
	int usado;
	char kind[6];
	int linha;
}Simbolo;
void cria_Simbolo(char* id,char* kind);
//CRIACAO DE CODIGO
void do_popExpression(int need);
void storeVAR(char *id);
void loadVAR(char *id);
void emitInstruction(Instruction inst);
//TABELA DE SIMBOLOS MANAGER
void insereTS(Simbolo s);
int busca_Simbolo(char *name, char *kind);
//REPORTS
void report(int sint_erro);
//
//
void emitInstruction(Instruction inst)
{
	switch(inst.kind)
	{
		default:
			break;
		case RO:
			fprintf(intermediario,"%3d: %5s %d,%d,%d\n",instruction_counter++,inst.op,inst.r,inst.s,inst.t);
			break;
		case RM:
			fprintf(intermediario,"%3d: %5s %d,%d(%d)\n",instruction_counter++,inst.op,inst.r,inst.t,inst.s);
			break;
	}
}
void storeVAR(char *id)
{
	int posicao = busca_Simbolo(id,"var");
	if(posicao!=-1)
	{
		Simbolo *s = (Simbolo *)vector_get(TS,posicao);
		Instruction i = cria_Instruction(RM,ST,ac,gp,posicao);
		emitInstruction(i);
	}
}

void do_popExpression(int need)
{
	if(need<=2)
	{
		Instruction *i;
		if(Instruction_list->length>1)
		{
			i = (Instruction*)vector_get(Instruction_list,Instruction_list->length-1);
			emitInstruction(*i);
			i = NULL;
			vector_remove(Instruction_list,Instruction_list->length-1);
		}
		emitInstruction(cria_Instruction(RM,ST,ac,mp,memoffset--));
		emitInstruction(cria_Instruction(RM,LD,ac1,mp,++memoffset));
		if(Instruction_list->length>0)
		{
			i = (Instruction*)vector_get(Instruction_list,Instruction_list->length-1);
			emitInstruction(*i);
			i=NULL;
			vector_remove(Instruction_list,Instruction_list->length-1);
		}
	}
	else
	{
//		emitRM(LD,ac,++memoffset,mp);
//		emitRM(LD,ac1,++memoffset,mp);
		need=0;
	}
}

void loadVAR(char* id)
{
	int posicao = busca_Simbolo(id,"var");
	Simbolo *s = (Simbolo *)vector_get(TS,posicao);
	Instruction inst = cria_Instruction(RM,LD,ac,gp,posicao);
	vector_add(Instruction_list,(void*)&inst,sizeof(Instruction));
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
		emitInstruction(cria_Instruction(RO,OUT,ac,0,0));
	};

read_statement:
	READ '(' ID ')' ';'
	{
		marcausado_Simbolo($ID,"var");
		emitInstruction(cria_Instruction(RO,IN,ac,0,0));
		storeVAR($ID);
	};

sel_statement:
	IF '(' exp ')' statement %prec IFX{;} 
	| IF '(' exp ')' statement ELSE statement {;};

rpt_statement:
	RPT '(' exp ')' statement {;};

exp_statement:
	exp ';'{;};

exp:
	ID {marcausado_Simbolo($ID,"var");} ASSIGN exp
	{
		if(Instruction_list->length==1)
		{
			Instruction *i = (Instruction*)vector_get(Instruction_list,Instruction_list->length-1);
			emitInstruction(*i);
			vector_remove(Instruction_list,Instruction_list->length-1);
		}
		storeVAR($ID);
	}
	| exp_simples {;};

exp_simples:
	exp_add REL exp_add {;}
	| exp_add {;};

exp_add:
	exp_add OADD term
	{
		do_popExpression(need);
		if(strcmp($OADD,"+")==0)
		{
			emitInstruction(cria_Instruction(RO,ADD,ac,ac1,ac));
		}
		else
		{
			emitInstruction(cria_Instruction(RO,SUB,ac,ac1,ac));
		}
	}
	| term {;};

term:
	term OMULT fator
	{
		do_popExpression(need);
		if(strcmp($OMULT,"*")==0)
		{
			emitInstruction(cria_Instruction(RO,MUL,ac,ac1,ac));
		}
		else
		{
			emitInstruction(cria_Instruction(RO,DIV,ac,ac1,ac));
		}
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
		loadVAR($ID);
	}
	| INTEIRO
	{
		Instruction inst = cria_Instruction(RM,LDC,ac,0,$INTEIRO);
		vector_add(Instruction_list,(void*)&inst,sizeof(Instruction));
	};

call:
	ID '('')'
	{
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
	Instruction_list = create_vector();
	yyin = fopen(argv[1],"r");
	intermediario = fopen("a.tm","w");
	if(yyin)
	{
		emitInstruction(cria_Instruction(RM,LD,6,0,0));
		emitInstruction(cria_Instruction(RM,ST,0,0,0));
		sint_erro = yyparse();
	}
	report(sint_erro);
	destroy_vector(TS);
	destroy_vector(Instruction_list);
	return 0;
}

void report(int sint_erro)
{
	int erros = 0;
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
		emitInstruction(cria_Instruction(RO,HALT,0,0,0));
	}
}

yyerror (s) /* Called by yyparse on error */
{
	printf ("Problema com a analise sintatica!\n");
}
