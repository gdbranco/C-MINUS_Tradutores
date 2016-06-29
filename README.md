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

Exemplo de saída gerado em TM:
```
* PRELUDIO
  0:    LD 6,0(0)
  1:    ST 0,0(0)
* START PROGRAM
  2:    IN 0,0,0
  3:   LDA 4,0(0)
  4:   LDA 0,0(4)
  5:   LDA 1,0(0)
  6:   LDC 0,0(0)
  7:   SUB 0,0,1
  8:   JLT 0,2(7)
  9:   LDC 0,0(0)
 10:   LDA 7,1(7)
 11:   LDC 0,1(0)
 13:   LDC 0,1(0)
 14:   LDA 3,0(0)
 15:   LDC 0,0(0)
 16:   LDA 1,0(0)
 17:   LDA 0,0(4)
 18:   SUB 0,0,1
 19:   JNE 0,2(7)
 20:   LDC 0,0(0)
 21:   LDA 7,1(7)
 22:   LDC 0,1(0)
 24:   LDA 0,0(4)
 25:   LDA 1,0(0)
 26:   LDA 0,0(3)
 27:   MUL 0,0,1
 28:   LDA 3,0(0)
 29:   LDC 0,1(0)
 30:   LDA 1,0(0)
 31:   LDA 0,0(4)
 32:   SUB 0,0,1
 33:   LDA 4,0(0)
 23:   JEQ 0,11(7)
 34:   LDA 7,-20(7)
 35:   LDA 0,0(3)
 36:   OUT 0,0,0
 12:   JEQ 0,24(7)
* STOP
 37:  HALT 0,0,0
```
