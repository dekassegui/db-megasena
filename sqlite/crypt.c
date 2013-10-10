/*
 * MD5 + funções criptográficas naives no SQLite:
 *
 *    MD5, ENC, DEC, GET_CRYTP, SET_CRYPT
 *
 * Dependências:
 *
 *    pacotes libsqlite3-dev e libssl-dev
 *
 * Compilação:
 *
 *    gcc crypt.c -Wall -fPIC -shared -lm -lcrypto -o crypt.so
 *
 * Uso em arquivos de inicialização ou sessões interativas:
 *
 *    .load "path_to_lib/crypt.so"
 *
 * ou como requisição SQLite:
 *
 *    select load_extension("path_to_lib/crypt.so");
*/
#include <sqlite3ext.h>
SQLITE_EXTENSION_INIT1

#include <string.h>
#include <stdlib.h>
#include <openssl/md5.h>

#if SQLITE_VERSION_NUMBER < 3007011
#define sqlite3_stricmp(a, b) sqlite3_strnicmp((a), (b), strlen(a))
#endif

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

  for (i = 0; i < n; i++)
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
  for (i = 0; i < n; i++)
  {
    t >>= 1;
    if (t & 128) t |= 32768;
  }

  return t >> 8;
}

#define ROT(a, b)  (char) rrotate((unsigned char) (a), ((int) (b)) % 8)

#define LROT(a, b) (char) lrotate((unsigned char) (a), ((int) (b)) % 8)

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

static char twin_cifrar_char(char c, char k)
{
  return c ^ ROT(k, k);
}

static char both_cifrar_char(char c, char k)
{
  return LROT(c, ROT(k, k)) ^ k;
}

static char both_decifrar_char(char c, char k)
{
  return ROT(c ^ k, ROT(k, k));
}

static const char *METHODS[] = \
  { "naive", "usual", "single", "alternate", "twin", "both" };

static const int NUM_METHODS = 6;

typedef struct crypt_s
{
  char *method;
  char (*cifrar_char)(char c, char k);
  char (*decifrar_char)(char c, char k);
}
crypt_t;

static crypt_t engine;  // var global iniciada com NULLs

/*
 * Retorna texto cifrado usando criptografia por chave simétrica, tal que os
 * argumentos são a chave criptográfica e o texto.
 *
 * ENC é a função inversa de DEC:
 *
 *    SELECT ENC(chave, DEC(chave, texto)) == texto;
*/
static void enc(sqlite3_context *ctx, int argc, sqlite3_value **argv)
{
  const char *chave, *texto;
  char *cifrado;
  int j, k;

  if (!engine.method) {
    sqlite3_result_error(ctx, "método criptográfico não definido", -1);
    return ;
  }

  if (SQLITE_NULL == sqlite3_value_type(argv[0])) {
    sqlite3_result_error(ctx, "chave criptográfica é NULL", -1);
    return ;
  }
  chave = (char *) sqlite3_value_text(argv[0]);
  if (strlen(chave) == 0) {
    sqlite3_result_error(ctx, "chave de comprimento zero", -1);
    return ;
  }

  if (SQLITE_NULL == sqlite3_value_type(argv[1])) {
    sqlite3_result_null(ctx);
    return ;
  }
  texto = (char *) sqlite3_value_text(argv[1]);

  cifrado = sqlite3_malloc( strlen(texto) + 1 );
  if (!cifrado) {
    sqlite3_result_error_nomem(ctx);
    return ;
  }

  if (argc >= 0) {
    for (k = strlen(chave), j = 0; texto[j]; ++j)
    {
      cifrado[j] = engine.cifrar_char(texto[j], chave[j%k]);
    }
  } else {
    for (k = strlen(chave), j = 0; texto[j]; ++j)
    {
      cifrado[j] = engine.decifrar_char(texto[j], chave[j%k]);
    }
  }
  cifrado[j] = 0;

  sqlite3_result_text(ctx, cifrado, -1, SQLITE_TRANSIENT);
  sqlite3_free(cifrado);
}

/*
 * Retorna texto decifrado usando criptografia por chave simétrica, tal que os
 * argumentos são a chave criptográfica e o texto.
 *
 * DEC é a função inversa de ENC:
 *
 *    select DEC(chave, ENC(chave, texto)) == texto;
*/
static void dec(sqlite3_context *ctx, int argc, sqlite3_value **argv)
{
  enc(ctx, -argc, argv);
}

