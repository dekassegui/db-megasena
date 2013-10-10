/*
 * Funções de calendário com granularidade temporal "dia" no SQLite:
 *
 *    CHKDATE, DATEADD, DATEPART, DATESTR, DIFFDATES, SWAPFORMAT, TIMESTAMP,
 *    TIMEZONE, TODAY, WEEKDAY
 *
 * Compilação:
 *
 *    gcc calendar.c -Wall -fPIC -shared -lm -o calendar.so
 *
 * Uso em arquivos de inicialização ou sessões interativas:
 *
 *    .load "path_to_lib/calendar.so"
 *
 * ou como requisição SQLite:
 *
 *    select load_extension("path_to_lib/calendar.so");
*/
#include <sqlite3ext.h>
SQLITE_EXTENSION_INIT1

#include <stdlib.h>
#include <string.h>
#include <time.h>

#define IS_DIGIT(c) (((c) >= '0') && ((c) <= '9'))

#define IS_SEPARATOR(c) ((c) == '-')

enum date_formats { DD_MM_YYYY = 0, YYYY_MM_DD = 1 };

enum date_components { YEAR = 0, MONTH = 1, DAY = 2 };

/* offsets do ano, mês e dia nas strings de data conforme formato */
static const int OFFSET[2][3] = { { 6, 3, 0 } /* DD-MM-YYYY */,
                                  { 0, 5, 8 } /* YYYY-MM-DD */ };

/* Testa os valores dos componentes explícitos de alguma data. */
static int chkdatefields(int year, int month, int day)
{
  char daysInMonth[] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };

  if (month < 1 || month > 12) return 0;
  if (month == 2)
  {
    daysInMonth[1] = (year%4 == 0 && year%100 != 0) || year%400 == 0 ? 29 : 28;
  }
  return (day > 0 && day <= daysInMonth[month-1]);
}

/*
 * Validação dos componentes da data expressa na string 'date' terminada com
 * NUL, condicionada ao check-up sequencial do seu formato, conforme valor do
 * inteiro 'as_isodate'.
*/
static int chkdate(const char *date, const int as_isodate)
{
  if (date) {
    const int x = (as_isodate > 0) ? YYYY_MM_DD : DD_MM_YYYY;
    int j, k = OFFSET[x][MONTH] - 1;
    for (j = 0; j < k && IS_DIGIT(date[j]); ++j) ;
    if (j == k && IS_SEPARATOR(date[j])) {
      k = OFFSET[x][x ? DAY : YEAR] - 1;
      for (j++; j < k && IS_DIGIT(date[j]); ++j) ;
      if (j == k && IS_SEPARATOR(date[j])) {
        for (k = 10, ++j; j < k && IS_DIGIT(date[j]); ++j) ;
        if (j == k && date[j] == 0)
          return chkdatefields(atoi(date + OFFSET[x][YEAR]),
                               atoi(date + OFFSET[x][MONTH]),
                               atoi(date + OFFSET[x][DAY]));
      }
    }
  }
  return 0;
}

/*
 * Validação completa da data no primeiro argumento de tipo string, num dos dois
 * formatos considerados, opcionalmente especificado pelo segundo argumento de
 * tipo inteiro tal que; sendo maior que "0", então o formato é DD-MM-YYYY senão
 * o formato é o default YYYY-MM-DD.
*/
static void chkdateFunc(sqlite3_context *ctx, int argc, sqlite3_value **argv)
{
  const char *z;
  int as_isodate = YYYY_MM_DD;

  if (argc < 1 || argc > 2) {
    sqlite3_result_error(ctx, "número de argumentos incorreto." \
      "\nEsta função requer ao menos um e no máximo dois argumentos.", -1);
    return ;
  }
  if (SQLITE3_TEXT != sqlite3_value_type(argv[0])) {
    z = (argc == 1) ? "argumento não é do tipo text"
                    : "primeiro argumento não é do tipo text";
    sqlite3_result_error(ctx, z, -1);
    return ;
  }
  z = (const char *) sqlite3_value_text(argv[0]);
  if (argc == 2) {
    if (SQLITE_INTEGER != sqlite3_value_type(argv[1])) {
      sqlite3_result_error(ctx, "segundo argumento não é do tipo inteiro", -1);
      return ;
    }
    as_isodate = (sqlite3_value_int(argv[1]) > 0) ? DD_MM_YYYY : YYYY_MM_DD;
  }
  sqlite3_result_int(ctx, chkdate(z, as_isodate));
}

