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

/*
 *  Add Your own definitions here
 */

int comment_depth = 0;
%}

/*
 * Define names for regular expressions here.
 */

DARROW          =>
LE              <=
ASSIGN          <-

CLASS           ?i:class
ELSE            ?i:else
FI              ?i:fi
IF              ?i:if
IN              ?i:in
INHERITS        ?i:inherits
LET             ?i:let
LOOP            ?i:loop
POOL            ?i:pool
THEN            ?i:then
WHILE           ?i:while
CASE            ?i:case
ESAC            ?i:esac
OF              ?i:of
NEW             ?i:new
ISVOID          ?i:isvoid
NOT             ?i:not
INT_CONST       [0-9]+
TRUE            t(?i:rue)
FALSE           f(?i:alse)
BOOL_CONST      t[rR][uU][eE]|f[aA][lL][sS][eE]
TYPEID          [A-Z][a-zA-Z0-9_]*
OBJECTID        [a-z][a-zA-Z0-9_]*
WHITESPACE      [ \f\r\t\v]+
NEWLINE         \n
SYMBOL          [+/\-*=<.~,;:()@{}]
STR_CONST       \"[^"\n]*\"
COMMENTL  "(*"
COMMENTR  "*)"
COMMENTN  --

%x COMMENT STRING ENDSTRING

%%
 /*
  *  Nested comments
  */

<INITIAL,COMMENT>{COMMENTL} {
    comment_depth++;
    BEGIN(COMMENT);
}

<COMMENT>{COMMENTR} {
    comment_depth--;
    if (comment_depth == 0) {
        BEGIN(INITIAL);
    }
}

<COMMENT><<EOF>> {
    BEGIN(INITIAL);
    cool_yylval.error_msg = "EOF in comment";
    return(ERROR);
}

<INITIAL>{COMMENTR} {
    cool_yylval.error_msg = "Unmatched *)";
    return(ERROR);
}

<COMMENT>\n { curr_lineno++; }
<COMMENT>. { }
{COMMENTN}.*\n        { curr_lineno++; }  /* discard line */
{COMMENTN}.*          { curr_lineno++; }  /* discard line */

 /*
  *  The multiple-character operators.
  */
{DARROW}        { return (DARROW); }
{LE}            { return (LE); }
{ASSIGN}        { return (ASSIGN); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
{CLASS}         { return (CLASS); }
{ELSE}          { return (ELSE); }
{FI}            { return (FI); }
{IF}            { return (IF); }
{IN}            { return (IN); }
{INHERITS}      { return (INHERITS); }
{LET}           { return (LET); }
{LOOP}          { return (LOOP); }
{POOL}          { return (POOL); }
{THEN}          { return (THEN); }
{WHILE}         { return (WHILE); }
{CASE}          { return (CASE); }
{ESAC}          { return (ESAC); }
{OF}            { return (OF); }
{NEW}           { return (NEW); }
{ISVOID}        { return (ISVOID); }
{NOT}           { return (NOT); }
{WHITESPACE}    { }
{NEWLINE}       { curr_lineno++; }
{SYMBOL}        { return int(yytext[0]); }

{INT_CONST} {
    cool_yylval.symbol = inttable.add_string(yytext);
    return INT_CONST;
}

{TRUE} {
    cool_yylval.boolean = 1;
    return BOOL_CONST;
}

{FALSE} {
    cool_yylval.boolean = 0;
    return BOOL_CONST;
}

{BOOL_CONST} {
    for (int i = 0; yytext[i]; i++)
        yytext[i] = tolower(yytext[i]);
    if (strcmp("true", yytext) == 0) { cool_yylval.boolean = true; }
    else { cool_yylval.boolean = false; }
    return (BOOL_CONST);
}

{TYPEID} {
    cool_yylval.symbol = idtable.add_string(yytext);
    return(TYPEID);
}

{OBJECTID} {
    cool_yylval.symbol = idtable.add_string(yytext);
    return(OBJECTID);
}

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

\" {
    string_buf_ptr = string_buf;
    BEGIN(STRING);
}

<STRING>{
    \" { /* saw closing quote - all done */
        *string_buf_ptr = '\0';
        cool_yylval.symbol = stringtable.add_string(string_buf);
        BEGIN(INITIAL);
        return STR_CONST;
    }

    \\n {
        *string_buf_ptr++ = '\n';
	    if (string_buf_ptr == string_buf + MAX_STR_CONST) {
	        cool_yylval.error_msg = "String constant too long";
		    BEGIN(ENDSTRING);
	    }
	}

    \\t {
        *string_buf_ptr++ = '\t';
	    if (string_buf_ptr == string_buf + MAX_STR_CONST) {
	        cool_yylval.error_msg = "String constant too long";
		    BEGIN(ENDSTRING);
	    }
	}

    \\b {
     *string_buf_ptr++ = '\b';
	    if (string_buf_ptr == string_buf + MAX_STR_CONST) {
	        cool_yylval.error_msg = "String constant too long";
		    BEGIN(ENDSTRING);
	    }
	 }

	 \\f {
        *string_buf_ptr++ = '\f';
	    if (string_buf_ptr == string_buf + MAX_STR_CONST) {
	        cool_yylval.error_msg = "String constant too long";
		    BEGIN(ENDSTRING);
	    }
	}

    \\\0 {
        cool_yylval.error_msg = "String contains escaped null character";
        BEGIN(ENDSTRING);
    }

    \\[^ntbf\0] {
        *string_buf_ptr++ = yytext[1];
	    if (string_buf_ptr == string_buf + MAX_STR_CONST) {
	        cool_yylval.error_msg = "String constant too long";
		    BEGIN(ENDSTRING);
	    }
    }

    \0 {
        cool_yylval.error_msg = "String contains null character";
        BEGIN(ENDSTRING);
    }

    [^\\\n\"\0]+  {
        char *yptr = yytext;
    	while ( *yptr ) {
    	    *string_buf_ptr++ = *yptr++;
	        if (string_buf_ptr == string_buf + MAX_STR_CONST) {
	            cool_yylval.error_msg = "String constant too long";
		        BEGIN(ENDSTRING);
	        }
    	}
	}

    <STRING>\n {
	    curr_lineno++;
	    cool_yylval.error_msg = "Unterminated string constant";
	    BEGIN(INITIAL);
	    return ERROR;
    }

    <<EOF>> {
        cool_yylval.error_msg = "EOF in string constant";
        BEGIN(INITIAL);
        return ERROR;
    }
}

<ENDSTRING>[^\n\"]*\"? {
    BEGIN(INITIAL);
    return ERROR;
}

. {
    cool_yylval.error_msg = yytext;
    return ERROR;
}

%%