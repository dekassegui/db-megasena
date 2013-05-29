#!/usr/bin/Rscript
library(RSQLite)
drv <- dbDriver('SQLite')
con <- sqliteNewConnection(drv, dbname='megasena.sqlite')

rs <- dbGetQuery(con, 'select frequencia from info_dezenas')
frequencias <- as.vector( rs[,] )

rs <- dbGetQuery(con, 'select count(concurso) from concursos')
title=sprintf('Frequências das Dezenas em %d Concursos da Mega-Sena', as.integer(rs))

sqliteCloseConnection(con)

lbl <- vector(mode='character', length=60)
for (ndx in 1:60) lbl[ndx] = sprintf('%02d', ndx)

gd <- barplot(
  frequencias,
  main=title, ylab='frequência', xlab='dezenas',
  names.arg=lbl,
  border=c('#CC0000', '#CC00CC', '#FF6600', '#009933', '#0066FF'),
  space=4
)