/* Função complementar de "datefield" evitando código redundante. */
static int chk_2nd_argument(sqlite3_context *ctx, int *f, sqlite3_value **argv)
{
  /* verifica se o segundo argumento é do tipo inteiro */
  if (SQLITE_INTEGER != sqlite3_value_type(argv[1])) {
    sqlite3_result_error(ctx, "segundo argumento não é do tipo inteiro", -1);
    return 0;
  }
  *f = sqlite3_value_int(argv[1]);
  /* verifica o número de ordem do componente a extrair */
  if (*f < YEAR || *f > DAY) {
    sqlite3_result_error(ctx, "número de ordem do componente é incorreto." \
      "\nUse 0 para extrair o ANO, 1 para extrair o mês e 2 para extrair o " \
      " dia.", -1);
    return 0;
  }
  return 1;
}

/*
 * Extrai valor numérico de componente de data representada numa string com
 * formato YYYY-MM-DD ou DD-MM-YYYY, ou expressa pelo seu número inteiro de
 * segundos decorridos na era Unix aka "epoch", "timestamp" ou "unixtime".
 * O primeiro argumento é a data e o segundo é o número de ordem do componente
 * intencionado tal que; "0" extrai o ano, "1" extrai o mês e "2" extrai o dia.
*/
static void datefield(sqlite3_context *ctx, int argc, sqlite3_value **argv)
{
  int f, rz;

  if (SQLITE_INTEGER == sqlite3_value_type(argv[0]))
  {
    if (chk_2nd_argument(ctx, &f, argv) == 0) return ;
    time_t seconds = (time_t) sqlite3_value_int64(argv[0]);
    struct tm *time = localtime(&seconds);
    if (YEAR == f) {
      rz = time->tm_year + 1900;
    } else if (MONTH == f) {
      rz = time->tm_mon + 1;
    } else {
      rz = time->tm_mday;
    }
  } else {
    char *date;
    int x;
    if (SQLITE3_TEXT != sqlite3_value_type(argv[0])) {
      sqlite3_result_error(ctx, "primeiro argumento não é do tipo text", -1);
      return ;
    }
    date = (char *) sqlite3_value_text(argv[0]);
    x = chkdate(date, YYYY_MM_DD);
    if (x == 0 && chkdate(date, DD_MM_YYYY) == 0) {
      sqlite3_result_error(ctx, "primeiro argumento não contém data valida", -1);
      return ;
    }
    if (chk_2nd_argument(ctx, &f, argv) == 0) return ;
    rz = atoi(date + OFFSET[x][f]);
  }
  sqlite3_result_int(ctx, rz);
}

/*
 * Computa o unixtime da string de data no formato YYYY-MM-DD ou DD-MM-YYYY,
 * no instante ZERO do dia, relevando a "timezone" e "daylight saving time"
 * se disponíveis no sistema operacional.
*/
static time_t datestring_to_nixtime(char *date)
{
  const enum date_formats x = IS_SEPARATOR(date[4]) ? YYYY_MM_DD : DD_MM_YYYY;
  time_t curtime = time(NULL);
  struct tm *broken_time = localtime(&curtime);
  broken_time->tm_year = atoi(date + OFFSET[x][YEAR]) - 1900;
  broken_time->tm_mon  = atoi(date + OFFSET[x][MONTH]) - 1;
  broken_time->tm_mday = atoi(date + OFFSET[x][DAY]);
  broken_time->tm_hour = broken_time->tm_min = broken_time->tm_sec = 0;
  return mktime(broken_time);
}

