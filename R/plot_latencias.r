#!/usr/bin/Rscript

library(RSQLite, quietly=TRUE)
con <- sqliteNewConnection(dbDriver('SQLite'), dbname='megasena.sqlite')

rs <- dbSendQuery(con, 'SELECT max(concurso) as NREC FROM concursos')
nrec <- fetch(rs, n = -1)$NREC

rs <- dbSendQuery(con, 'SELECT dezena, latencia FROM info_dezenas')
datum <- fetch(rs, n = -1)

dbClearResult(rs)
sqliteCloseConnection(con)

titulo = paste('Latências das dezenas da Mega-Sena em', nrec, 'concursos')

png(filename='latencias.png', width=600, height=600, pointsize=13)

plot(
  datum,
  main=titulo,
  ylab='latência',
  xlab='dezenas',
  col='blue',
  type='h',
  xlim=c(1, 60)
)

# renderiza a linha horizontal esperança das latências
abline(
  h=10,
  col='red',
  lty=3
)

d <- par()$usr

legend(
  3*(d[1]+d[2])/4, d[4],
  bty='n',
  legend=c('esperança'),
  col='red',
  lty=3
)

dev.off()
