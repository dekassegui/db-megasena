#!/usr/bin/Rscript --no-init-file

library(RSQLite)
con <- dbConnect(SQLite(), dbname='megasena.sqlite')
concurso <- dbGetQuery(con, 'SELECT MAX(concurso) FROM concursos')[1,1]
latencias <- dbGetQuery(con, 'SELECT latencia FROM info_dezenas')
# "prepared statement" para requisitar as máximas latências de cada número
rs <- dbSendQuery(con, "SELECT MAX(latencia) AS maxLatencia FROM (
  WITH RECURSIVE this (s) AS (
    SELECT GROUP_CONCAT(NOT(dezenas >> ($NUMERO - 1) & 1), '') || '0'
    FROM dezenas_juntadas
  ), core (i) AS (
    SELECT INSTR(s, '1') FROM this
    UNION ALL
    SELECT i + INSTR(SUBSTR(s, i), '01') AS k FROM this, core WHERE k > i
  ) SELECT INSTR(SUBSTR(s, i), '0')-1 AS latencia FROM this, core
)")
# loop das requisições das máximas latências históricas de cada número
for (n in 1:60) {
  dbBind(rs, list('NUMERO'=n))
  dat <- dbFetch(rs)
  latencias[n, "maxLatencia"] <- dat$maxLatencia
}
dbClearResult(rs)
dbDisconnect(con)

latencias$dif <- latencias$maxLatencia - latencias$latencia

# dispositivo de renderização: arquivo PNG
png(filename='img/latencias.png', width=1200, height=600, pointsize=12, family="Quicksand")

par(mar=c(2.25, 3.5, 3, 1))

major=(max(latencias$maxLatencia) %/% 10 + 1) * 10

bar <- barplot(
  t(latencias[, c('latencia', 'dif')]),
  main=list('Latências dos Números', cex=2.5, font=1, col='black'),
  border="gray80", space=.25, col=c('orange1', 'gold'),
  xaxt='n', yaxt='n',   # evita renderização default dos eixos
  ylim=c(0, major)
)

axis(
  1, at=bar, labels=c(sprintf('%02d', 1:60)),
  mgp=c(0, .75, 0), col="transparent",
  cex.axis=1.2775, font.axis=2, col.axis="orangered4"
)

# renderiza o eixo Y com visual amigável
y <- seq(0, major, 10)
axis(
  2, at=y, las=2, col="gray10",
  cex.axis=1.25, font.axis=2, col.axis="orangered3"
)
# adiciona "tick marks" extras no eixo Y
rug(head(y,-1)+5, side=2, ticksize=-.01, col="grey10", lwd=1)

# renderiza linhas de referência ordinárias
abline(h=c(y[y != 10], y+5), col="gray84", lty="dotted")
# renderiza texto e linha da esperança das latências = 60 / 6 = 10
abline(h=10, col="dodgerblue", lty="dotted")
text(par("usr")[2], 10, "esperança", adj=c(1, -0.5), cex=.8, font=2, col="dodgerblue")

# adiciona "box & whiskers" antes da primeira coluna
bp <- boxplot(
  latencias$latencia, outline=T, frame.plot=F, add=T, at=-1.25,
  border="darkred", col=c("#ffddbb"), yaxt='n'
)

abline(h=bp$stats, col="#ff000040", lty="dotted")

legend(
  x="topright", inset=0, box.col="#cccccc", box.lwd=1, bg="white",
  border="#b0b0b0", fill=c("orange1", "gold"), x.intersp=.5,
  legend=c("atual", "máxima histórica"), cex=1.125, text.col="black"
)

mtext(
  paste("Mega-Sena", concurso), side=4, adj=.5, line=-.75,
  cex=2.75, font=1, col='orangered'
)

dev.off()
