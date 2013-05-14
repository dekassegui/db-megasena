/*
 * Math: power
 *
 * Math aggregation: product
 *
 * String: reverse, zeropad
 *
 * Bitwise: int2bin, bitstatus
 *
 * Bitwise aggregation: group_bitor, group_ndxbitor
 *
 * Miscellaneous: mask60, quadrante, datalocal, datefield
 *
 * Compile: gcc -fPIC -lm -shared more-functions.c -o more-functions.so
 *
 * Usage: .load "path_to_lib/more-functions.so"
 * or also for JDBC: select load_extension("path_to_lib/more-functions.so");
*/
#define COMPILE_SQLITE_EXTENSIONS_AS_LOADABLE_MODULE 1

#ifdef COMPILE_SQLITE_EXTENSIONS_AS_LOADABLE_MODULE
#include "sqlite3ext.h"
SQLITE_EXTENSION_INIT1
#else
#include "sqlite3.h"
#endif

#include <assert.h>
#include <string.h>
#include <stdint.h>

typedef uint8_t         u8;
typedef uint16_t        u16;
typedef int64_t         i64;

#include <math.h>
#include <errno.h>		/* LMH 2007-03-25 */

/*
 * Wraps the pow math.h function
*/

static void powerFunc(sqlite3_context *context, int argc, sqlite3_value **argv)
{
  double r1 = 0.0;
  double r2 = 0.0;
  double val;

  assert( argc==2 );

  if (sqlite3_value_type(argv[0]) == SQLITE_NULL
      || sqlite3_value_type(argv[1]) == SQLITE_NULL) {
    sqlite3_result_null(context);
  } else {
    r1 = sqlite3_value_double(argv[0]);
    r2 = sqlite3_value_double(argv[1]);
    errno = 0;
    val = pow(r1,r2);
    if (errno == 0) {
      sqlite3_result_double(context, val);
    } else {
      sqlite3_result_error(context, strerror(errno), errno);
    }
  }
}

/* estrutura de contexto Produtorio */
typedef struct ProductCtx ProductCtx;
struct ProductCtx {
  double rB;
};


static void group_productStep(sqlite3_context *context, int argc, sqlite3_value **argv)
{
  ProductCtx *p;
  double value = 0;
  assert( 1 == argc );
  p = sqlite3_aggregate_context(context, sizeof(*p));
  value = sqlite3_value_double(argv[0]);
  p->rB += log(value);
}

static void group_productFinalize(sqlite3_context *context)
{
  ProductCtx *p;
  double value = 0;
  p = sqlite3_aggregate_context(context, 0);
  value = exp(p->rB);
  sqlite3_result_double(context, value);
}

#include <limits.h>

#define I64_NBITS (sizeof(i64) * CHAR_BIT)

static char *int2bin(char *buf, i64 n)
{
  int i;
  char* t = buf + I64_NBITS;
  *t = '\0';
  for (i=I64_NBITS; i>0; i--, n >>= 1) *(--t) = (n & 1) + '0';
  return buf;
}

/*
 * Returns the binary representation string of an integer up to 64 bits.
*/
static void int2binFunc(sqlite3_context *context, int argc, sqlite3_value **argv)
{
  char *buffer;
  i64 iVal = 0;
  assert( 1 == argc );
  if ( SQLITE_INTEGER == sqlite3_value_type(argv[0]) ) {
    iVal = sqlite3_value_int64(argv[0]);
    buffer = sqlite3_malloc(I64_NBITS+1);
    if (!buffer) {
      sqlite3_result_error_nomem(context);
    } else {
      int2bin(buffer, iVal);
      sqlite3_result_text(context, buffer, -1, SQLITE_TRANSIENT);
      sqlite3_free(buffer);
    }
  } else {
    sqlite3_result_error(context, "invalid type", -1);
  }
}

#define N_DEZENAS 60 /* número de dezenas da mega-sena */

/**
 * Monta máscara de incidência das dezenas da mega-sena agrupadas via bitwise OR
 * no único argumento inteiro.
*/
static void mask60Func(sqlite3_context *context, int argc, sqlite3_value **argv)
{
  char *buffer, *t;
  i64 iVal = 0;
  int i = 0;
  assert( 1 == argc );
  if ( SQLITE_INTEGER == sqlite3_value_type(argv[0]) ) {
    iVal = sqlite3_value_int64(argv[0]);
    if (iVal < 0) {
      sqlite3_result_error(context, "argument of mask60 is negative", -1);
    } else {
      buffer = sqlite3_malloc(N_DEZENAS+1);
      if (!buffer) {
        sqlite3_result_error_nomem(context);
      } else {
        t = buffer;
        for (i=0; i < N_DEZENAS; i++, iVal >>= 1) *t++ = (iVal & 1) + '0';
        *t = '\0';
        sqlite3_result_text(context, buffer, -1, SQLITE_TRANSIENT);
        sqlite3_free(buffer);
      }
    }
  } else {
    sqlite3_result_error(context, "invalid type", -1);
  }
}

