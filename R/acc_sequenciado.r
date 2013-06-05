#!/usr/bin/Rscript

library(RSQLite)
con <- sqliteNewConnection(drv <- dbDriver('SQLite'), dbname='megasena.sqlite', loadable.extensions=TRUE)
dbGetQuery(con, 'SELECT LOAD_EXTENSION("./sqlite/more-functions.so")')

rs <- dbGetQuery(con, 'SELECT COUNT(concurso) FROM concursos')
n=as.integer(rs)

dbGetQuery(con, paste(
  'CREATE TEMP TABLE t AS',
  'SELECT acumulado, MASK60(dezenas) LIKE "%11%" AS sequenciado',
  'FROM concursos NATURAL JOIN dezenas_juntadas'))

rs <- dbGetQuery(con, paste(
  'SELECT * FROM',
  '(SELECT COUNT(*) FROM t WHERE acumulado AND sequenciado),',
  '(SELECT COUNT(*) FROM t WHERE acumulado AND NOT sequenciado),',
  '(SELECT COUNT(*) FROM t WHERE NOT acumulado AND sequenciado),',
  '(SELECT COUNT(*) FROM t WHERE NOT acumulado AND NOT sequenciado)'))

sqliteCloseConnection(con)

m <- matrix(as.integer(rs[1:4]), ncol=2, byrow=TRUE)
dimnames(m) <- list(' acumulado'=c('sim','não'), sequenciado=c('sim','não'))
teste <- chisq.test(m, correct=TRUE)

cat('Acumulados X Sequenciados nos', n, 'concursos da Mega-Sena:\n\n')
addmargins(m)

cat('\nTeste de Independência entre Eventos:\n')
cat('\n', 'H0: Os eventos são independentes.')
cat('\n', 'HA: Os eventos não são independentes.')
cat('\n\n\t', sprintf('X-square = %.4f', teste$statistic))
cat('\n\t', sprintf('      df = %d', teste$parameter))
cat('\n\t', sprintf(' p-value = %.4f', teste$p.value))

if (teste$p.value > 0.05) action='Não rejeitamos' else action='Rejeitamos'
cat('\n\n', 'Conclusão:', action, 'H0 conforme evidências estatísticas.\n\n')
