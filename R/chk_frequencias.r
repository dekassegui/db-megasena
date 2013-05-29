#!/usr/bin/Rscript

library(RSQLite)
drv <- dbDriver('SQLite')
con <- sqliteNewConnection(drv, dbname='megasena.sqlite')

rs <- dbGetQuery(con, 'select frequencia from info_dezenas')
frequencias <- as.vector(rs[,])

rs <- dbGetQuery(con, 'select count(concurso) from concursos')

sqliteCloseConnection(con)

print(sprintf('Frequências das Dezenas em %d Concursos da Mega-Sena:', as.integer(rs)), quote=FALSE)
cat('\n', frequencias, '\n')
print('H0: As dezenas tem distribuição uniforme.', quote=FALSE)
print('HA: Existe alguma tendência nos sorteios.', quote=FALSE)

rs <- chisq.test(frequencias, correct=FALSE)
print(rs)

if (rs$p.value > 0.05) status='não ' else status=''
print(sprintf('Conclusão: %srejeitamos H0 ao nível de significância de 5%%.', status), quote=FALSE)