/**
 * Calcula o quadrante da dezena da mega-sena.
*/
static void quadranteFunc(sqlite3_context *context, int argc, sqlite3_value **argv)
{
  int d, q;
  assert( 1 == argc );
  if ( SQLITE_INTEGER == sqlite3_value_type(argv[0]) ) {
    d = sqlite3_value_int(argv[0]);
    if (d < 0 || d > N_DEZENAS) {
      sqlite3_result_error(context, "argument isn't in [1;60]", -1);
      return;
    }
    q = ((d-1) / 20 + 1) * 10 + (((d-1) % 10) / 2 + 1);
    sqlite3_result_int(context, q);
  } else {
    sqlite3_result_error(context, "argument isn't an integer", -1);
    return;
  }
}

/*
 * Returns the bit status of an integer up to 64 bits as first argument
 * and the zero-based bit number as second argument.
*/
static void bitstatusFunc(sqlite3_context *context, int argc, sqlite3_value **argv)
{
  i64 iVal = 0;
  int bitNumber = 0;
  int rZ = 0;
  assert( 2 == argc );
  if ( SQLITE_INTEGER == sqlite3_value_type(argv[0]) ) {
    iVal = sqlite3_value_int64(argv[0]);
    if ( SQLITE_INTEGER == sqlite3_value_type(argv[1]) ) {
      bitNumber = sqlite3_value_int(argv[1]);
      if (bitNumber >= 0 && bitNumber < I64_NBITS) {
        rZ = (iVal >> bitNumber) & 1;
        sqlite3_result_int(context, rZ);
      } else {
        sqlite3_result_error(context, "error: bit number isn't in [0;63]", -1);
      }
    } else {
      sqlite3_result_error(context, "error: bit status 2nd argument isn't an integer", -1);
    }
  } else {
    sqlite3_result_error(context, "error: bit status 1st argument isn't an integer", -1);
  }
}

/* estrutura de contexto Bitwise */
typedef struct BitCtx BitCtx;
struct BitCtx {
  i64 rB;
};

/*
 * Acumula o resultado do BITWISE OR entre o valor da estrutura de contexto
 * e o argumento inteiro a cada iteração da função de agregação de valores
 * agrupados.
*/
static void group_bitorStep(sqlite3_context *context, int argc, sqlite3_value **argv)
{
  BitCtx *p;
  i64 iVal = 0;
  assert( 1 == argc );
  if ( SQLITE_INTEGER == sqlite3_value_numeric_type(argv[0]) ) {
    iVal = sqlite3_value_int64(argv[0]);
    p = sqlite3_aggregate_context(context, sizeof(*p));
    p->rB |= iVal;
  } else {
    sqlite3_result_error(context, "error: BITOR argument isn't an integer", -1);
  }
}

/**
 * BITWISE OR dos índices das dezenas da mega-sena.
*/
static void group_ndxbitorStep(sqlite3_context *context, int argc, sqlite3_value **argv)
{
  const i64 ONE = 1;
  BitCtx *p;
  assert( 1 == argc );
  if ( SQLITE_INTEGER == sqlite3_value_numeric_type(argv[0]) ) {
    int iVal = sqlite3_value_int(argv[0]);
    if (iVal > 0 && iVal <= N_DEZENAS) {
      p = sqlite3_aggregate_context(context, sizeof(*p));
      p->rB |= ONE << iVal-1;
    } else {
      sqlite3_result_error(context, "error: index isn't in [1;60]", -1);
    }
  } else {
    sqlite3_result_error(context, "error: NDXBITOR argument isn't an integer", -1);
  }
}

/*
 * returns the resulting value of bitwise OR on group itens
*/
static void group_bitorFinalize(sqlite3_context *context)
{
  BitCtx *p;
  p = sqlite3_aggregate_context(context, 0);
  sqlite3_result_int64(context, p->rB);
}

