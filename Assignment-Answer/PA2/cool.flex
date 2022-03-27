/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

std::string stringbuff;
/*
 *  Add Your own definitions here
 */


%}

/*
 * Define names for regular expressions here.
 */
%x COMMENT
%x STR
%x STR_ESCAPE
CLASS [cC][lL][aA][sS][sS]
IF [iI][fF]
FI [fF][iI]
ELSE [eE][lL][sS][eE]
IN [iI][nN]
INHERITS [iI][nN][hH][eE][rR][iI][tT][sS]
ISVOID [iI][sS][vV][oO][iI][dD]
LET [lL][eE][tT]
LOOP [lL][oO][oO][pP]
POOL [pP][oO][oO][lL]
THEN [tT][hH][eE][nN]
WHILE [wW][hH][iI][lL][eE]
CASE [cC][aA][sS][eE]
ESAC [eE][sS][aA][cC]
NEW [nN][eE][wW]
OF [oO][fF]
NOT [nN][oO][tT]
TRUE [t][rR][uU][eE]
FALSE [f][aA][lL][sS][eE]

DARROW          =>
ASSIGN          <-
LE              <=

%%

[\[\]\!\#\?\'\>] {
  yylval.error_msg = yytext;
  return ERROR;
}

  /*
  * single line comment
  */
--.*        {}
 /*
  *  Nested comments
  */

"(*" {
  BEGIN(COMMENT);
}


<COMMENT>[^\*\)\n] {}
<COMMENT>[\n] {
  ++curr_lineno;
}
<COMMENT><<EOF>> {
  BEGIN(INITIAL);
  cool_yylval.error_msg = "EOF in comment";
  return ERROR;
}

<COMMENT>. {}

<COMMENT>"*)" {
  BEGIN(INITIAL);
}



<INITIAL>"*)" {
  cool_yylval.error_msg = "Unmatched *)";
  return ERROR;
}

\" {BEGIN(STR);}

<STR><<EOF>> {
  BEGIN(INITIAL);
  cool_yylval.error_msg = "EOF in string constant";
  return ERROR;
}

<STR>[\0] {
  BEGIN(INITIAL);
  cool_yylval.error_msg = "String contains null character";
  return ERROR;
}

<STR>[\n] {
  BEGIN(INITIAL);
  cool_yylval.error_msg = "Unterminated string constant";
  curr_lineno++;
  return ERROR;
}
<STR>\\ {
  BEGIN(STR_ESCAPE);
}

<STR_ESCAPE>n {
  stringbuff.append("\n");
  BEGIN(STR);
}

<STR_ESCAPE>b {
  stringbuff.append("\b");
  BEGIN(STR);
}

<STR_ESCAPE>t {
  stringbuff.append("\t");
  BEGIN(STR);
}

<STR_ESCAPE>b {
  stringbuff.append("\f");
  BEGIN(STR);
}

<STR_ESCAPE>0 {
  stringbuff.append("0");
  BEGIN(STR);
}

<STR>\" {
  BEGIN(INITIAL);
  char tmp[stringbuff.size()];
  strcpy(tmp, stringbuff.c_str());
  cool_yylval.symbol = stringtable.add_string(tmp);
  stringbuff.clear();
  return STR_CONST;
}

<STR>. {
  stringbuff.append(yytext);
}

 /*
  *  The multiple-character operators.
  */
\n          { ++curr_lineno;}
{DARROW}		{ return (DARROW); }
{ASSIGN}    { return (ASSIGN);}
{LE}        { return (LE);}
 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
{CLASS}     { return (CLASS);}
{IF}        { return (IF);}
{FI}        { return (FI);}
{ELSE}      { return (ELSE);}
{IN}        { return (IN);}
{INHERITS}  { return (INHERITS);}
{ISVOID}    { return (ISVOID);}
{LET}       { return (LET);}
{LOOP}      { return (LOOP);}
{POOL}      { return (POOL);}
{THEN}      { return (THEN);}
{WHILE}     { return (WHILE);}
{CASE}      { return (CASE);}
{ESAC}      { return (ESAC);}
{NEW}       { return (NEW);}
{OF}        { return (OF);}
{NOT}       { return (NOT);}


{TRUE} {
  cool_yylval.boolean = true;
  return BOOL_CONST;
}

{FALSE} {
  cool_yylval.boolean = false;
  return BOOL_CONST;
}
  /*
  *
  */

[A-Z][a-zA-Z_0-9]* {
  cool_yylval.symbol = idtable.add_string(yytext);
  return TYPEID;
}

[a-z][a-zA-Z_0-9]* {
  cool_yylval.symbol = idtable.add_string(yytext);
  return OBJECTID;
}

[0-9]+ {
  cool_yylval.symbol = inttable.add_string(yytext);
  return INT_CONST;
}

[\+\-\*\/\<\=\.\@\~\;\,\{\}\:\(\)] {return yytext[0];}

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

[ \t\f\r\v] {}
%%