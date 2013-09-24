/*
 * Functions dealing with security in SQLite:
 *
 *    MD5, ENC, DEC
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

static unsigned char lrotate(unsigned char val, int n)
{
  int i, t = val;

  for (i=0; i < n; i++)
  {
    t <<= 1;
    if (t & 256) t |= 1;
  }

  return t;
}

static unsigned char rrotate(unsigned char val, int n)
{
  int i, t = val;

  t <<= 8;
  for (i=0; i < n; i++)
  {
    t >>= 1;
    if (t & 128) t |= 32768;
  }

  return t >> 8;
}

#define ROT(a, b)  (char) rrotate((unsigned char) (a), ((int) (b)) % 8)

#define LROT(a, b) (char) lrotate((unsigned char) (a), ((int) (b)) % 8)

typedef struct krypt_s
{
  char *id;
  char (*cifrar_char)(char c, char k);
  char (*decifrar_char)(char c, char k);
}
krypt_t;

static char naive_cifrar_char(char c, char k)
{
  return c ^ k;
}

static char usual_cifrar_char(char c, char k)
{
  return ROT(c ^ k, k);
}

static char usual_decifrar_char(char c, char k)
{
  return LROT(c, k) ^ k;
}

static char single_cifrar_char(char c, char k)
{
  return ROT(c, k) ^ k;
}

static char single_decifrar_char(char c, char k)
{
  return LROT(c ^ k, k);
}

static char alternate_cifrar_char(char c, char k)
{
  return (k % 2) ? LROT(c ^ k, k) : ROT(c ^ k, k);
}

static char alternate_decifrar_char(char c, char k)
{
  return (k % 2) ? ROT(c, k) ^ k : LROT(c, k) ^ k;
}

#define DEFAULT_KRYPT_MODE "naive"

/*
 * Inicializa o engine de criptografia de caractéres conforme nome do método.
*/
static void init_krypt(krypt_t *krypt, const char *id)
{
  if (strcmp(id, "single") == 0)
  {
    krypt->id = "single";
    krypt->cifrar_char = single_cifrar_char;
    krypt->decifrar_char = single_decifrar_char;
  }
  else if (strcmp(id, "usual") == 0)
  {
    krypt->id = "usual";
    krypt->cifrar_char = usual_cifrar_char;
    krypt->decifrar_char = usual_decifrar_char;
  }
  else if (strcmp(id, "alternate") == 0)
  {
    krypt->id = "alternate";
    krypt->cifrar_char = alternate_cifrar_char;
    krypt->decifrar_char = alternate_decifrar_char;
  }
  else
  {
    krypt->id = "naive";
    krypt->cifrar_char = naive_cifrar_char;
    krypt->decifrar_char = naive_cifrar_char;
  }
}

/*
 * Valor inteiro resultante de 0xC0 | (0x80 << 8) cujos bytes na ordem inversa
 * coincidem com a codificação do caractere NULL (U+0000) no "Modified UTF8",
 * onde strings nunca contém NULL, mas podem conter todos os "code points" do
 * Unicode, inclusive U+0000, possibilitando que tais strings contendo NULL
 * sejam processadas por funções tradicionais de string terminada com NULL.
*/
#define INSIDE_NULL -32576

/*
 * Retorna texto cifrado via método ingenuo de criptografia por chave simétrica.
 *
 * src: string objeto da cifragem, terminada com NULL.
 * key: string contendo a chave criptográfica, terminada com NULL.
 * buf: string resultante, terminada com NULL (0x00) e os NULL gerados
 *      na cifragem, substituídos pela sequência de bytes 0xC0 e 0x80.
 * krypt: engine de criptografia de caractéres.
*/
static char *cifrar(const char *src, const char *key, char *buf, krypt_t *krypt)
{
  char *z;
  int n, k;

  for (z=buf, k=strlen(key), n=0; src[n]; ++n, ++z)
  {
    *z = krypt->cifrar_char(src[n], key[n%k]);
    if (*z == 0) *((short int *) z++) = INSIDE_NULL;
  }
  *z = 0;

  return buf;
}

/*
 * Retorna texto decifrado, proveniente do processamento via função "cifrar".
 *
 * src: string objeto da decifragem, terminada com NULL.
 * key: string contendo a chave criptográfica, terminada com NULL.
 * buf: string resultante, terminada com NULL (0x00).
 * krypt: engine de criptografia de caractéres.
*/
static char *decifrar(const char *src, const char *key, char *buf, krypt_t *krypt)
{
  char c;
  int n, k, x;

  for (k=strlen(key), n=0; *src; ++n, ++src)
  {
    x = *((short int *) src) == INSIDE_NULL;
    c = *src * (1 - x);
    src += x;
    buf[n] = krypt->decifrar_char(c, key[n%k]);
  }
  buf[n] = 0;

  return buf;
}