/* LMH from sqlite3 3.3.13 */
/*
** This table maps from the first byte of a UTF-8 character to the number
** of trailing bytes expected. A value '4' indicates that the table key
** is not a legal first byte for a UTF-8 character.
*/
static const u8 xtra_utf8_bytes[256]  = {
  /* 0xxxxxxx */
  0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0,     0, 0, 0, 0, 0, 0, 0, 0,

  /* 10wwwwww */
  4, 4, 4, 4, 4, 4, 4, 4,     4, 4, 4, 4, 4, 4, 4, 4,
  4, 4, 4, 4, 4, 4, 4, 4,     4, 4, 4, 4, 4, 4, 4, 4,
  4, 4, 4, 4, 4, 4, 4, 4,     4, 4, 4, 4, 4, 4, 4, 4,
  4, 4, 4, 4, 4, 4, 4, 4,     4, 4, 4, 4, 4, 4, 4, 4,

  /* 110yyyyy */
  1, 1, 1, 1, 1, 1, 1, 1,     1, 1, 1, 1, 1, 1, 1, 1,
  1, 1, 1, 1, 1, 1, 1, 1,     1, 1, 1, 1, 1, 1, 1, 1,

  /* 1110zzzz */
  2, 2, 2, 2, 2, 2, 2, 2,     2, 2, 2, 2, 2, 2, 2, 2,

  /* 11110yyy */
  3, 3, 3, 3, 3, 3, 3, 3,     4, 4, 4, 4, 4, 4, 4, 4,
};

/*
** This table maps from the number of trailing bytes in a UTF-8 character
** to an integer constant that is effectively calculated for each character
** read by a naive implementation of a UTF-8 character reader. The code
** in the READ_UTF8 macro explains things best.
*/
static const int xtra_utf8_bits[] =  {
  0,
  12416,          /* (0xC0 << 6) + (0x80) */
  925824,         /* (0xE0 << 12) + (0x80 << 6) + (0x80) */
  63447168        /* (0xF0 << 18) + (0x80 << 12) + (0x80 << 6) + 0x80 */
};

/*
** If a UTF-8 character contains N bytes extra bytes (N bytes follow
** the initial byte so that the total character length is N+1) then
** masking the character with utf8_mask[N] must produce a non-zero
** result.  Otherwise, we have an (illegal) overlong encoding.
*/
static const int utf_mask[] = {
  0x00000000,
  0xffffff80,
  0xfffff800,
  0xffff0000,
};

static int sqlite3ReadUtf8(const unsigned char *z)
{
  int c;
  /* LMH salvaged from sqlite3 3.3.13 source code src/utf.c */
  // READ_UTF8(z, c);
  int xtra;
  c = *(z)++;
  xtra = xtra_utf8_bytes[c];
  switch (xtra) {
    case 4: c = (int) 0xFFFD; break;
    case 3: c = (c << 6) + *(z)++;
    case 2: c = (c << 6) + *(z)++;
    case 1: c = (c << 6) + *(z)++;
    c -= xtra_utf8_bits[xtra];
    if ((utf_mask[xtra] & c) == 0
        || (c&0xFFFFF800) == 0xD800
        || (c&0xFFFFFFFE) == 0xFFFE ) { c = 0xFFFD; }
  }
  return c;
}

/*
** X is a pointer to the first byte of a UTF-8 character.  Increment
** X so that it points to the next character.  This only works right
** if X points to a well-formed UTF-8 string.
*/
#define sqliteNextChar(X)  while( (0xc0&*++(X))==0x80 ){}
#define sqliteCharVal(X)   sqlite3ReadUtf8(X)

/*
** given a string returns the same string but with the characters in reverse
** order
*/
static void reverseFunc(sqlite3_context *context, int argc, sqlite3_value **argv)
{
  const char *z;
  const char *zt;
  char *rz;
  char *rzt;
  int l = 0;
  int i = 0;

  assert( 1 == argc );

  if ( SQLITE_NULL == sqlite3_value_type(argv[0]) ) {
    sqlite3_result_null(context);
    return;
  }
  z = (char *)sqlite3_value_text(argv[0]);
  l = strlen(z);
  rz = sqlite3_malloc(l+1);
  if (!rz) {
    sqlite3_result_error_nomem(context);
    return;
  }
  rzt = rz+l;
  *(rzt--) = '\0';

  zt = z;
  while ( sqliteCharVal((unsigned char *) zt) != 0 ) {
    z = zt;
    sqliteNextChar(zt);
    for (i=1; zt-i >= z; ++i) {
      *(rzt--) = *(zt-i);
    }
  }

  sqlite3_result_text(context, rz, -1, SQLITE_TRANSIENT);
  sqlite3_free(rz);
}

