#!/usr/bin/Rscript

library(RSQLite)
con <- sqliteNewConnection(dbDriver('SQLite'), dbname='megasena.sqlite')

rs <- dbSendQuery(con, 'SELECT COUNT(concurso) AS NREC FROM concursos')
nrec = fetch(rs, n = -1)$NREC
titulo = paste('Frequências das dezenas em', nrec, 'concursos da Mega-Sena')

rs <- dbSendQuery(con, 'SELECT frequencia FROM info_dezenas')
dados <- fetch(rs, n=-1)

dbClearResult(rs)
sqliteCloseConnection(con)

lbl <- vector(mode='character', length=60)
for (ndx in 1:60) lbl[ndx] = sprintf('%02d', ndx)

gd <- barplot(
  dados$frequencia,
  main=titulo,
  ylab='frequência',
  xlab='dezenas', names.arg=lbl,
  border=c('#CC0000', '#CC00CC', '#FF6600', '#009933', '#0066FF'),
  space=4
)