/*
 * Retorna texto cifrado usando criptografia por chave simétrica.
 *
 * O primeiro argumento é o nome do método criptográfico que deve ser;
 * "alternate", "naive", "single" ou "usual", e se for omitido, então
 * será usado o método definido em DEFAULT_KRYPT_MODE.
 * Os argumentos seguintes são a chave criptográfica e o texto, nesta
 * ordem.
 *
 * ENC é a função inversa de DEC:
 *
 *    select ENC([método, ]chave, DEC([método, ]chave, texto)) == texto;
*/
static void enc(sqlite3_context *ctx, int argc, sqlite3_value **argv)
{
  krypt_t *krypt;
  const char *chave, *texto, *modo;
  char *cifrado;
  int j = 0;

  assert(argc == 2 || argc == 3);

  if (3 == argc) {
    if (SQLITE_NULL == sqlite3_value_type(argv[j])) {
      sqlite3_result_error(ctx, "nome do modo criptográfico é NULL", -1);
      return ;
    }
    modo = (char *) sqlite3_value_text(argv[j++]);
    if (strlen(modo) == 0) {
      sqlite3_result_error(ctx, "nome do modo criptográfico tem comprimento zero", -1);
      return ;
    }
  } else {
    modo = DEFAULT_KRYPT_MODE;
  }

  if (SQLITE_NULL == sqlite3_value_type(argv[j])) {
    sqlite3_result_error(ctx, "chave criptográfica é NULL", -1);
    return ;
  }
  chave = (char *) sqlite3_value_text(argv[j++]);
  if (strlen(chave) == 0) {
    sqlite3_result_error(ctx, "chave de comprimento zero", -1);
    return ;
  }

  if (SQLITE_NULL == sqlite3_value_type(argv[j])) {
    sqlite3_result_null(ctx);
    return ;
  }
  texto = (char *) sqlite3_value_text(argv[j]);

  cifrado = sqlite3_malloc( strlen(texto)*2 );
  if (!cifrado) {
    sqlite3_result_error_nomem(ctx);
    return ;
  }

  krypt = sqlite3_get_auxdata(ctx, 0);
  if (!krypt) {
    krypt = (krypt_t *) sqlite3_malloc(sizeof(krypt_t));
    if (!krypt) {
      sqlite3_result_error(ctx, "memória insuficiente", -1);
      sqlite3_free(cifrado);
      return ;
    }
    init_krypt(krypt, modo);
    sqlite3_set_auxdata(ctx, 0, krypt, sqlite3_free);
  }
  cifrar(texto, chave, cifrado, krypt);

  sqlite3_result_text(ctx, cifrado, -1, SQLITE_TRANSIENT);
  sqlite3_free(cifrado);
}

/*
 * Retorna texto decifrado usando criptografia por chave simétrica.
 *
 * O primeiro argumento é o nome do método criptográfico que deve ser
 * "alternate", "naive", "single" ou "usual", e se for omitido, então
 * será usado o método definido em DEFAULT_KRYPT_MODE.
 * Os argumentos seguintes são a chave criptográfica e o texto, nesta
 * ordem.
 *
 * DEC é a função inversa de ENC:
 *
 *    select DEC([método, ]chave, ENC([método, ]chave, texto)) == texto;
*/
static void dec(sqlite3_context *ctx, int argc, sqlite3_value **argv)
{
  krypt_t *krypt;
  const char *chave, *cifrado, *modo;
  char *texto;
  int j = 0;

  assert(argc == 2 || argc == 3);

  if (3 == argc) {
    if (SQLITE_NULL == sqlite3_value_type(argv[j])) {
      sqlite3_result_error(ctx, "nome do modo criptográfico é NULL", -1);
      return ;
    }
    modo = (char *) sqlite3_value_text(argv[j++]);
    if (strlen(modo) == 0) {
      sqlite3_result_error(ctx, "nome do modo criptográfico tem comprimento zero", -1);
      return ;
    }
  } else {
    modo = DEFAULT_KRYPT_MODE;
  }

  if (SQLITE_NULL == sqlite3_value_type(argv[j])) {
    sqlite3_result_error(ctx, "chave criptográfica é NULL", -1);
    return ;
  }
  chave = (char *) sqlite3_value_text(argv[j++]);
  if (strlen(chave) == 0) {
    sqlite3_result_error(ctx, "chave de comprimento zero", -1);
    return ;
  }

  if (SQLITE_NULL == sqlite3_value_type(argv[j])) {
    sqlite3_result_null(ctx);
    return ;
  }
  cifrado = (char *) sqlite3_value_text(argv[j]);

  texto = sqlite3_malloc( strlen(cifrado)*2 );
  if (!texto) {
    sqlite3_result_error_nomem(ctx);
    return ;
  }

  krypt = sqlite3_get_auxdata(ctx, 0);
  if (!krypt) {
    krypt = (krypt_t *) sqlite3_malloc(sizeof(krypt_t));
    if (!krypt) {
      sqlite3_result_error(ctx, "memória insuficiente", -1);
      sqlite3_free(texto);
      return ;
    }
    init_krypt(krypt, modo);
    sqlite3_set_auxdata(ctx, 0, krypt, sqlite3_free);
  }
  decifrar(cifrado, chave, texto, krypt);

  sqlite3_result_text(ctx, texto, -1, SQLITE_TRANSIENT);
  sqlite3_free(texto);
}

int sqlite3_extension_init(sqlite3 *db, char **err, const sqlite3_api_routines *api)
{
  SQLITE_EXTENSION_INIT2(api)

  sqlite3_create_function(db, "MD5",  1, SQLITE_UTF8, NULL, md5, NULL, NULL);
  sqlite3_create_function(db, "ENC", -1, SQLITE_UTF8, NULL, enc, NULL, NULL);
  sqlite3_create_function(db, "DEC", -1, SQLITE_UTF8, NULL, dec, NULL, NULL);

  return 0;
}
