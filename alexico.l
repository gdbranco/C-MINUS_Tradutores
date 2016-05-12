%option noyywrap
%option yylineno
%{
#include "asintatico.tab.h"
%}
%%

("abre"|"{")	                        {return del_bloco_abre;}
("fecha"|"}")                           {return del_bloco_fecha;}
("int"|"float"|"char"|"void")           {yylval.tipo= (char *) strdup(yytext);return tipo;}
("while")								{return op_rpt;}
("if")									{return op_if;}
("else")								{return op_else;}
("<-") 		                        	{return op_atrib;}
("+"|"-")	 		        			{return op_add;}
("/"|"*")								{return op_mult;}
("<"|">")                               {return op_relacional;}
[a-z]{1,8} 			        			{yylval.cadeia= (char *) strdup(yytext);return id;}
[0-9]+(".")*[0-9]*|[0-9]*(".")[0-9]+ 	{return flutuante;}
[ \n\t\r]+		                		{;}
.		                        		{return yytext[0];}

%%