/*
 * Retorna o número de segundos decorridos na era Unix, aka "epoch", "timestamp"
 * ou "unixtime"; da data contida no argumento de tipo string com formato
 * YYYY-MM-DD ou DD-MM-YYYY.
*/
static void nixtime(sqlite3_context *ctx, int argc, sqlite3_value **argv)
{
  if (SQLITE3_TEXT == sqlite3_value_type(argv[0])) {
    char *date = (char *) sqlite3_value_text(argv[0]);
    if (chkdate(date, YYYY_MM_DD) || chkdate(date, DD_MM_YYYY)) {
      sqlite3_result_int64(ctx, (long int) datestring_to_nixtime(date));
    } else {
      sqlite3_result_error(ctx, "argumento não contém data valida", -1);
    }
  } else {
    sqlite3_result_error(ctx, "argumento não é do tipo text", -1);
  }
}

/*
 * Retorna string de data no formato DD-MM-YYYY ou YYYY-MM-DD, sendo o primeiro
 * argumento o seu número de segundos na era Unix, seguido de valor zero-um que
 * indica o formato desejado, armazenando o resultado no buffer apontado pelo
 * último argumento, que ao menos deve conter 11 bytes.
*/
static char *nixtime_to_datestring(time_t seconds, int as_isodate, char *buf)
{
  struct tm *time = localtime(&seconds);
  const char *format = (as_isodate == YYYY_MM_DD) ? "%Y-%m-%d" : "%d-%m-%Y";
  (void) strftime(buf, 11, format, time);
  return buf;
}

/*
 * Retorna string representando data cujo número inteiro de segundos decorridos
 * na era Unix é o valor do primeiro argumento e seu formato, conforme valor do
 * segundo argumento opcional tal que; se for um número inteiro maior que "0",
 * então terá formato DD-MM-YYYY, senão terá o formato default YYYY-MM-DD.
*/
static void datestr(sqlite3_context *ctx, int argc, sqlite3_value **argv)
{
  time_t seconds;
  char *date;
  int as_isodate = YYYY_MM_DD;

  if (argc < 1 || argc > 2) {
    sqlite3_result_error(ctx, "número de argumentos incorreto." \
      "\nEsta função requer ao menos um e no máximo dois argumentos.", -1);
    return ;
  }
  if (SQLITE_INTEGER != sqlite3_value_type(argv[0])) {
    sqlite3_result_error(ctx, "primeiro argumento não é do tipo inteiro", -1);
    return ;
  }
  if (argc == 2) {
    if (SQLITE_INTEGER != sqlite3_value_type(argv[1])) {
      sqlite3_result_error(ctx, "segundo argumento não é do tipo inteiro", -1);
      return ;
    }
    as_isodate = (sqlite3_value_int(argv[1]) > 0) ? DD_MM_YYYY : YYYY_MM_DD;
  }
  seconds = (time_t) sqlite3_value_int64(argv[0]);
  date = (char *) sqlite3_malloc(11);
  nixtime_to_datestring(seconds, as_isodate, date);
  sqlite3_result_text(ctx, date, -1, SQLITE_TRANSIENT);
  sqlite3_free(date);
}

#define WORD(ptr) *((unsigned short int *) (ptr))

#define SWAP(a, b) WORD(a) ^= WORD(b), WORD(b) ^= WORD(a), WORD(a) ^= WORD(b)

/*
 * Alterna o formato de data representada como string.
*/
static void swap_format(sqlite3_context *ctx, int argc, sqlite3_value **argv)
{
  char *date;
  int j;

  if (SQLITE3_TEXT != sqlite3_value_type(argv[0])) {
    sqlite3_result_error(ctx, "argumento não é do tipo text", -1);
    return ;
  }
  date = (char *) sqlite3_value_text(argv[0]);
  if (chkdate(date, YYYY_MM_DD)) {
    SWAP(date, date+8);
    for (j = 4; j <= 8; j += 2) SWAP(date+j, date+j-2);
  } else if (chkdate(date, DD_MM_YYYY)) {
    for (j = 8; j >= 4; j -= 2) SWAP(date+j, date+j-2);
    SWAP(date, date+8);
  } else {
    sqlite3_result_error(ctx, "argumento não contém data valida", -1);
    return ;
  }
  sqlite3_result_text(ctx, date, -1, SQLITE_TRANSIENT);
}