/*
 * Informa o nome do método incumbente de criptografia de caracteres, senão
 * notifica a indefinição como erro, cancelando requisições encadeadas.
*/
static void get_crypt(sqlite3_context *ctx, int argc, sqlite3_value **argv)
{
  if (engine.method) {
    sqlite3_result_text(ctx, engine.method, -1, SQLITE_TRANSIENT);
  } else {
    sqlite3_result_error(ctx, "método criptográfico não definido", -1);
  }
}

/*
 * Configura o engine de criptografia de caracteres vinculando as funções do
 * método que corresponde ao argumento.
*/
static void bind_method(const char *method)
{
  if (sqlite3_stricmp(method, "both") == 0) {
    engine.method = "both";
    engine.cifrar_char = both_cifrar_char;
    engine.decifrar_char = both_decifrar_char;
  } else if (sqlite3_stricmp(method, "twin") == 0) {
    engine.method = "twin";
    engine.cifrar_char = twin_cifrar_char;
    engine.decifrar_char = twin_cifrar_char;
  } else if (sqlite3_stricmp(method, "single") == 0) {
    engine.method = "single";
    engine.cifrar_char = single_cifrar_char;
    engine.decifrar_char = single_decifrar_char;
  } else if (sqlite3_stricmp(method, "usual") == 0) {
    engine.method = "usual";
    engine.cifrar_char = usual_cifrar_char;
    engine.decifrar_char = usual_decifrar_char;
  } else if (sqlite3_stricmp(method, "alternate") == 0) {
    engine.method = "alternate";
    engine.cifrar_char = alternate_cifrar_char;
    engine.decifrar_char = alternate_decifrar_char;
  } else if (sqlite3_stricmp(method, "naive") == 0) {
    engine.method = "naive";
    engine.cifrar_char = naive_cifrar_char;
    engine.decifrar_char = naive_cifrar_char;
  }
}

#define IS_SPACE(c) (((c) == 0x20) || (((c) >= 0x09) && ((c) <= 0x0D)))

/*
 * Retorna substring da original sem espaços redundantes nas extremidades.
 *
 * +) São considerados "espaço" os caracteres : SPACE, HT, LF, VT, FF, CR
 *    que é subconjunto do "Whitespaces Unicode", contendo os caracteres
 *    whitespace definidos na "Linguagem C" agregado do CR.
 * +) Se a original é NULL ou contém apenas espaços será retornado NULL
 *    portanto recomenda-se testar o resultado.
 * !) A substring retornada deve ser liberada após "casting" apropriado,
 *    pois ocupa memória alocada no contexto de execução dessa extensão.
*/
static const char *trim(const char *src)
{
  char *e = NULL;
  if (src) {
    while (IS_SPACE(*src)) ++src;
    if (*src) {
      int n = 1;
      for (e = (char *) src + 1; *e; ++e) if (!IS_SPACE(*e)) n = e - src + 1;
      e = sqlite3_malloc(n+1);
      e[n] = 0;
      memcpy(e, src, n); /* while (--n >= 0) e[n] = src[n]; */
    }
  }
  return e;
}

