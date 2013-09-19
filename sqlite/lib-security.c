/*
 * Functions dealing with security in SQLite:
 *
 *    MD5, ENC, DEC, ENC2, DEC2
 *
 * Except to MD5, all functions are workaround providing naive encryption
 * and decryption using symmetric-key which are safe in the sense of system
 * resources usage with very good performance.
 *
 * Important: There aren't warranties and usage is at your own risk.
 *
 * Dependencies:
 *
 *    packages libsqlite3-dev and libssl-dev are required.
 *
 * Compile:
 *
 *    gcc lib-security.c -Wall -fPIC -shared -lm -lcrypto -o lib-security.so
 *
 * Usage in init file or interative sessions:
 *
 *    .load "path_to_this_extension_lib/lib-security.so"
 *
 * or as SQLite query:
 *
 *    select load_extension("path_to_this_extension_lib/lib-security.so");
*/
#include <sqlite3ext.h>
SQLITE_EXTENSION_INIT1

#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <openssl/md5.h>

/*
 * Retorna o MD5 128-bit checksum do argumento como string de 32 dígitos
 * hexadecimais ou NULL se o argumento é NULL.
*/
static void md5(sqlite3_context *ctx, int argc, sqlite3_value **argv)
{
  unsigned char digest[MD5_DIGEST_LENGTH];
  unsigned char *z;
  char *rz;
  int i;

  assert(1 == argc);

  if (SQLITE_NULL == sqlite3_value_type(argv[0])) {
    sqlite3_result_null(ctx);
    return ;
  }
  z = (unsigned char *) sqlite3_value_text(argv[0]);

  rz = sqlite3_malloc((MD5_DIGEST_LENGTH << 1) + 1);
  if (!rz) {
    sqlite3_result_error_nomem(ctx);
    return ;
  }

  MD5(z, strlen((char *) z), (unsigned char *) &digest);

  for (i = 0; i < MD5_DIGEST_LENGTH; i++)
  {
    sqlite3_snprintf(3, rz + (i << 1), "%02x", (unsigned int) digest[i]);
  }

  sqlite3_result_text(ctx, rz, -1, SQLITE_TRANSIENT);
  sqlite3_free(rz);
}

/*
 * Retorna o incremento de 1 da disjunção exclusiva entre os argumentos:
 *
 *                        (c xor k) + 1
*/
static inline char encrypt_char(char c, char k)
{
  return -(~(c ^ k)); // (c ^ k) + (char) 0x01;
}

/*
 * Retorna a disjunção exclusiva do primeiro argumento decrementado de 1
 * e o segundo argumento:
 *
 *                        (c - 1) xor k
 *
 * Funciona como função inversa de encrypt_char se o primeiro argumento é
 * o resultado de seu uso e o segundo argumento é o mesmo para ambos:
 *
 *                decrypt_char(encrypt_char(c, k), k) == c
 *
 * equivalente a:
 *
 *                  ((((c xor k) + 1) - 1) xor k) == c
*/
static inline char decrypt_char(char c, char k)
{
  return --c ^ k;     // ~(-c) ^ k;   // (c - (char) 0x01) ^ k;
}

/*
 * Método ingênuo de criptografia via chave simétrica, acionado internamente
 * pelas funções de interface ao usuário.
*/
static char *crypt(const char *src, const char *key, char *buf, char (*f)(char, char))
{
  char *s, *z;
  int i, k;

  // read source and fill buffer in forward direction
  s = (char *) src;
  z = buf;
  k = strlen(key);
  i = 0;
  while (*s) {
    *z++ = (*f)(*s++, key[i++ % k]);
  }
  *z = *s;  // borrow the NUL char

  return buf;
}

/*
 * Método alternativo ao anterior com pouca complexidade adicional.
*/
static char *crypt2(const char *src, const char *key, char *buf, char (*f)(char, char))
{
  char *s, *z;
  int i, k;

  // build the reversed source string
  k = strlen(src);
  s = (char *) sqlite3_malloc(k + 1);
  s += k;
  *s = '\0';
  z = (char *) src;
  while (*z) {
    *(--s) = *z++;
  }
  // read reversed source and fill buffer in backward direction
  z = buf + k;
  *z = '\0';
  k = strlen(key);
  i = 0;
  while (*s) {
    *(--z) = (*f)(*s++, key[i++ % k]);
  }
  sqlite3_free(s - i);

  return buf;
}

/*
 * Retorna texto cifrado usando chave simétrica, tal que a chave
 * deve ser o primeiro argumento e o texto o segundo.
 *
 * ENC é a função inversa de DEC:
 *
 *    select ENC(chave, DEC(chave, texto)) == texto;
*/
static void enc(sqlite3_context *ctx, int argc, sqlite3_value **argv)
{
  const char *key, *plain;
  char *cypher;

  assert(2 == argc);

  if (SQLITE_NULL == sqlite3_value_type(argv[0])) {
    sqlite3_result_error(ctx, "can't use NULL as key value", -1);
    return ;
  }
  key = (char *) sqlite3_value_text(argv[0]);
  if (strlen(key) == 0) {
    sqlite3_result_error(ctx, "key value is an zero length string", -1);
    return ;
  }

  if (SQLITE_NULL == sqlite3_value_type(argv[1])) {
    sqlite3_result_null(ctx);
    return ;
  }
  plain = (char *) sqlite3_value_text(argv[1]);

  cypher = sqlite3_malloc( strlen(plain) + 1 );
  if (!cypher) {
    sqlite3_result_error_nomem(ctx);
    return ;
  }
  crypt(plain, key, cypher, &encrypt_char);

  sqlite3_result_text(ctx, cypher, -1, SQLITE_TRANSIENT);
  sqlite3_free(cypher);
}

