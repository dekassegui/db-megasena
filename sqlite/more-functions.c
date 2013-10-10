/*
 * Math: power
 *
 * String: reverse, zeropad
 *
 * Bitwise: int2bin, bitstatus
 *
 * Bitwise aggregation: group_bitor, group_ndxbitor
 *
 * Miscellaneous: mask60, quadrante, rownum
 *
 * Compile: gcc more-functions.c -fPIC -shared -lm -o more-functions.so
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

typedef uint8_t   u8;
typedef uint16_t  u16;
typedef int64_t   i64;

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

#include <limits.h>

#define I64_NBITS (sizeof(i64) * CHAR_BIT)

static char *int2bin(i64 n, char *buf)
{
  char *t;
  for (t = buf+I64_NBITS, *t = '\0'; t != buf; n >>= 1) *(--t) = (n & 1) | '0';
  return buf;
}

/*
 * Returns the binary representation string of an integer up to 64 bits.
*/
static void int2binFunc(sqlite3_context *context, int argc, sqlite3_value **argv)
{
  char *buffer;
  i64 iVal;

  assert( 1 == argc );

  if ( SQLITE_INTEGER == sqlite3_value_type(argv[0]) ) {
    iVal = sqlite3_value_int64(argv[0]);
    buffer = sqlite3_malloc( I64_NBITS+1 );
    if (!buffer) {
      sqlite3_result_error_nomem(context);
    } else {
      int2bin(iVal, buffer);
      sqlite3_result_text(context, buffer, -1, SQLITE_TRANSIENT);
      sqlite3_free(buffer);
    }
  } else {
    sqlite3_result_error(context, "invalid type", -1);
  }
}

#define N_DEZENAS 60 /* quantidade de números da Mega-Sena */

/*
 * Monta máscara de incidência dos números da Mega-Sena agrupados via
 * bitwise OR no único argumento de tipo inteiro.
*/
static void mask60Func(sqlite3_context *context, int argc, sqlite3_value **argv)
{
  char *buffer;
  i64 iVal;
  int i;

  assert( 1 == argc );

  if ( SQLITE_INTEGER == sqlite3_value_type(argv[0]) ) {
    iVal = sqlite3_value_int64(argv[0]);
    if (iVal < 0) {
      sqlite3_result_error(context, "argumento é negativo", -1);
    } else {
      buffer = (char *) sqlite3_malloc( N_DEZENAS+1 );
      if (!buffer) {
        sqlite3_result_error_nomem(context);
      } else {
        for (i=0; i < N_DEZENAS; i++, iVal >>= 1) buffer[i] = (iVal & 1) | '0';
        buffer[N_DEZENAS] = '\0';
        sqlite3_result_text(context, buffer, -1, SQLITE_TRANSIENT);
        sqlite3_free(buffer);
      }
    }
  } else {
    sqlite3_result_error(context, "tipo do argumento é invalido", -1);
  }
}

/*
 * Retorna o quadrante do número da Mega-Sena conforme apresentado no boleto.
*/
static void quadranteFunc(sqlite3_context *context, int argc, sqlite3_value **argv)
{
  int d, q;

  assert( 1 == argc );

  if ( SQLITE_INTEGER == sqlite3_value_type(argv[0]) ) {
    d = sqlite3_value_int(argv[0]);
    if (d < 1 || d > N_DEZENAS) {
      sqlite3_result_error(context, "argumento é menor que 1 ou maior que 60", -1);
      return;
    }
    q = ((d-1) / 20 + 1) * 10 + (((d-1) % 10) / 2 + 1);
    sqlite3_result_int(context, q);
  } else {
    sqlite3_result_error(context, "argumento não é do tipo inteiro", -1);
    return;
  }
}