/*
 * Procedimento para definir o método incumbente de criptografia de caracteres
 * conforme seu nome que é o argumento único esperado e se for ilegal, o erro
 * será notificado seguido da lista de nomes válidos.
*/
static void set_crypt(sqlite3_context *ctx, int argc, sqlite3_value **argv)
{
  char *s, *z = NULL;
  int j;

  if (SQLITE_NULL == sqlite3_value_type(argv[0])) {
    z = "o argumento é um NULL";
  } else {
    s = (char *) trim((const char *) sqlite3_value_text(argv[0]));
    if (!s) {
      z ="o argumento é uma string vazia";
    } else if (!engine.method || sqlite3_stricmp(s, engine.method)) {
      // pesquisa a string no array de nomes de métodos
      for (j = 0; j < NUM_METHODS && sqlite3_stricmp(s, METHODS[j]); ++j) ;
      if (j == NUM_METHODS) {
        z = "método é desconhecido";
      } else {
        // vincula o método ao engine de criptografia
        bind_method(s);
#if SQLITE_VERSION_NUMBER >= 3007013
{
  // preserva o nome do método para uso persistente entre sessões
  sqlite3_stmt *stmt;
  sqlite3_prepare_v2(sqlite3_context_db_handle(ctx),
    "INSERT OR REPLACE INTO properties VALUES ('method', ?);", -1, &stmt, NULL);
  sqlite3_bind_text(stmt, 1, s, -1, NULL);
  sqlite3_step(stmt);
  sqlite3_finalize(stmt);
}
#endif
      }
    }
    sqlite3_free(s);
  }
  if (z) {
    // montagem da lista textual dos nomes de métodos disponíveis
    // começando pelo cálculo da quantidade de bytes necessária
    int len[NUM_METHODS], n = (NUM_METHODS - 1) * 2;
    for (j = 0; j < NUM_METHODS; ++j) n += len[j] = strlen(METHODS[j]);
    s = (char *) sqlite3_malloc(n+1);
    memcpy(s, METHODS[0], n = len[0]);  // agrega o primeiro item
    for (j = 1; j < NUM_METHODS; ++j) {
      memcpy(s+n, ", ", 2);             // agrega separador
      n += 2;
      memcpy(s+n, METHODS[j], len[j]);  // agrega o j-ésimo item
      n += len[j];
    }
    s[n] = 0;
    z = sqlite3_mprintf("%s.\nMétodos disponíveis: %z.", z, s);
    sqlite3_result_error(ctx, z, -1);
    sqlite3_free(z);
  }
}

int sqlite3_extension_init(sqlite3 *db, char **err, const sqlite3_api_routines *api)
{
  SQLITE_EXTENSION_INIT2(api)

  sqlite3_create_function(db, "MD5",  1, SQLITE_UTF8, NULL, md5, NULL, NULL);
  sqlite3_create_function(db, "ENC",  2, SQLITE_UTF8, NULL, enc, NULL, NULL);
  sqlite3_create_function(db, "DEC",  2, SQLITE_UTF8, NULL, dec, NULL, NULL);
  sqlite3_create_function(db, "GET_CRYPT", 0, SQLITE_UTF8, NULL, get_crypt, NULL, NULL);
  sqlite3_create_function(db, "SET_CRYPT", 1, SQLITE_UTF8, NULL, set_crypt, NULL, NULL);

#if SQLITE_VERSION_NUMBER >= 3007013
  {
    const char *CREATE_TABLE = "CREATE TABLE IF NOT EXISTS properties" \
      "(key TEXT NOT NULL UNIQUE ON CONFLICT IGNORE, value TEXT NOT NULL);";

    sqlite3_stmt *stmt;
    char *s, *z;
    int n;

    /* check-up do esquema da tabela PROPERTIES */

    sqlite3_prepare_v2(db, "SELECT sql FROM sqlite_master WHERE " \
      "type == 'table' AND name == 'properties';", -1, &stmt, NULL);
    if (SQLITE_ROW == sqlite3_step(stmt)) {
      for (s = (char *) sqlite3_column_text(stmt, 0); *s != '('; ++s) ;
      for (z = (char *) CREATE_TABLE; *z != '('; ++z) ;
      if (sqlite3_strnicmp(s, z, strlen(s))) {
        sqlite3_prepare_v2(db,
          "DROP TABLE IF EXISTS properties;", -1, &stmt, NULL);
        sqlite3_step(stmt);
      }
    }

    /* criação redundante da tabela */

    sqlite3_prepare_v2(db, CREATE_TABLE, -1, &stmt, NULL);
    sqlite3_step(stmt);

    /* configuração persistente do engine criptográfico */

    sqlite3_prepare_v2(db,
      "SELECT value FROM properties WHERE key == 'method';", -1, &stmt, NULL);
    if (sqlite3_step(stmt) == SQLITE_ROW) {
      // recupera valor associado a chave 'method'
      s = (char *) sqlite3_column_text(stmt, 0);
      // pesquisa o valor no array de nomes de métodos
      for (n = 0; n < NUM_METHODS; ++n) {
        if (sqlite3_stricmp(s, METHODS[n]) == 0) {
          bind_method(s);
          break;
        }
      }
    }

    sqlite3_finalize(stmt);
  }
#endif

  return 0;
}
