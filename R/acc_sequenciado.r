#!/usr/bin/Rscript

library(RSQLite)
drv <- dbDriver('SQLite')
con <- sqliteNewConnection(drv, dbname='megasena.sqlite', loadable.extensions=TRUE)
dbGetQuery(con, 'SELECT LOAD_EXTENSION("./sqlite/more-functions.so")')

rs <- dbGetQuery(con, 'select count(concurso) from concursos')
n=as.integer(rs)

dbGetQuery(con, paste('CREATE TEMP TABLE t AS', 'SELECT acumulado, MASK60(dezenas) LIKE "%11%" AS sequenciado FROM concursos NATURAL JOIN dezenas_juntadas'))

rs <- dbGetQuery(con,
        paste(
  'SELECT * FROM',
  '(SELECT COUNT(*) FROM t WHERE acumulado AND sequenciado),',
  '(SELECT COUNT(*) FROM t WHERE acumulado AND NOT sequenciado),',
  '(SELECT COUNT(*) FROM t WHERE NOT acumulado AND sequenciado),',
  '(SELECT COUNT(*) FROM t WHERE NOT acumulado AND NOT sequenciado)'))

sqliteCloseConnection(con)

m <- matrix(as.integer(rs[1:4]), ncol=2, byrow=TRUE)
dimnames(m) <- list(acumulado=c('sim','não'), sequenciado=c('sim','não'))

cat(sprintf('\nAcumulados X Sequenciados nos %d concursos da Mega-Sena:\n\n', n))
print(m)
cat('\n')
print('H0: Os eventos são independentes entre si.', quote=FALSE)
print('HA: Os eventos não são independentes entre si.', quote=FALSE)

rs <- chisq.test(m, correct=FALSE)
print(rs)

if (rs$p.value > 0.05) status='não ' else status=''
print(sprintf('Conclusão: %srejeitamos H0 ao nível de significância de 5%%.', status), quote=FALSE)
