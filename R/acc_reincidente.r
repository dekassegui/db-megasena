#!/usr/bin/Rscript

library(RSQLite)
drv <- dbDriver('SQLite')
con <- sqliteNewConnection(drv, dbname='megasena.sqlite')

rs <- dbGetQuery(con, 'select count(concurso) from concursos')
n=as.integer(rs)

dbGetQuery(con, paste(
  'CREATE TEMP TABLE t AS',
  'SELECT acumulado, CASE WHEN',
    '(SELECT dezenas FROM dezenas_juntadas WHERE concurso == concursos.concurso)',
    '& (SELECT dezenas FROM dezenas_juntadas WHERE concurso == concursos.concurso-1) > 0',
    'THEN 1 ELSE 0 END AS reincidente FROM concursos'))

rs <- dbGetQuery(con,
        paste(
  'SELECT * FROM',
  '(SELECT COUNT(*) AS a FROM t WHERE acumulado AND reincidente),',
  '(SELECT COUNT(*) AS b FROM t WHERE acumulado AND NOT reincidente),',
  '(SELECT COUNT(*) AS c FROM t WHERE NOT acumulado AND reincidente),',
  '(SELECT COUNT(*) AS d FROM t WHERE NOT acumulado AND NOT reincidente)'))

sqliteCloseConnection(con)

m <- matrix(as.integer(rs[1:4]), ncol=2, byrow=TRUE)
dimnames(m) <- list(acumulado=c('sim','não'), reincidente=c('sim','não'))

cat(sprintf('\nAcumulados X Reincidentes nos %d concursos da Mega-Sena:\n\n', n))
print(m)
cat('\n')
print('H0: Os eventos são independentes entre si.', quote=FALSE)
print('HA: Os eventos não são independentes entre si.', quote=FALSE)

rs <- chisq.test(m, correct=FALSE)
print(rs)

if (rs$p.value > 0.05) status='não ' else status=''
print(sprintf('Conclusão: %srejeitamos H0 ao nível de significância de 5%%.', status), quote=FALSE)