/*
 * Returns a left zero padded string of the first positive int argument with
 * minimum length corresponding to the second positive int argument.
*/
static void zeropadFunc(sqlite3_context *context, int argc, sqlite3_value **argv)
{
  i64 iVal = 0;
  int iSize = 0;
  assert( argc == 2 );
  int j;
  for (j=0; j < argc; j++) {
    switch( sqlite3_value_type(argv[j]) ) {
      case SQLITE_INTEGER: {
        if (j == 0)
          iVal = sqlite3_value_int64(argv[0]);
        else
          iSize = sqlite3_value_int(argv[1]);
        break;
      }
      case SQLITE_NULL: {
        sqlite3_result_null(context);
        break;
      }
      default: {
        sqlite3_result_error(context, "invalid type", -1);
        break;
      }
    }
  }
  if (iVal < 0 || iSize < 0) {
    sqlite3_result_error(context, "domain error", -1);
    return;
  }
  char *mask = sqlite3_mprintf("%%0%dd", iSize);
  char *z = sqlite3_mprintf(mask, iVal);
  sqlite3_free(mask);
  sqlite3_result_text(context, (char*)z, -1, SQLITE_TRANSIENT);
  sqlite3_free(z);
}

/**
 * Copia até 'length' caractéres da string utf8 apontada por 'source' a partir
 * do índice 'offset' inclusive, para a posição de memória apontada por 'buffer'
 * dimensionada préviamente para conter a substring mais o byte terminador null
 * e em caso contrário ocorrerá falha de segmentação.
 * A string apontada por 'source' é preservada conforme definição do argumento
 * como constante, embora o ponteiro seja usado na montagem da substring.
*/
static char *strcopy(char * buffer, const char *source, int offset, int length)
{
  const char *zt;
  char *rzt;
  int i, j;
  /* position the pointer to traverse the utf8 string from offset */
  zt = source + offset;
  /* position the pointer to fill the result string */
  rzt = buffer;
  /* traverse the utf8 source string filling the buffer string till */
  /* 'length' characters are copied or till the null byte is found  */
  for (j=0; j < length && sqliteCharVal((unsigned char *) zt) != 0; j++) {
    source = zt;
    sqliteNextChar(zt);
    /* inner loop to get all character bytes */
    for (i=1; zt-i >= source; ++i) *(rzt++) = *(zt-i);
  }
  *(rzt++) = '\0'; /* finalize the buffer string */
  return buffer;
}

/*
 * Extract field from a datestring in first parameter with index order in
 * second parameter where 0 is for year, 1 is for month and 2 is for day.
*/
static void datefieldFunc(sqlite3_context *context, int argc, sqlite3_value **argv)
{
  const int LEN[3] = { 4, 2, 2 }; /* fields lengths */
  const int NDX[3] = { 0, 5, 8 }; /* fields offset indexes */
  const char *z;
  char *rz;
  int f, i, j;
  assert( 2 == argc );
  /* check if first argument type is text */
  if ( SQLITE_TEXT != sqlite3_value_type(argv[0]) ) {
    sqlite3_result_error(context, "1st argument isn't a string", -1);
    return;
  }
  z = (char *) sqlite3_value_text(argv[0]);
  /* check if second argument type is integer */
  if ( SQLITE_INTEGER != sqlite3_value_type(argv[1]) ) {
    sqlite3_result_error(context, "2nd argument isn't an integer", -1);
    return;
  }
  f = sqlite3_value_int(argv[1]);
  /* check field offset index argument value */
  if (f < 0 || f > 2) {
    sqlite3_result_error(context, "2nd argument domain error", -1);
    return;
  }
  /* try to allocate memory for result string */
  rz = sqlite3_malloc(LEN[f]+1);
  if (!rz) {
    sqlite3_result_error_nomem(context);
    return;
  }
  strcopy(rz, z, NDX[f], LEN[f]);
  /* publish the result string in the context */
  sqlite3_result_text(context, rz, -1, SQLITE_TRANSIENT);
  /* release the wasted memory */
  sqlite3_free(rz);
}

/**
 * Retorna a data 'yyyy-mm-dd' no formato 'dd-mm-yyyy'.
*/
static void datalocalFunc(sqlite3_context *context, int argc, sqlite3_value **argv)
{
  const char *z;
  char *rz;
  z = (char *) sqlite3_value_text(argv[0]);
  rz = sqlite3_malloc(strlen(z)+1);
  strcopy(rz, z, 8, 2);
  strcopy(&rz[strlen(rz)], z, 4, 4);
  strcopy(&rz[strlen(rz)], z, 0, 4);
  sqlite3_result_text(context, rz, -1, SQLITE_TRANSIENT);
  sqlite3_free(rz);
}

