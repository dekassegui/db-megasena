#!/usr/bin/Rscript

library(RSQLite)
drv <- dbDriver('SQLite')
con <- sqliteNewConnection(drv, dbname='megasena.sqlite')

rs <- dbGetQuery(con, 'select count(concurso) from concursos')
n=as.integer(rs)

rs <- dbGetQuery(con, paste(
  'SELECT ACC, ', n, '-ACC AS WIN FROM',
  '(SELECT SUM(acumulado) AS ACC FROM concursos)'))

sqliteCloseConnection(con)

print(sprintf('Acumulação em %d Concursos da Mega-Sena:', n), quote=FALSE)
cat('\n')
rownames(rs)='count'; print(rs)
cat('\n')
pe=0.77
print(sprintf('H0: A proporção de acumulados é %5.3f.', pe), quote=FALSE)
print(sprintf('HA: A proporção de acumulados não é %5.3f.', pe), quote=FALSE)

rs <- prop.test(as.matrix(rs), p=pe)
print(rs)

if (rs$p.value > 0.05) status='não ' else status=''
print(sprintf('Conclusão: %srejeitamos H0 ao nível de significância de 5%%.', status), quote=FALSE)
