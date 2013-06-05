#!/usr/bin/Rscript

library(RSQLite, quietly=TRUE)
con <- sqliteNewConnection(dbDriver('SQLite'), dbname='megasena.sqlite')

rs <- dbSendQuery(con, 'SELECT max(concurso) as NREC FROM concursos')
nrec <- fetch(rs, n = -1)$NREC

rs <- dbSendQuery(con, 'SELECT latencia FROM info_dezenas')
datum <- fetch(rs, n = -1)

dbClearResult(rs)
sqliteCloseConnection(con)

titulo = paste('Mega-Sena #', nrec, sep='')

x <- as.vector(datum$latencia)

names(x) <- c(sprintf('%02d', 1:60))

png(filename='latencias.png', width=1000, height=558, pointsize=13)

barplot(
  x,
  main=titulo,
  ylab='latência',
  col=c('gold', 'orange')
)

abline(
  h=10,             # esperança das latências
  col='red', lty=3
)

d <- par()$usr

legend(
  3*(d[1]+d[2])/4, 4*d[4]/5,
  bty='n',
  legend=c('esperança'),
  col='red', lty=3
)

mtext('Made with the R Statistical Computing',
  side=4,
  adj=0,
  font=2,
  cex=.7
)

dev.off()
