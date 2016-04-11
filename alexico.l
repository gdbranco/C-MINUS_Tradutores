%option noyywrap
%{
#include "asintatico.tab.h"
%}
%%

("variaveis")				{return var;}
("abre")	                        {return del_bloco_abre;}
("fecha")                               {return del_bloco_fecha;}
("int"|"float"|"char"|"void")                  {return tipo;}
[a-z]{1,8} 			        {return id;}
[0-9]+(".")*[0-9]*|[0-9]*(".")[0-9]+ 	{return flutuante;}
("<-") 		                        {return op_atrib;}
("+"|"/"|"*") 		                {return op_arit;}
("<"|">")                               {return op_relacional;}
[ \n\t\r]+		                {;}
.		                        {return yytext[0];}

%%
