%option noyywrap
%{
#include "asintatico.tab.h"
%}

/*id 				[a-z]{1,8}
digito 			[0-9]
flutuante 		{digito}+("."){digito}*|{digito}*("."){digito}+
op_atrib 		("<-")
op_arit 		("+"|"/"|"*")
op_relacional 	("<"|">")
del_bloco_abre  ("abre")
del_bloco_fecha ("fecha")
branco 			[ \n\t\r]+
etc 			.*
*/
%%

("abre")	                            {return del_bloco_abre;}
("fecha")                               {return del_bloco_fecha;}
("int"|"float"|"char")                  {return tipo;}
[a-z]{1,8} 			                    {return id;}
[0-9]+(".")[0-9]*|[0-9]*(".")[0-9]+ 	{return flutuante;}
("<-") 		                            {return op_atrib;}
("+"|"/"|"*") 		                    {return op_arit;}
("<"|">")                               {return op_relacional;}
[ \t\r]+		                        {;}
.|\n		                            {return yytext[0];}

%%