/*
 * Returns the bit status of an integer up to 64 bits as first argument
 * and the zero-based bit number as second argument.
*/
static void bitstatusFunc(sqlite3_context *context, int argc, sqlite3_value **argv)
{
  i64 iVal;
  int bitNumber;

  assert( 2 == argc );

  if ( SQLITE_INTEGER == sqlite3_value_type(argv[0]) ) {
    iVal = sqlite3_value_int64(argv[0]);
    if ( SQLITE_INTEGER == sqlite3_value_type(argv[1]) ) {
      bitNumber = sqlite3_value_int(argv[1]);
      if (bitNumber >= 0 && bitNumber < I64_NBITS) {
        sqlite3_result_int(context, (iVal >> bitNumber) & 1);
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

typedef struct BitCtx {
  i64 rB;
}
BitCtx;

/*
 * returns the resulting value of bitwise OR on group itens
*/
static void group_bitorFinalize(sqlite3_context *context)
{
  BitCtx *p;

  p = sqlite3_aggregate_context(context, sizeof(BitCtx));
  sqlite3_result_int64(context, p->rB);
}

/*
 * Acumula o resultado do BITWISE OR entre o valor da estrutura de contexto
 * e o argumento inteiro a cada iteração da função de agregação de valores
 * agrupados.
*/
static void group_bitorStep(sqlite3_context *context, int argc, sqlite3_value **argv)
{
  BitCtx *p;
  i64 iVal;

  assert( 1 == argc );

  if ( SQLITE_INTEGER == sqlite3_value_numeric_type(argv[0]) ) {
    iVal = sqlite3_value_int64(argv[0]);
    p = sqlite3_aggregate_context(context, sizeof(BitCtx));
    p->rB |= iVal;
  } else {
    sqlite3_result_error(context, "error: BITOR argument isn't an integer", -1);
  }
}

/*
 * BITWISE OR dos índices dos números da Mega-Sena.
*/
static void group_ndxbitorStep(sqlite3_context *context, int argc, sqlite3_value **argv)
{
  BitCtx *p;
  int iVal;

  assert( 1 == argc );

  if ( SQLITE_INTEGER == sqlite3_value_numeric_type(argv[0]) ) {
    iVal = sqlite3_value_int(argv[0]);
    if (iVal > 0 && iVal <= N_DEZENAS) {
      p = sqlite3_aggregate_context(context, sizeof(BitCtx));
      p->rB |= ((i64) 1) << (iVal-1);
    } else {
      sqlite3_result_error(context, "argumento é menor que 1 ou maior que 60", -1);
    }
  } else {
    sqlite3_result_error(context, "argumento nao é do tipo inteiro", -1);
  }
}

/* LMH from sqlite3 3.3.13
 *
 * This table maps from the first byte of a UTF-8 character to the number
 * of trailing bytes expected. A value '4' indicates that the table key
 * is not a legal first byte for a UTF-8 character.
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
 * This table maps from the number of trailing bytes in a UTF-8 character
 * to an integer constant that is effectively calculated for each character
 * read by a naive implementation of a UTF-8 character reader. The code
 * in the READ_UTF8 macro explains things best.
*/
static const int xtra_utf8_bits[] =  {
  0,
  12416,          /* (0xC0 << 6)  + (0x80) */
  925824,         /* (0xE0 << 12) + (0x80 << 6) + (0x80) */
  63447168        /* (0xF0 << 18) + (0x80 << 12) + (0x80 << 6) + 0x80 */
};

/*
 * If a UTF-8 character contains N bytes extra bytes (N bytes follow
 * the initial byte so that the total character length is N+1) then
 * masking the character with utf8_mask[N] must produce a non-zero
 * result.  Otherwise, we have an (illegal) overlong encoding.
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
 * X is a pointer to the first byte of a UTF-8 character.  Increment
 * X so that it points to the next character.  This only works right
 * if X points to a well-formed UTF-8 string.
*/
#define sqliteNextChar(X)  while( (0xC0 & *(++X)) == 0x80 ){}
#define sqliteCharVal(X)   sqlite3ReadUtf8(X)

/*
 * Returns the source string with the characters in reverse order.
*/
static void reverseFunc(sqlite3_context *context, int argc, sqlite3_value **argv)
{
  unsigned char *z, *t;
  char *rz, *r;
  int n;

  assert( 1 == argc );

  if ( SQLITE_NULL == sqlite3_value_type(argv[0]) )
  {
    sqlite3_result_null(context);
    return;
  }
  t = z = (unsigned char *) sqlite3_value_text(argv[0]);
  n = strlen((char *) z);
  r = rz = (char *) sqlite3_malloc(n + 1);
  if (!rz)
  {
    sqlite3_result_error_nomem(context);
    return;
  }
  *(rz += n) = '\0';
  while (sqliteCharVal(t) != 0)
  {
    z = t;
    sqliteNextChar(t);
    rz -= n = t - z;
    memcpy(rz, z, n);
  }

  assert(r == rz);

  sqlite3_result_text(context, rz, -1, SQLITE_TRANSIENT);
  sqlite3_free(rz);
}

/*
 * Returns a left zero padded string of the first positive int argument with
 * minimum length corresponding to the second positive int argument.
*/
static void zeropadFunc(sqlite3_context *context, int argc, sqlite3_value **argv)
{
  i64 iVal;
  int iSize, j;
  char *z, *format;

  assert( argc == 2 );

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
  format = sqlite3_mprintf("%%0%dd", iSize);
  z = sqlite3_mprintf(format, iVal);
  sqlite3_free(format);
  sqlite3_result_text(context, z, -1, SQLITE_TRANSIENT);
  sqlite3_free(z);
}

/*
 * The ROWNUM code was borrowed from: http://sqlite.1065341.n5.nabble.com/sequential-row-numbers-from-query-td47370.html
*/

typedef struct ROWNUM_t ROWNUM_t;
struct ROWNUM_t {
  int nNumber;
};

static void rownum_free(void *p)
{
  sqlite3_free(p);
}

/*
 * Retorna o número da linha na tabela, necessariamente usando como argumento
 * qualquer valor constante.
*/
static void rownumFunc(sqlite3_context *context, int argc, sqlite3_value **argv
)
{
  ROWNUM_t *pAux;

  pAux = sqlite3_get_auxdata(context, 0);
  if (!pAux) {
    pAux = (ROWNUM_t *) sqlite3_malloc( sizeof(ROWNUM_t) );
    if (pAux) {
      pAux->nNumber = 0;
      sqlite3_set_auxdata(context, 0, (void *) pAux, rownum_free);
    } else {
      sqlite3_result_error(context, "sqlite3_malloc failed", -1);
      return;
    }
  }
  pAux->nNumber++;

  sqlite3_result_int(context, pAux->nNumber);
}

/*
 * This function registered all of the above C functions as SQL
 * functions.  This should be the only routine in this file with
 * external linkage.
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

    { "rownum",             1, 0, SQLITE_UTF8,    0, rownumFunc },

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
