# Note: This needs to be fixed to make inside rgl2 too, if necessary

CPPFLAGS= $(INCLUDES:%=-I%)
LDFLAGS = $(LIBRARIES:%=-L%)
LDLIBS	= -lrgl $(USED_TOOLS:%=-l%)

MAIN_DIR 	= /home/kyrozier/research/source
RGL_DIR		= $(MAIN_DIR)/rgl2/include
RGL_LIB		= $(MAIN_DIR)/rgl2
RGL_OBJ		= $(MAIN_DIR)/rgl2/objs

INCLUDES	= $(RGL_DIR) $(RGL_OBJ)
LIBRARIES	= $(RGL_LIB) 


MODULES_C =\
	astar\
	bheap\
	conf\
	fbheap\
	fast_union\
	graph\
	graphalg\
	graphreachable\
	graphtriangulation\
	kdtree\
	knn\
	kpartition\
	lexset\
	matrix\
	prime\
	random\
	set\
	setop\
	serial\
	serial_ds

MY_MODULES =\
	KItem\
	KList\
	PANDA\
	lex.yy\
	y.tab

OBJS = $(MODULES_C:%=${RGL_OBJ}/%.o)
MY_OBJS = $(MY_MODULES:%=%.o)

PANDA: yacc lex
	g++ -c ${CPPFLAGS} lex.yy.c y.tab.c KItem.cc KList.cc PANDA.cpp 
	g++ ${CPPFLAGS} ${LDFLAGS} ${LDLIBS} ${OBJS} ${MY_OBJS} -o PANDA -lfl
	#g++ lex.yy.c y.tab.c KItem.cc KList.cc PANDA.cpp -o PANDA -lfl -ly

lex:
	lex lexLTL.cc
	#gcc lex.yy.c -lfl -o my_lexer
	#g++ -c lex.yy.c -o lex.yy.o

yacc:
	yacc -d yaccLTL.cc
	#-d specifies creation of y.tab.h
	#g++ -c y.tab.c -o y.tab.o

parser: lex yacc
	g++  lex.yy.c y.tab.c parsetest.cc -o parser -lfl

clean:
	rm ./*.o lex.yy.c y.tab.c