/*
** This function registered all of the above C functions as SQL
** functions.  This should be the only routine in this file with
** external linkage.
*/
int RegisterExtensionFunctions(sqlite3 *db)
{
  static const struct FuncDef {
     char *zName;
     signed char nArg;
     u8 argType;           /* 0: none.  1: db  2: (-1) */
     u8 eTextRep;          /* 1: UTF-16.  0: UTF-8 */
     u8 needCollSeq;
     void (*xFunc)(sqlite3_context*,int,sqlite3_value **);
  } aFuncs[] = {

    { "power",              2, 0, SQLITE_UTF8,    0, powerFunc  },

    { "reverse",            1, 0, SQLITE_UTF8,    0, reverseFunc },
    { "zeropad",            2, 0, SQLITE_UTF8,    0, zeropadFunc },

    /* bitwise */
    { "int2bin",            1, 0, SQLITE_UTF8,    0, int2binFunc },
    { "bitstatus",          2, 0, SQLITE_UTF8,    0, bitstatusFunc },

    { "mask60",             1, 0, SQLITE_UTF8,    0, mask60Func },
    { "quadrante",          1, 0, SQLITE_UTF8,    0, quadranteFunc },

    { "datefield",          2, 0, SQLITE_UTF8,    0, datefieldFunc },
    { "datalocal",          1, 0, SQLITE_UTF8,    0, datalocalFunc },

  };

  /* Aggregate functions */
  static const struct FuncDefAgg {
    char *zName;
    signed char nArg;
    u8 argType;
    u8 needCollSeq;
    void (*xStep)(sqlite3_context*,int,sqlite3_value**);
    void (*xFinalize)(sqlite3_context*);
  } aAggs[] = {

    { "group_bitor",      1, 0, 0, group_bitorStep, group_bitorFinalize },
    { "group_ndxbitor",   1, 0, 0, group_ndxbitorStep, group_bitorFinalize },

    { "product",          1, 0, 0, group_productStep, group_productFinalize },

  };

  int i;
  for (i=0; i<sizeof(aFuncs)/sizeof(aFuncs[0]); i++) {
    void *pArg = 0;
    switch ( aFuncs[i].argType ) {
      case 1: pArg = db; break;
      case 2: pArg = (void *)(-1); break;
    }
    //sqlite3CreateFunc
    /* LMH no error checking */
    sqlite3_create_function(db, aFuncs[i].zName, aFuncs[i].nArg,
        aFuncs[i].eTextRep, pArg, aFuncs[i].xFunc, 0, 0);
#if 0
    if ( aFuncs[i].needCollSeq ) {
      struct FuncDef *pFunc = sqlite3FindFunction(db, aFuncs[i].zName,
          strlen(aFuncs[i].zName), aFuncs[i].nArg, aFuncs[i].eTextRep, 0);
      if ( pFunc && aFuncs[i].needCollSeq ) {
        pFunc->needCollSeq = 1;
      }
    }
#endif
  }

  for (i=0; i<sizeof(aAggs)/sizeof(aAggs[0]); i++) {
    void *pArg = 0;
    switch ( aAggs[i].argType ) {
      case 1: pArg = db; break;
      case 2: pArg = (void *)(-1); break;
    }
    //sqlite3CreateFunc
    /* LMH no error checking */
    sqlite3_create_function(db, aAggs[i].zName, aAggs[i].nArg, SQLITE_UTF8,
        pArg, 0, aAggs[i].xStep, aAggs[i].xFinalize);
#if 0
    if ( aAggs[i].needCollSeq ) {
      struct FuncDefAgg *pFunc = sqlite3FindFunction( db, aAggs[i].zName,
          strlen(aAggs[i].zName), aAggs[i].nArg, SQLITE_UTF8, 0);
      if ( pFunc && aAggs[i].needCollSeq ) {
        pFunc->needCollSeq = 1;
      }
    }
#endif
  }
  return 0;
}

#ifdef COMPILE_SQLITE_EXTENSIONS_AS_LOADABLE_MODULE
int sqlite3_extension_init(sqlite3 *db, char **pzErrMsg, const sqlite3_api_routines *pApi)
{
  SQLITE_EXTENSION_INIT2(pApi);
  RegisterExtensionFunctions(db);
  return 0;
}
#endif /* COMPILE_SQLITE_EXTENSIONS_AS_LOADABLE_MODULE */
