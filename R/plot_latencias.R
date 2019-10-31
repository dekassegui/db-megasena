#!/usr/bin/Rscript --no-init-file

library(RSQLite)
con <- dbConnect(SQLite(), dbname='megasena.sqlite')
datum <- dbGetQuery(con, 'SELECT max(concurso) as NREC FROM concursos')
nrec <- datum$NREC
datum <- dbGetQuery(con, 'SELECT latencia FROM info_dezenas')
dbDisconnect(con)

x <- as.vector(datum$latencia)
names(x) <- c(sprintf('%02d', 1:60))

png(filename='img/latencias.png', width=1200, height=600, pointsize=12, family="Quicksand")

major=1 + max(x)

barplot(
  x,
  main=list( sprintf('Latências dos Números na Mega-Sena #%d', nrec), cex=1.5, font=2, col='black' ),
  #ylab='latência',
  cex.names=1.25, font.axis=2,
  ylim=c(0, major),
  border='#333333',
  col=c('orange', 'gold'),
  space=.25,
  yaxt='n'
)

axis(
  2,                  # eixo y
  las=2,              # labels dispostos perpendicularmente
  col.axis="black",
  cex.axis=1.25,
  font.axis=2,
  at=c(0, 5, seq(10, major, 10))
)

abline(h=c(5, seq(20, major, 10)), col='darkgray', lty=3)

abline(h=10, col='red', lty=3)

legend("topright", legend="esperança", bty='n', col='red', lty=3)

mtext("Gerado via GNU R-cran.", side=1, adj=1.025, line=4, font=4, cex=1.1, col="slategray")

dev.off()
