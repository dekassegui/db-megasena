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

png(filename='img/latencias.png', width=1000, height=558, pointsize=13)

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

gd <- par()$usr

legend(
  3*(gd[1]+gd[2])/4, 4*gd[4]/5,
  bty='n',
  col='red', lty=3,
  legend=c('esperança')
)

mtext('Made with the R Statistical Computing Environment',
  side=4, adj=0, font=2, cex=.7)

dev.off()
