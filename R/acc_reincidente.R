#!/usr/bin/Rscript

library(RSQLite)
con <- sqliteNewConnection(dbDriver('SQLite'), dbname='megasena.sqlite')

rs <- dbGetQuery(con, 'SELECT COUNT(concurso) FROM concursos')
n=as.integer(rs)

dbGetQuery(con, paste(
  'CREATE TEMP TABLE t AS',
  'SELECT acumulado, CASE WHEN',
    '(SELECT dezenas FROM dezenas_juntadas WHERE concurso == concursos.concurso)',
    '& (SELECT dezenas FROM dezenas_juntadas WHERE concurso == concursos.concurso-1) > 0',
    'THEN 1 ELSE 0 END AS reincidente FROM concursos'))

rs <- dbGetQuery(con, paste(
  'SELECT * FROM',
  '(SELECT COUNT(*) AS a FROM t WHERE acumulado AND reincidente),',
  '(SELECT COUNT(*) AS b FROM t WHERE acumulado AND NOT reincidente),',
  '(SELECT COUNT(*) AS c FROM t WHERE NOT acumulado AND reincidente),',
  '(SELECT COUNT(*) AS d FROM t WHERE NOT acumulado AND NOT reincidente)'))

sqliteCloseConnection(con)

m <- matrix(as.integer(rs[1:4]), ncol=2, byrow=TRUE)
dimnames(m) <- list(' acumulado'=c('sim','não'), reincidente=c('sim','não'))
teste <- chisq.test(m, correct=FALSE)

cat('Acumulados X Reincidentes nos', n, 'concursos da Mega-Sena:\n\n')
addmargins(m)
cat('\nTeste de Independência entre Eventos:\n')
cat('\n', 'H0: Os eventos são independentes.')
cat('\n', 'HA: Os eventos não são independentes.')
cat('\n\n\t', sprintf('X-square = %.4f', teste$statistic))
cat('\n\t', sprintf('      df = %d', teste$parameter))
cat('\n\t', sprintf(' p-value = %.4f', teste$p.value))

if (teste$p.value > 0.05) action='Não rejeitamos' else action='Rejeitamos'
cat('\n\n', 'Conclusão:', action, 'H0 conforme evidências estatísticas.\n\n')