/*
 * Retorna o número de dias inteiros entre duas datas, indiferente aos tipos
 * dos argumentos que podem ser inteiro ou string de data no formato YYYY-MM-DD
 * ou DD-MM-YYYY.
*/
static void days_between_dates(ctx, argc, argv)
  sqlite3_context *ctx; int argc; sqlite3_value **argv;
{
  time_t seconds[2];
  char *date;
  int j;

  for (j = 0; j < 2; ++j) {
    if (SQLITE3_TEXT == sqlite3_value_type(argv[j])) {
      date = (char *) sqlite3_value_text(argv[j]);
      if (chkdate(date, YYYY_MM_DD) || chkdate(date, DD_MM_YYYY)) {
        seconds[j] = datestring_to_nixtime(date);
      } else {
        char *z = sqlite3_mprintf("argumento #%d nao contém data valida", j+1);
        sqlite3_result_error(ctx, z, -1);
        sqlite3_free(z);
        return ;
      }
    } else if (SQLITE_INTEGER == sqlite3_value_type(argv[j])) {
      seconds[j] = (time_t) sqlite3_value_int64(argv[j]);
    }
  }
  sqlite3_result_int(ctx, difftime(seconds[1], seconds[0]) / 86400);
}

/*
 * Retorna o nome abreviado do dia da semana de data expressa com seu número
 * inteiro de segundos decorridos na era Unix ou representada como string no
 * formato YYYY-MM-DD ou DD-MM-YYYY.
*/
static void weekday(sqlite3_context *ctx, int argc, sqlite3_value **argv)
{
  const char *WEEKDAY[7] = { "Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb" };
  struct tm *time;
  time_t seconds;

  if (SQLITE_INTEGER == sqlite3_value_type(argv[0])) {
    seconds = (time_t) sqlite3_value_int64(argv[0]);
  } else if (SQLITE3_TEXT == sqlite3_value_type(argv[0])) {
    char *date = (char *) sqlite3_value_text(argv[0]);
    if (chkdate(date, YYYY_MM_DD) || chkdate(date, DD_MM_YYYY)) {
      seconds = datestring_to_nixtime(date);
    } else {
      sqlite3_result_error(ctx, "argumento não contém data valida", -1);
      return ;
    }
  }
  time = localtime(&seconds);
  sqlite3_result_text(ctx, WEEKDAY[time->tm_wday], -1, SQLITE_TRANSIENT);
}

/*
 * Retorna a data do dia corrente representada como string num dos dois formatos
 * considerados, opcionalmente especificado pelo argumento de tipo inteiro tal
 * que; se maior que 0 o formato é DD-MM-YYYY senão é o default YYYY-MM-DD.
*/
static void today(sqlite3_context *ctx, int argc, sqlite3_value **argv)
{
  int as_isodate = YYYY_MM_DD;

  if (argc > 1) {
    sqlite3_result_error(ctx, "número de argumentos incorreto." \
      "\nEsta função requer no máximo um argumento.", -1);
    return ;
  }
  if (argc == 1) {
    if (SQLITE_INTEGER == sqlite3_value_type(argv[0])) {
      as_isodate = (sqlite3_value_int(argv[0]) > 0) ? DD_MM_YYYY : YYYY_MM_DD;
    } else {
      sqlite3_result_error(ctx, "argumento não é do tipo inteiro", -1);
      return ;
    }
  }
  char *date = (char *) sqlite3_malloc(11);
  time_t seconds = time(NULL);
  nixtime_to_datestring(seconds, as_isodate, date);
  return sqlite3_result_text(ctx, date, -1, SQLITE_TRANSIENT);
  sqlite3_free(date);
}

