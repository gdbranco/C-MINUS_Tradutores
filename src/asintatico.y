/* Verificando a sintaxe de programas segundo nossa GLC-exemplo */
/* considerando notacao polonesa para expressoes */
%{
#include <stdio.h>
#include <string.h>
#include "src/vector.h"
#define ERRO_UNDEF "nao declarado"
#define WRNG_NUSED "nao usado"

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
int erros = 0;
int instruction_counter = 0;
int memoffset = 0;
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
void do_popExpression();
void do_popVAR(char* id);
void storeVAR(char *id);
void loadVAR(char *id);
void insereVAR(char* id);
void insereTS(Simbolo s);
int nameinTS(char *name, char *kind);
int getIndexTS(Simbolo b);
void emitRO(char* opcode, int r, int s, int t);
void emitRM(char* opcode, int r, int offset, int s);
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
	insereVAR(id);
	int posicao = nameinTS(id,"var");
	if(posicao!=-1)
	{
		Simbolo *s = (Simbolo *)vector_get(TS,posicao);
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
	storeVAR(id);
}
void do_popExpression()
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

void loadVAR(char* id)
{
	insereVAR(id);
	int posicao = nameinTS(id,"var");
	Simbolo *s = (Simbolo *)vector_get(TS,posicao);
	emitRM(LD,ac,posicao,gp);
}

void insereVAR(char* id)
{
	int posicao = nameinTS(id,"var");
	if(posicao==-1)
	{
		Simbolo s;
		strcpy(s.id,id);
		strcpy(s.tipo,"undef");
		strcpy(s.kind,"var");
		s.linha = yylineno;
		s.declarado = 0;
		s.usado = 1;
		insereTS(s);
		cont_declr_tot++;
	}
	else
	{
		Simbolo *s = (Simbolo*) vector_get(TS,posicao);
		s->usado = 1;
	}
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
char *operador;
int inum;
}

%token <cadeia> id
%token <inum> inteiro
%token PRINT
%token READ
%token op_atrib
%token <operador>op_add
%token <operador>op_mult
%token <operador>op_relacional
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
		strcpy(s->tipo,$tipo);
		strcpy(s->kind,"var");
		s->declarado = 1;
		s->usado = 0;
		s->linha = yylineno;
	}
	cont_declr_var_linha = 0;
};

lista_declaracao_var: 
	id ';' 
	{
		cont_declr_var_linha++;
		Simbolo s;
		strcpy(s.id,$id);
		insereTS(s);
	}
	| id ',' lista_declaracao_var 
	{
		cont_declr_var_linha++;
		Simbolo s;
		strcpy(s.id,$id);
		insereTS(s);
	};

declaracao_fun: id '('')' {
		Simbolo s;
		strcpy(s.tipo,"undef");
		strcpy(s.id,$id);
		strcpy(s.kind,"fun");
		s.linha = yylineno;
		s.declarado = 1;
		s.usado = 0;
		cont_declr_tot++;
		insereTS(s);
	} cmpst_statement{;};

cmpst_statement: del_bloco_abre lista_statement del_bloco_fecha{;};

lista_statement: statement {;}
| statement lista_statement {;};

statement: exp_statement {;} 
| sel_statement {;}
| rpt_statement {;}
| print_statement {;}
| read_statement {;}
| cmpst_statement {;};

print_statement: PRINT '(' exp_simples ')' ';' 
{
	emitRO(OUT,ac,0,0);
};

read_statement: READ '(' id ')' ';'
{
	insereVAR($id);
	emitRO(IN,ac,0,0);
	storeVAR($id);
}

sel_statement: op_if '(' exp ')' statement %prec IFX{;} 
| op_if '(' exp ')' statement op_else statement {;};

rpt_statement: op_rpt '(' exp ')' statement {;};

exp_statement: exp ';' {;} ;

exp: id op_atrib exp
{
	do_popVAR($id);
}
| exp_simples {;};

exp_simples: exp_add op_relacional exp_add {;}
| exp_add {;};

exp_add: exp_add op_add term 
{
	do_popExpression();
	if(strcmp($op_add,"+")==0)
	{
		emitRO(ADD,ac,ac1,ac);
	}
	else
	{
		emitRO(SUB,ac,ac1,ac);
	}
}
| term {;};

term: term op_mult fator
{
	do_popExpression();
	if(strcmp($op_mult,"*")==0)
	{
		emitRO(MUL,ac,ac1,ac);
	}
	else
	{
		emitRO(DIV,ac,ac1,ac);
	}
}
| fator {;};

fator: '(' exp ')' {;}
| call {;}
| id {loadVAR($id);}
| inteiro 
	{
		int num = $inteiro;
		vector_add(expres,(void*)&num,sizeof(int));
	};

call: id '('')' 
{
	//printf("Chamando funcao %s\n",$id);
	int posicao = nameinTS($id,"fun");
	if(posicao==-1)
	{
		Simbolo s;
		strcpy(s.kind,"fun");
		strcpy(s.tipo,"undef");
		strcpy(s.id,$id);
		s.declarado = 0;
		s.usado = 1;
		s.linha = yylineno;
		insereTS(s);
		cont_declr_tot++;
	}
	else
	{
		Simbolo *s = vector_get(TS,posicao);
		s->usado = 1;
	}
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
	expres = create_vector();
	yyin = fopen(argv[1],"r");
	intermediario = fopen("a.tm","w");
	if(yyin)
	{
		emitRM(LD,6,0,0);
		emitRM(ST,0,0,0);
		erro = yyparse();
		if(!erro)
			printf("%s\n",SINTATICAMENTE_CORRETO);
		else
			erros++;
	}
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
		emitRO(HALT,0,0,0);
	}
	destroy_vector(TS);
	destroy_vector(expres);
	return 0;
}
yyerror (s) /* Called by yyparse on error */
{
	printf ("Problema com a analise sintatica!\n");
}
