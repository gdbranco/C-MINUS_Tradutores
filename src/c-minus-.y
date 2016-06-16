/* Verificando a sintaxe de programas segundo nossa GLC-exemplo */

%{
#include <stdio.h>
#include <string.h>
#include "src/vector.h"

#define TRUE 1
#define FALSE 0

//DEFINICOES DA ANALISE
#define ERRO_UNDEF "nao declarado"
#define WRNG_NUSED "nao usado"
#define ERROR_2DEF "declarado mais de uma vez"
#define ERROR_SINTATICO "Problema com analise sintatica"
#define SINTATICAMENTE_CORRETO "O programa esta sintaticamente correto"
#define SEMANTICAMENTE_CORRETO "O programa esta semanticamento correto"
#define REPORT TRUE
#define REPORT_TM TRUE

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

//TINY MACHINE REGISTERS
#define ac 0
#define ac1 1
#define gp 5
#define mp 6
#define pcreg 7

int erros = 0;
int cont_declr_var_linha = 0;
int cont_declr_tot = 0;
int instruction_counter = 0;
int memoffset = 0;

extern yylineno;
extern FILE *yyin;
extern FILE *yyout;

vector_p TS;
vector_p ExpInstruction_list;
vector_p Location_stack;

typedef struct _instruction{
	char op[5];
	int kind;
	int r;
	int s;
	int t;
	int hasP;
}Instruction;

Instruction cria_Instruction(int kind,char *op , int r, int s, int t, int hasP);

Instruction cria_Instruction(int kind, char *op, int r, int s, int t, int hasP)
{
	Instruction i;
	i.kind = kind;
	strcpy(i.op,op);
	i.r = r;
	i.s = s;
	i.t = t;
	i.hasP = hasP;
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
void do_popExpression();
void storeVAR(char *id);
void loadVAR(char *id);
void emitInstruction(Instruction inst);
void emitComment(char *com);
void emitBackup();
int emitRestore();

//TABELA DE SIMBOLOS MANAGER
void insereTS(Simbolo s);
int busca_Simbolo(char *name, char *kind);

//REPORTS
void report(int sint_erro);
//
// Guarda posicao do pc reg
void emitBackup()
{
	vector_add(Location_stack,(void*)&instruction_counter,sizeof(int));
}

// Libera posicao pc reg
int emitRestore()
{
	int *i;
	i = (int*)vector_get(Location_stack,Location_stack->length-1);
	return *i;
}

void emitComment(char *com)
{
	fprintf(yyout,"* %s\n", com);
}
void emitInstruction(Instruction inst)
{
	switch(inst.kind)
	{
		default:
			break;
		case RO:
			fprintf(yyout,"%3d: %5s %d,%d,%d\n",instruction_counter++,inst.op,inst.r,inst.s,inst.t);
			break;
		case RM:
			fprintf(yyout,"%3d: %5s %d,%d(%d)\n",instruction_counter++,inst.op,inst.r,inst.t,inst.s);
			break;
	}
}

void storeVAR(char *id)
{
	int posicao = busca_Simbolo(id,"var");
	if(posicao!=-1)
	{
		Simbolo *s = (Simbolo *)vector_get(TS,posicao);
		Instruction i = cria_Instruction(RM,ST,ac,gp,posicao,FALSE);
		emitInstruction(i);
	}
}

// Checa na pilha se precisa pegar algum valor
void do_popExpression()
{
	Instruction *i;
	if(ExpInstruction_list->length>1)
	{
		i = (Instruction*)vector_get(ExpInstruction_list,ExpInstruction_list->length-1);
		if(i->hasP)
		{
			++memoffset;
		}
		emitInstruction(*i);
		i = NULL;
		vector_remove(ExpInstruction_list,ExpInstruction_list->length-1);
	}
	emitInstruction(cria_Instruction(RM,ST,ac,mp,memoffset--,FALSE));
	emitInstruction(cria_Instruction(RM,LD,ac1,mp,++memoffset,FALSE));
	if(ExpInstruction_list->length>0)
	{
		i = (Instruction*)vector_get(ExpInstruction_list,ExpInstruction_list->length-1);
		if(i->hasP)
			++memoffset;
		emitInstruction(*i);
		i=NULL;
		vector_remove(ExpInstruction_list,ExpInstruction_list->length-1);
	}
}

void loadVAR(char* id)
{
	int posicao = busca_Simbolo(id,"var");
	Simbolo *s = (Simbolo *)vector_get(TS,posicao);
	Instruction inst = cria_Instruction(RM,LD,ac,gp,posicao,FALSE);
	vector_add(ExpInstruction_list,(void*)&inst,sizeof(Instruction));
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
		s.declarado = TRUE;
		s.usado = FALSE;
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
		s.declarado = FALSE;
		s.usado = TRUE;
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
%token <operador>ASSIGN
%token <operador>OADD
%token <operador>OMULT
%token <operador>REL
%token RPT
%token IF
%token ELSE
%token THEN
%token DEL_BLOCO_ABRE
%token DEL_BLOCO_FECHA
%token <tipo> TIPO

%%
/* Regras definindo a GLC e acoes correspondentes */
programa:
	{if(REPORT_TM) emitComment("START PROGRAM");} lista_declaracao {;};

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
		free($TIPO);
	};

lista_declaracao_var: 
	ID ';' 
	{
		cria_Simbolo($ID,"var");
		free($ID);
	}
	| ID ',' lista_declaracao_var 
	{
		cria_Simbolo($ID,"var");
		free($ID);
	};

declaracao_fun:
	ID '('')'
	{
		cria_Simbolo($ID,"fun");
		free($ID);
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
		if(ExpInstruction_list->length)
		{
			Instruction *i = (Instruction*)vector_get(ExpInstruction_list,ExpInstruction_list->length-1);
			emitInstruction(*i);
			vector_remove(ExpInstruction_list,ExpInstruction_list->length-1);
		}
		emitInstruction(cria_Instruction(RO,OUT,ac,0,0,FALSE));
	};

read_statement:
	READ '(' ID ')' ';'
	{
		marcausado_Simbolo($ID,"var");
		emitInstruction(cria_Instruction(RO,IN,ac,0,0,FALSE));
		storeVAR($ID);
		free($ID);
	};

sel_statement:
	IF '(' exp ')' THEN {emitBackup();instruction_counter++;} statement
	{
		int i = instruction_counter;
		instruction_counter = emitRestore();
		vector_remove(Location_stack,Location_stack->length-1);
		emitInstruction(cria_Instruction(RM,JEQ,ac,pcreg,i - instruction_counter - 1,FALSE));
		instruction_counter = i;
	}
	| IF '(' exp ')'{emitBackup();instruction_counter++;} statement
	{
		int i = instruction_counter;
		instruction_counter = emitRestore();
		vector_remove(Location_stack,Location_stack->length-1);
		emitInstruction(cria_Instruction(RM,JEQ,ac,pcreg,i - instruction_counter,FALSE));
		instruction_counter = i;
	}
	ELSE {emitBackup();instruction_counter++;} statement
	{
		int i = instruction_counter;
		instruction_counter = emitRestore();
		vector_remove(Location_stack,Location_stack->length-1);
		emitInstruction(cria_Instruction(RM,LDA,pcreg,pcreg,i - instruction_counter - 1,FALSE));
		instruction_counter = i;
	};
rpt_statement:
	RPT {emitBackup();}'(' exp ')'{emitBackup();instruction_counter++;} statement 
	{
			int i = instruction_counter;
			instruction_counter = emitRestore();
			vector_remove(Location_stack,Location_stack->length-1);
			emitInstruction(cria_Instruction(RM,JEQ,ac,pcreg,i - instruction_counter,FALSE));
			instruction_counter = i;
			int aux;
			aux = emitRestore();
			vector_remove(Location_stack,Location_stack->length-1);
			emitInstruction(cria_Instruction(RM,LDA,pcreg,pcreg,aux-instruction_counter-1,FALSE));
	};

exp_statement:
	exp ';'{;}
	| ';' {;};

exp:
	ID {marcausado_Simbolo($ID,"var");} ASSIGN exp
	{
		if(ExpInstruction_list->length>=1)
		{
			Instruction *i = (Instruction*)vector_get(ExpInstruction_list,ExpInstruction_list->length-1);
			emitInstruction(*i);
			vector_remove(ExpInstruction_list,ExpInstruction_list->length-1);
		}
		storeVAR($ID);
		free($ID);
		free($ASSIGN);
	}
	| exp_simples {;};

exp_simples:
	exp_add REL exp_add
	{
		do_popExpression();
		if(strcmp($REL,"<")==0)
		{
			emitInstruction(cria_Instruction(RO,SUB,ac,ac,ac1,FALSE));
			emitInstruction(cria_Instruction(RM,JLT,ac,pcreg,2,FALSE));
			emitInstruction(cria_Instruction(RM,LDC,ac,ac,0,FALSE));
			emitInstruction(cria_Instruction(RM,LDA,pcreg,pcreg,1,FALSE));
			emitInstruction(cria_Instruction(RM,LDC,ac,ac,1,FALSE));
		}
		else if(strcmp($REL,">")==0)
		{
			emitInstruction(cria_Instruction(RO,SUB,ac,ac,ac1,FALSE));
			emitInstruction(cria_Instruction(RM,JGT,ac,pcreg,2,FALSE));
			emitInstruction(cria_Instruction(RM,LDC,ac,ac,0,FALSE));
			emitInstruction(cria_Instruction(RM,LDA,pcreg,pcreg,1,FALSE));
			emitInstruction(cria_Instruction(RM,LDC,ac,ac,1,FALSE));
		}
		else if(strcmp($REL,"<=")==0)
		{
			emitInstruction(cria_Instruction(RO,SUB,ac,ac,ac1,FALSE));
			emitInstruction(cria_Instruction(RM,JLE,ac,pcreg,2,FALSE));
			emitInstruction(cria_Instruction(RM,LDC,ac,ac,0,FALSE));
			emitInstruction(cria_Instruction(RM,LDA,pcreg,pcreg,1,FALSE));
			emitInstruction(cria_Instruction(RM,LDC,ac,ac,1,FALSE));
		}
		else if(strcmp($REL,">=")==0)
		{
			emitInstruction(cria_Instruction(RO,SUB,ac,ac,ac1,FALSE));
			emitInstruction(cria_Instruction(RM,JGE,ac,pcreg,2,FALSE));
			emitInstruction(cria_Instruction(RM,LDC,ac,ac,0,FALSE));
			emitInstruction(cria_Instruction(RM,LDA,pcreg,pcreg,1,FALSE));
			emitInstruction(cria_Instruction(RM,LDC,ac,ac,1,FALSE));
		}
		else if(strcmp($REL,"==")==0)
		{
			emitInstruction(cria_Instruction(RO,SUB,ac,ac,ac1,FALSE));
			emitInstruction(cria_Instruction(RM,JEQ,ac,pcreg,2,FALSE));
			emitInstruction(cria_Instruction(RM,LDC,ac,ac,0,FALSE));
			emitInstruction(cria_Instruction(RM,LDA,pcreg,pcreg,1,FALSE));
			emitInstruction(cria_Instruction(RM,LDC,ac,ac,1,FALSE));
		}
		else if(strcmp($REL,"!=")==0)
		{
			emitInstruction(cria_Instruction(RO,SUB,ac,ac,ac1,FALSE));
			emitInstruction(cria_Instruction(RM,JNE,ac,pcreg,2,FALSE));
			emitInstruction(cria_Instruction(RM,LDC,ac,ac,0,FALSE));
			emitInstruction(cria_Instruction(RM,LDA,pcreg,pcreg,1,FALSE));
			emitInstruction(cria_Instruction(RM,LDC,ac,ac,1,FALSE));
		}
		else if(strcmp($REL,"&&")==0)
		{
			emitInstruction(cria_Instruction(RO,MUL,ac,ac,ac1,FALSE));
			emitInstruction(cria_Instruction(RM,JNE,ac,pcreg,2,FALSE));
			emitInstruction(cria_Instruction(RM,LDC,ac,ac,0,FALSE));
			emitInstruction(cria_Instruction(RM,LDA,pcreg,pcreg,1,FALSE));
			emitInstruction(cria_Instruction(RM,LDC,ac,ac,1,FALSE));
		}
		else if(strcmp($REL,"||")==0)
		{
			emitInstruction(cria_Instruction(RO,ADD,ac,ac,ac1,FALSE));
			emitInstruction(cria_Instruction(RM,JNE,ac,pcreg,2,FALSE));
			emitInstruction(cria_Instruction(RM,LDC,ac,ac,0,FALSE));
			emitInstruction(cria_Instruction(RM,LDA,pcreg,pcreg,1,FALSE));
			emitInstruction(cria_Instruction(RM,LDC,ac,ac,1,FALSE));
		}
		else
		{
			if(REPORT_TM) emitComment("Undefined Expression");
		}
		Instruction inst = cria_Instruction(RM,LD,ac,mp,memoffset,TRUE); //Instrucao LD que deve ser inserida
		emitInstruction(cria_Instruction(RM,ST,ac,mp,memoffset,FALSE));
		memoffset--;
		vector_add(ExpInstruction_list,(void*)&inst,sizeof(Instruction));
		free($REL);
	}
	| exp_add {;};

exp_add:
	exp_add OADD term
	{
		do_popExpression();
		if(strcmp($OADD,"+")==0)
		{
			//ADD
			emitInstruction(cria_Instruction(RO,ADD,ac,ac,ac1,FALSE));
		}
		else
		{
			//SUB
			emitInstruction(cria_Instruction(RO,SUB,ac,ac,ac1,0));
		}
		
		// Guarda valores na pilha caso existam mais de dois operandos
		// Espera proximo operando para que trate os valores inseridos na pilha
		Instruction inst = cria_Instruction(RM,LD,ac,mp,memoffset,TRUE); //Instrucao LD que deve ser inserida
		emitInstruction(cria_Instruction(RM,ST,ac,mp,memoffset,FALSE));
		memoffset--;
		vector_add(ExpInstruction_list,(void*)&inst,sizeof(Instruction));
		free($OADD);
	}
	| term {;};

term:
	term OMULT fator
	{
		do_popExpression();
		if(strcmp($OMULT,"*")==0)
		{
			emitInstruction(cria_Instruction(RO,MUL,ac,ac,ac1,FALSE));
		}
		else
		{
			emitInstruction(cria_Instruction(RO,DIV,ac,ac,ac1,FALSE));
		}
		Instruction inst = cria_Instruction(RM,LD,ac,mp,memoffset,TRUE); //Instrucao LD que deve ser inserida
		emitInstruction(cria_Instruction(RM,ST,ac,mp,memoffset,FALSE));
		memoffset--;
		vector_add(ExpInstruction_list,(void*)&inst,sizeof(Instruction));
		free($OMULT);
	}
	| fator {;};

fator:
	'(' exp ')' {;}
	| call {;}
	| ID 
	{
		marcausado_Simbolo($ID,"var");
		loadVAR($ID);
		free($ID);
	}
	| INTEIRO
	{
		Instruction inst = cria_Instruction(RM,LDC,ac,0,$INTEIRO,FALSE);
		vector_add(ExpInstruction_list,(void*)&inst,sizeof(Instruction));
	};

call:
	ID '('')'
	{
		marcausado_Simbolo($ID,"fun");
		free($ID);
	};
%%
int main (int argc, char *argv[]) 
{
	int sint_erro;
	if(argc < 2)
	{
		perror("Uso: ./g-- <input_file> [<output_file>]\n");
		return -1;
	}
	TS = create_vector();
	ExpInstruction_list = create_vector();
	Location_stack = create_vector();
	char infile_name[100];
	char outfile_name[100];
	strcpy(infile_name,argv[1]);
	char *pch = strrchr(infile_name,'/');
	if(pch == NULL) strcpy(outfile_name,infile_name);
	else strcpy(outfile_name,pch+1);
	pch = strrchr(infile_name,'.');
	if(pch == NULL)	{strcat(infile_name,".c--");}
	else 
	{
		char aux[100] = "";
		strncpy(aux,outfile_name,strlen(outfile_name) - strlen(pch));
		strcpy(outfile_name,aux);
	}
	strcat(outfile_name,".tm");
	yyin = fopen(infile_name,"r");
	if(yyin)
	{
		if(argc < 3)
			yyout = fopen(outfile_name,"w");
		else
			yyout = fopen(argv[2],"w");
		if(REPORT_TM) emitComment("PRELUDIO");
		emitInstruction(cria_Instruction(RM,LD,6,0,0,FALSE));
		emitInstruction(cria_Instruction(RM,ST,0,0,0,FALSE));
		sint_erro = yyparse();
		report(sint_erro);
		if(REPORT_TM) emitComment("STOP");
		emitInstruction(cria_Instruction(RO,HALT,0,0,0,FALSE));
	}
	else
	{
		printf("Arquivo ""%s"" não existe\n",infile_name);
		return -1;
	}
	fclose(yyin);
	fclose(yyout);
	destroy_vector(TS);
	destroy_vector(ExpInstruction_list);
	destroy_vector(Location_stack);
	return 0;
}

void report(int sint_erro)
{
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
	
	if(REPORT)
	{
		printf("----REPORT SEMANTICO----\nPrograma com %d linhas\nHouve %d declr. \nHouve %d erro(s)\n",yylineno-1,cont_declr_tot,erros);
		printf("N instrucoes : %d\n",instruction_counter+1);
		printf("N memoffset : %d\n",memoffset);
		printf("KIND\tTIPO\tID\tDECLARADO\tUSADO\tLINHA\n");
		for(i=0;i<TS->length;i++)
		{
			Simbolo *s = (Simbolo*)vector_get(TS,i);
			printf("%s\t%s\t%s\t%d\t\t%d\t%d\n",s->kind,s->tipo,s->id,s->declarado,s->usado,s->linha);
		}
		if(!erros)
		{
			if(!sint_erro)
				printf("%s\n",SINTATICAMENTE_CORRETO);
			printf("%s\n",SEMANTICAMENTE_CORRETO);
		}
	}
}

yyerror (s) /* Called by yyparse on error */
{
	erros++;
	printf ("[l.%d] ERROR : %s\n",yylineno,ERROR_SINTATICO);
}
