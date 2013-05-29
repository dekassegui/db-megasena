#!/usr/bin/Rscript

library(RSQLite)
drv <- dbDriver('SQLite')
con <- sqliteNewConnection(drv, dbname='megasena.sqlite')

rs <- dbGetQuery(con, 'select count(concurso) from concursos')
n=as.integer(rs)

rs <- dbGetQuery(con, paste(
        'SELECT M-N, N FROM',
        '(SELECT count(*) AS M, SUM(dezena % 2) AS N FROM dezenas_sorteadas)'))

sqliteCloseConnection(con)

dimnames(rs) <- list('frequência', paridades=c('even', 'odd'))

print(sprintf('Paridades das Dezenas em %d Concursos da Mega-Sena:', n), quote=FALSE)
cat('\n')
print(rs)
cat('\n')
print('H0: A proporção de pares é 0.5.', quote=FALSE)
print('HA: A proporção de pares não é 0.5.', quote=FALSE)

rs <- prop.test(as.matrix(rs), p=0.5, correct=FALSE)
print(rs)

if (rs$p.value > 0.05) status='não ' else status=''
print(sprintf('Conclusão: %srejeitamos H0 ao nível de significância de 5%%.', status), quote=FALSE)
