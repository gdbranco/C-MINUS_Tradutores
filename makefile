all: main clean

main:
	bison -d asintatico.y
	flex alexico.l
	gcc asintatico.tab.c lex.yy.c

clean:
	rm -rf *.o
	
fclean:
	rm -rf *.out