/*
 * Retorna data no primeiro argumento, incrementada ou decrementada do número de
 * dias no segundo argumento, mantendo o formato original se for string de data
 * senão usa o formato padrão YYYY-MM-DD.
*/
static void dateadd(sqlite3_context *ctx, int argc, sqlite3_value **argv)
{
  char *date;
  long int seconds, ndays;
  int x = YYYY_MM_DD;

  if (SQLITE_INTEGER == sqlite3_value_type(argv[0])) {
    seconds = sqlite3_value_int64(argv[0]);
  } else {
    if (SQLITE3_TEXT != sqlite3_value_type(argv[0])) {
      sqlite3_result_error(ctx, "primeiro argumento não é do tipo text", -1);
      return ;
    }
    date = (char *) sqlite3_value_text(argv[0]);
    x = chkdate(date, YYYY_MM_DD);
    if (!x && !chkdate(date, DD_MM_YYYY)) {
      sqlite3_result_error(ctx, "primeiro argumento não contém data valida", -1);
      return ;
    }
    seconds = (long int) datestring_to_nixtime(date);
  }
  if (SQLITE_INTEGER != sqlite3_value_type(argv[1])) {
    sqlite3_result_error(ctx, "segundo argumento não é do tipo inteiro", -1);
    return ;
  }
  ndays = sqlite3_value_int(argv[1]);
  seconds += ndays * 86400;
  date = (char *) sqlite3_malloc(11);
  nixtime_to_datestring((time_t) seconds, x, date);
  sqlite3_result_text(ctx, date, -1, SQLITE_TRANSIENT);
  sqlite3_free(date);
}

#define FAST_ABS(x) (((x) ^ ((x) >> 31)) - ((x) >> 31))

/*
 * Informa a configuração da "timezone" e "daylight saving time" quando
 * efetiva.
*/
static void timezone_info(sqlite3_context *ctx, int argc, sqlite3_value **argv)
{
  char *z;
  int h, m;
  time_t seconds = time(NULL);
  struct tm *broken_time = localtime(&seconds);
  h = FAST_ABS(timezone);
  m = h % 3600 / 60;
  h /= 3600;
  z = sqlite3_mprintf("%s\nUTC%c%02d:%02d", broken_time->tm_zone, \
                      (((timezone > 0) << 1) + '+'), h, m);
  if (broken_time->tm_isdst) {
    z = sqlite3_mprintf("%z\nObservação: Usando horário de verão.", z);
  }
  sqlite3_result_text(ctx, z, -1, SQLITE_TRANSIENT);
  sqlite3_free(z);
}

int sqlite3_extension_init(db, err, api)
  sqlite3 *db; char **err; const sqlite3_api_routines *api;
{
  SQLITE_EXTENSION_INIT2(api)

  sqlite3_create_function(db, "CHKDATE", -1, SQLITE_UTF8, NULL, chkdateFunc, NULL, NULL);
  sqlite3_create_function(db, "DATEPART", 2, SQLITE_UTF8, NULL, datefield, NULL, NULL);
  sqlite3_create_function(db, "TIMESTAMP", 1, SQLITE_UTF8, NULL, nixtime, NULL, NULL);
  sqlite3_create_function(db, "DATESTR", -1, SQLITE_UTF8, NULL, datestr, NULL, NULL);
  sqlite3_create_function(db, "SWAPFORMAT", 1, SQLITE_UTF8, NULL, swap_format, NULL, NULL);
  sqlite3_create_function(db, "DIFFDATES", 2, SQLITE_UTF8, NULL, days_between_dates, NULL, NULL);
  sqlite3_create_function(db, "WEEKDAY", 1, SQLITE_UTF8, NULL, weekday, NULL, NULL);
  sqlite3_create_function(db, "TODAY", -1, SQLITE_UTF8, NULL, today, NULL, NULL);
  sqlite3_create_function(db, "DATEADD", 2, SQLITE_UTF8, NULL, dateadd, NULL, NULL);
  sqlite3_create_function(db, "TIMEZONE", 0, SQLITE_UTF8, NULL, timezone_info, NULL, NULL);

  return 0;
}
