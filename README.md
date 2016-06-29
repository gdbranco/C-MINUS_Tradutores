# C-MINUS_Tradutores

Trabalho de tradutores para UnB, Universidade de Brasília, ministrado por Germana Nóbrega em 2016/1

O trabalho foi feito em trio:
* Diego Marques de Azevedo - 11/0027876
* Guilherme David Branco - 11/0012470
* Samuel Vinicius Vieira Pala - 11/0066120

Utiliza-se da biblioteca presente em [libds](https://github.com/zhemao/libds), pois o foco não esta nas estruturas de dados, mas sim na tradução e análises.

A gramática de referência utilizada pode ser acessada em [C-MINUS](http://www.sierranevada.edu/snow/ExamplesX/C-Syntax.pdf).

O compilador necessita de arquivos na linguagem C-MINUS-, extensão .c--, esta linguagem aceita somente variáveis globais e funções sem parâmetros(devido a finalidade de estudos).

Além da checagem sintática e semântica, têm-se também geração de código três endereços, na linguagem Tiny Machine, extensão .tm, este por sua vez deve ser executado na máquina tiny criada por Louden.

A linguagem tiny e tiny machine podem ser acessador por [Louden](http://www.cs.sjsu.edu/~louden/cmptext/) uma versão linux está presente neste repositório.

O programa pode ser compilado a partir do comando "make". O comando "make fclean" remove o que foi criado durante a compilação.

Para executar utilize o comando "g-- \<input_file\> \[\<output_file\>\]"

* \<output_file\> é opcional, caso não seja informado será utilizado o mesmo nome de \<input_file\> e extensão .tm

Possui as seguintes otimizações:
1.Manter temporários em registradores (ao invés de memória)
2.Manter variáveis em registradores (ao invés de memória)
3.Salto específico em comandos condicionais e de repetição
4.Utilizar comandos de reg ao inves de memoria para troca de dados do ac para ac1

Exemplo de código c--:
```c
/*Codigo linguagem c-- que computa o fatorial de um numero inteiro e positivo*/
int x,fat;
main ()
{
	read(x);
	if( 0 < x ) then
	{
		fat = 1;
		while(x != 0)
		{
			fat = fat * x;
			x= x-1;
		}
		print(fat);
	}
}
```
