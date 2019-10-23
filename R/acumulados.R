#!/usr/bin/Rscript --no-init-file

# ACUMULAÇÃO é quando não há aposta vencedora do prêmio principal num concurso.

library(RSQLite)
con <- dbConnect(SQLite(), "megasena.sqlite")
datum <- dbGetQuery(con, "SELECT acumulado FROM concursos")

cat('-- ACUMULAÇÃO nos Concursos da Mega-Sena --\n\n')

tabela <- table(datum)[c('1', '0')]   # permuta colunas priorizando sucessos
dimnames(tabela) <- list(
  'ACUMULADO' = c('S', 'N')   # Sim ou Não + intuitivo
)
cat('Frequências das observações:\n\n')
print(addmargins(tabela))

# proporção de concursos acumulados na hipótese nula
args <- commandArgs(TRUE)
p.null <- ifelse(length(args) > 0,
  as.numeric(args[1]),                    # arbitrário
  round(tabela['S']/sum(tabela)*100)/100) # arredondamento da estimativa

# teste binomial exato
teste <- binom.test(
  tabela,
  alternative = "two.sided",  # p != p.null
  p = p.null
)
print(teste)

# teste de única proporção
# teste = prop.test(
  # tabela,
  # correct = FALSE,            # não aplica correção de Yates
  # alternative = "two.sided",  # p != p.null
  # p = p.null
# )
# print(teste)

# LATÊNCIA DA PREMIAÇÃO é o tamanho -- número de concursos -- da sequência de
# concursos sem aposta vencedora do prêmio principal que precede concurso com
# aposta vencedora, inclusive por expectativa se a sequência ocorre no final da
# série histórica dos concursos e na sequência de dois ou mais concursos com
# apostas vencedoras do prêmio principal a latência de cada a partir do segundo
# é "zero" ou seja; todo concurso com aposta vencedora do prêmio principal tem
# latência maior ou igual a zero.

cat('-- Latências de Premiação da Mega-Sena --\n')

datum <- dbGetQuery(con,
  "WITH RECURSIVE this (z, s) AS (
     SELECT serie, serie || '0' FROM (
       SELECT GROUP_CONCAT(acumulado, '') AS serie FROM concursos
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
dbDisconnect(con)

tabela <- table(datum$latencia)

cat('\nFrequências das latências:\n')
print(addmargins(tabela))
cat('\n')
print(summary(datum$latencia))
cat('\n')
