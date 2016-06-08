%option noyywrap
%option yylineno
%{
#include "asintatico.tab.h"
%}
%%

("abre"|"{")							{return del_bloco_abre;}
("fecha"|"}")							{return del_bloco_fecha;}
("int")									{yylval.tipo= (char *) strdup(yytext);return tipo;}
("while")								{return op_rpt;}
("print")								{return PRINT;}
("read")								{return READ;}
("if")									{return op_if;}
("else")								{return op_else;}
("<-"|"=")								{yylval.operador = (char*) strdup(yytext);return op_atrib;}
("+"|"-")								{yylval.operador = (char*) strdup(yytext);return op_add;}
("*"|"/")								{yylval.operador = (char*) strdup(yytext);return op_mult;}
("<"|">"|"=="|">="|"<="|"!=")			{return op_relacional;}
[a-z]{1,8} 								{yylval.cadeia= (char *) strdup(yytext);return id;}
[0-9]+									{yylval.inum = atoi(yytext);return inteiro;}
[ \n\t\r]+								{;}
.										{return yytext[0];}

%%