/*
 * Retorna texto usando chave simétrica, tal que a chave
 * deve ser o primeiro argumento e o texto cifrado o segundo.
 *
 * DEC é a função inversa de ENC:
 *
 *    select DEC(chave, ENC(chave, texto)) == texto;
*/
static void dec(sqlite3_context *ctx, int argc, sqlite3_value **argv)
{
  const char *key, *cypher;
  char *plain;

  assert(2 == argc);

  if (SQLITE_NULL == sqlite3_value_type(argv[0])) {
    sqlite3_result_error(ctx, "can't use NULL as key value", -1);
    return ;
  }
  key = (char *) sqlite3_value_text(argv[0]);
  if (strlen(key) == 0) {
    sqlite3_result_error(ctx, "key value is an zero length string", -1);
    return ;
  }

  if (SQLITE_NULL == sqlite3_value_type(argv[1])) {
    sqlite3_result_null(ctx);
    return ;
  }
  cypher = (char *) sqlite3_value_text(argv[1]);

  plain = sqlite3_malloc( strlen(cypher) + 1 );
  if (!plain) {
    sqlite3_result_error_nomem(ctx);
    return ;
  }
  crypt(cypher, key, plain, &decrypt_char);

  sqlite3_result_text(ctx, plain, -1, SQLITE_TRANSIENT);
  sqlite3_free(plain);
}

/*
 * Equivalente a ENC, usando procedimento alternativo.
 *
 * ENC2 é a função inversa de DEC2:
 *
 *    select ENC2(chave, DEC2(chave, texto)) == texto;
*/
static void enc2(sqlite3_context *ctx, int argc, sqlite3_value **argv)
{
  const char *key, *plain;
  char *cypher;

  assert(2 == argc);

  if (SQLITE_NULL == sqlite3_value_type(argv[0])) {
    sqlite3_result_error(ctx, "can't use NULL as key value", -1);
    return ;
  }
  key = (char *) sqlite3_value_text(argv[0]);
  if (strlen(key) == 0) {
    sqlite3_result_error(ctx, "key value is an zero length string", -1);
    return ;
  }

  if (SQLITE_NULL == sqlite3_value_type(argv[1])) {
    sqlite3_result_null(ctx);
    return ;
  }
  plain = (char *) sqlite3_value_text(argv[1]);

  cypher = sqlite3_malloc( strlen(plain) + 1 );
  if (!cypher) {
    sqlite3_result_error_nomem(ctx);
    return ;
  }
  crypt2(plain, key, cypher, &encrypt_char);

  sqlite3_result_text(ctx, cypher, -1, SQLITE_TRANSIENT);
  sqlite3_free(cypher);
}

/*
 * Equivalente a DEC, usando procedimento alternativo.
 *
 * DEC2 é a função inversa de ENC2:
 *
 *    select DEC2(chave, ENC2(chave, texto)) == texto;
*/
static void dec2(sqlite3_context *ctx, int argc, sqlite3_value **argv)
{
  const char *key, *cypher;
  char *plain;

  assert(2 == argc);

  if (SQLITE_NULL == sqlite3_value_type(argv[0])) {
    sqlite3_result_error(ctx, "can't use NULL as key value", -1);
    return ;
  }
  key = (char *) sqlite3_value_text(argv[0]);
  if (strlen(key) == 0) {
    sqlite3_result_error(ctx, "key value is an zero length string", -1);
    return ;
  }

  if (SQLITE_NULL == sqlite3_value_type(argv[1])) {
    sqlite3_result_null(ctx);
    return ;
  }
  cypher = (char *) sqlite3_value_text(argv[1]);

  plain = sqlite3_malloc( strlen(cypher) + 1 );
  if (!plain) {
    sqlite3_result_error_nomem(ctx);
    return ;
  }
  crypt2(cypher, key, plain, &decrypt_char);

  sqlite3_result_text(ctx, plain, -1, SQLITE_TRANSIENT);
  sqlite3_free(plain);
}

int sqlite3_extension_init(sqlite3 *db, char **err, const sqlite3_api_routines *api)
{
  SQLITE_EXTENSION_INIT2(api)

  sqlite3_create_function(db, "MD5", 1, SQLITE_UTF8, NULL, md5, NULL, NULL);
  sqlite3_create_function(db, "ENC", 2, SQLITE_UTF8, NULL, enc, NULL, NULL);
  sqlite3_create_function(db, "DEC", 2, SQLITE_UTF8, NULL, dec, NULL, NULL);
  sqlite3_create_function(db, "ENC2", 2, SQLITE_UTF8, NULL, enc2, NULL, NULL);
  sqlite3_create_function(db, "DEC2", 2, SQLITE_UTF8, NULL, dec2, NULL, NULL);

  return 0;
}
