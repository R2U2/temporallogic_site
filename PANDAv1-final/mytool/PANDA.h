/* PANDA.h

   Kristin Y. Rozier
   released: June, 2011

   Input: an LTL formula

   Output: a symbolic automaton (i.e. SMV model) of the input formula
*/

/*NOTE: For this parser, formulas MUST be enclosed within parens!!!*/

#ifndef PANDA_H
#define PANDA_H

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>

#include "KItem.h"
#include "KList.h"

/*Includes for Variable Ordering capabilities*/
#include "typedefs.h" /*rgl2: mcs_start_t*/
#include "graph.h"    /*rgl2: connect_graph() and alloc_graph()*/
#include "graphops.h" /*rgl2: mcs_graph()*/


/*A node in the parse tree*/
struct node {
    struct node *parent;
    char *me;
    int num; /*to use for numbering the nodes/subformulas*/
    struct node *left_kid;
    struct node *right_kid;
    bool temp_kid; /*does this node have a temporal operator as a decendant?*/
};


#ifndef ROOT
#define ROOT

/*Global Variables*/
extern struct node *root;     /*the root of the parse tree*/
extern size_t formula_length; /*the number of characters in the input formula*/
extern KList varList;         /*list of used variables to avoid repeats*/
extern graph_t var_graph;     /*rgl2-library style variable graph*/
extern int tiebreaker, sign;  /*rgl2-library flag variables*/

/*Operator Counters*/
/*  these are just for information, debugging*/
extern int numNonTemporalOps; /*how many &'s, |'s, and ->'s are in the input formula?*/
extern int numX;              /*how many X's are in the input formula?*/
extern int numU;              /*how many U's are in the input formula?*/
extern int numR;              /*how many R's are in the input formula?*/
extern int numG;              /*how many G's are in the input formula?*/
extern int numGF;             /*how many GF's are in the input formula? (These also get counted individually.)*/
extern int numF;              /*how many F's are in the input formula?*/
extern int numPROP;           /*how many times are props used in the input formula?*/
extern int numTRUE;           /*how many times is TRUE used in the input formula?*/
extern int numFALSE;          /*how many times is FALSE used in the input formula?*/

#endif


/*Required function definitions*/
void connect_graph(int from, int to);


#endif /*PANDA_H*/
