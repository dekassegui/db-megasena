#!/usr/bin/Rscript --no-init-file

# Máximas latências dos números na série histórica dos concursos da Mega-Sena.

library(RSQLite)
con <- dbConnect(SQLite(), 'megasena.sqlite')
# requisita o número do concurso mais recente
concurso <- dbGetQuery(con, 'SELECT MAX(concurso) FROM concursos')[1,1]
# prepara o vetor das máximas latências dos números
latencias <- vector(mode='integer', length=60)
# "prepared statement" para requisitar as latências históricas de cada número
rs <- dbSendQuery(con, "
WITH RECURSIVE this (s) AS (
    SELECT GROUP_CONCAT(NOT(dezenas >> ($NUMERO - 1) & 1), '') || '0'
    FROM dezenas_juntadas
  ), core (i) AS (
    SELECT INSTR(s, '1') FROM this
    UNION ALL
    SELECT i + INSTR(SUBSTR(s, i), '01') AS k FROM this, core WHERE k > i
  ) SELECT INSTR(SUBSTR(s, i), '0')-1 AS latencia FROM this, core"
)
# loop de preenchimento do vetor das máximas latências de cada número
for (numero in 1:60) {
  dbBind(rs, list('NUMERO'=numero))
  dat <- dbFetch(rs)
  latencias[numero] = max(dat$latencia)
}
dbClearResult(rs)
dbDisconnect(con)
rm(con, rs, dat)

if (interactive()) {
  X11(display=":0.0", width=12, height=6, pointsize=10, family='Quicksand')
} else {
  png(filename='img/max-latencias.png', width=1200, height=600, pointsize=12, family='Quicksand')
}

par(mar=c(2.25, 3, 3, 1))

m = min(latencias)
minor = m%/%10*10     # limite inferior do eixo Y
M = max(latencias);
major = ifelse((M%%10 > 0), 10*(M%/%10+1), M)+1   # limite superior do eixo Y

bar <- barplot(
  latencias,
  space=.25, border="gray80", col=c("gold", "orange"),
  xaxt='n',   # inabilita renderização default
  yaxt='n',
  ylim=c(minor, major),
  xpd=F       # não renderiza fora da área de plotagem
)

title(
  main="Máximas Latências Históricas dos Números",
  cex.main=2.5, font.main=1, col.main="black"
)

# renderiza o eixo X com visual mais amigável
axis(
  1, at=bar, labels=c(sprintf("%02d", 1:60)),
  mgp=c(0, .625, 0), col="transparent",
  cex.axis=1.1875, font.axis=2, col.axis="orangered4"
)

yLabs = seq(minor, major, 10)
axis(
  2, at=yLabs, las=1, col="gray10",
  cex.axis=1, font.axis=2, col.axis="orangered3"
)
# renderiza "tick marks" secundários no eixo Y
rug(head(yLabs,-1)+5, side=2, col="gray10", ticksize=-0.01, lwd=1)

# linhas de referência ordinárias
abline(h=seq(minor+10, M, 5), col="gray80", lty="dotted")

# linhas de referência dos "cinco números de Tukey"
sumario <- fivenum(latencias)
abline(h=sumario, col=c("coral","tomato","red","tomato","coral"), lty="dotted")
text(
  par("usr")[2], sumario[3], "mediana", adj=c(1, -0.5),
  cex=.75, font=2, col="red"
)

# adiciona "box & whiskers" antes da primeira coluna
boxplot(
  latencias, outline=T, frame.plot=F, add=T, at=-1.25,
  yaxt='n', border="tomato", col=c("mistyrose"), width=2
)

rect(
  0, sumario[2], bar[60]+bar[1], sumario[4], col="#ff00ff20",
  border="transparent", density=18
)

mtext(
  paste("Mega-Sena", concurso), side=4, adj=1, line=-.625,
  cex=2, font=1, col='firebrick'
)

dev.off() # finaliza a renderização e fecha arquivo
