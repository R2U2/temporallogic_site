%option noyywrap
%{
/* This is a lexer for LTL formulas in in-fix order */
#include "y.tab.h"
#include <string.h>
  extern int yylex(); /*does this do anything?*/
%}
%%
[\t ]+       /*ignore whitespace*/ ;

&&        { 
  /*ECHO; /* normal default anyway */ 
    fprintf(stderr, "ERROR: Unrecognized symbol: %s\nTry &\n", yytext);
    exit(1);
}
&  { 
    /*fprintf(stderr, "%s is a logical operator\n", yytext);*/
    return AND;
   }
\|\|        { 
  /*ECHO; /* normal default anyway */ 
    fprintf(stderr, "ERROR: Unrecognized symbol: %s\nTry |\n", yytext);
    exit(1);
}
\| { 
    /*fprintf(stderr, "%s is a logical operator\n", yytext);*/
    return OR;
   }

~  { 
    /*fprintf(stderr, "%s is a logical operator\n", yytext);*/
    return NOT;
   }
-> { 
    /*fprintf(stderr, "%s is a logical operator\n", yytext);*/
    return IMPLIES;
   }

X  { 
    /*fprintf(stderr, "%s is a temporal operator\n", yytext);*/
    return NEXT;
   }
U  { 
    /*fprintf(stderr, "%s is a temporal operator\n", yytext);*/
    return UNTIL;
   }
R  { 
    /*fprintf(stderr, "%s is a temporal operator\n", yytext);*/
    return RELEASE;
   }
G  { 
    /*fprintf(stderr, "%s is a temporal operator\n", yytext);*/
    return GLOBALLY;
   }
F  { 
    /*fprintf(stderr, "%s is a temporal operator\n", yytext);*/
    return FUTURE;
   }

FALSE  { 
    /*fprintf(stderr, "%s is a boolean truth value\n", yytext);*/
    return FFALSE;
   }

TRUE  { 
  /*fprintf(stderr, "%s is a boolean truth value\n", yytext);*/
    return TTRUE;
   }

[a-zA-Z_0-9]+   { 
  /*fprintf(stderr, "%s is a variable\n", yytext);*/
  yylval.varName = (char *)malloc((strlen(yytext)+1)*sizeof(char));
  if (yylval.varName==NULL){ fprintf(stderr, "Memory error24\n"); exit(1); }
  /*copy in the variable name*/
  strcpy(yylval.varName, yytext);
  /*fprintf(stderr, "saved variable %s\n", yylval.varName);
    fprintf(stderr, "returning PROP\n");*/
  return PROP;
}

\( {
  /*fprintf(stderr, "Got '('\n");*/
  return LPAREN;
}

\) {
  /*fprintf(stderr, "Got ')'\n");*/
    return RPAREN;
  }

\n { /*This signifies the end of input*/ 
    return 0;}

.        { 
    ECHO; /* normal default anyway */ 
    fprintf(stderr, "ERROR: Unrecognized symbol: %s\n", yytext);
    exit(1);
}
%%

/*int main(void) {
    yylex();

    return 0;
} /*end main*/
