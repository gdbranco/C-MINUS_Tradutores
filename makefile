all: main clean

main:
	bison -d -v asintatico.y
	flex alexico.l
	gcc asintatico.tab.c lex.yy.c vector.c vector.h

clean:
	rm -rf *.o
	
fclean:
	rm -rf *.out
