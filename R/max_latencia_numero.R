#!/usr/bin/Rscript --no-init-file

library(RSQLite)
con <- dbConnect(SQLite(), "megasena.sqlite")

args = commandArgs(TRUE)
numero = as.numeric(args[1])
if (is.na(numero)) {
  cat("Error: No arguments to run.\n")
} else {

  if(numero < 1) numero=1 else if (numero > 60) numero=60
  cat("Número: ", numero, "\n")

  query <- paste("
WITH RECURSIVE this (z, s) AS (
    SELECT serie, serie || '0' FROM (
      SELECT GROUP_CONCAT(NOT(dezenas>>(", numero, "-1)&1), '') AS serie
      FROM dezenas_juntadas
    )
  ), zero (j) AS (
    SELECT INSTR(z, '00') FROM this
    UNION ALL
    SELECT j + INSTR(SUBSTR(z, j+1), '00') AS k FROM this, zero WHERE k > j
  ), core (i) AS (
    SELECT INSTR(s, '1') FROM this
    UNION ALL
    SELECT i + INSTR(SUBSTR(s, i), '01') AS k FROM this, core WHERE k > i
  ) SELECT INSTR(SUBSTR(s, i), '0')-1 AS latencia FROM this, core
    UNION ALL
    SELECT 0 AS latencia FROM zero")

  datum <- dbGetQuery(con, query)
  dbDisconnect(con)

  tabela <- table(datum$latencia)
  cat('\nFrequências das latências:\n')
  print(addmargins(tabela))
  cat('\n')
  print(summary(datum$latencia))
  cat('\n')

}