#!/usr/bin/Rscript --no-init-file

# Máximas latências dos números na série histórica dos concursos da Mega-Sena.

library(RSQLite)
con <- dbConnect(SQLite(), 'megasena.sqlite')

latencias <- vector(mode='integer', length=60)

rs <- dbSendQuery(con, "
WITH RECURSIVE this (z, s) AS (
    SELECT serie, serie || '0' FROM (
      SELECT GROUP_CONCAT(NOT(dezenas >> ($target_value - 1) & 1), '') AS serie
      FROM dezenas_juntadas
    )
  ), zero (j) AS (
    SELECT INSTR(z, '00') FROM this
    UNION ALL
    SELECT j + INSTR(SUBSTR(z, j+1), '00') AS k FROM this, zero WHERE k > j
  ), core (i) AS (
    SELECT INSTR(s, '1') FROM this
    UNION ALL
    SELECT i + INSTR(SUBSTR(s, i), '01') AS k FROM this, core WHERE k > i
  ) SELECT INSTR(SUBSTR(s, i), '0')-1 AS latencia FROM this, core
    UNION ALL
    SELECT 0 AS latencia FROM zero"
)
for (numero in 1:60) {
  dbBind(rs, list('target_value'=numero))
  datum <- dbFetch(rs)
  latencias[numero] = max(datum$latencia)
}
dbClearResult(rs)
# print(latencias)
lastConcurso = dbGetQuery(con, 'SELECT MAX(concurso) FROM concursos')[1,1]
dbDisconnect(con)
rm(con, rs, datum)

if (interactive()) {
  X11(display=":0.0", family='Quicksand', width=12, height=6, pointsize=10)
} else {
  png(filename='img/max-latencias.png', width=1080, height=640, pointsize=12, family='Quicksand')
}

BOLD = 2
DOTTED = 'dotted'
Y_AXIS = 2

AXIS_COL = 'gray10'
BAR_BORDER_COL = 'transparent'
BAR_COLORS = c('orchid', 'palegreen')
BOX_COL = 'pink'
FOOTER_COL = 'gray'
HOT = 'orangered'
PALE = 'gray76'
MAIN_COL= 'darkgreen'

m = min(latencias)
minor = m%/%10*10     # limite inferior do eixo Y
M = max(latencias);
major = ifelse((M%%10 > 0), 10*(M%/%10+1), M)+1   # limite superior do eixo Y

barplot(
  latencias,
  main=list(
    sprintf('Máximas Latências Históricas #%d', lastConcurso),
    cex=1.375, font=BOLD, col=MAIN_COL
  ),
  names.arg=c(sprintf("%02d", 1:60)),
  cex.names=1.125, font.axis=BOLD, col.axis=AXIS_COL,
  space=.25, col=BAR_COLORS, border=BAR_BORDER_COL,
  ylim=c(minor, major),
  xpd=F,    # evita renderização das colunas abaixo do limite inferior
  yaxt='n'  # evita renderização padrão do eixo Y
)

# renderiza o eixo Y com visual mais amigável
yLabs = seq(minor, major, 10)
axis(
  Y_AXIS, las=2, cex.axis=1, font.axis=BOLD, col.axis=AXIS_COL, at=yLabs
)

# renderiza "tick marks" extras no eixo Y
rug(
  head(yLabs,-1)+5, side=Y_AXIS, col=AXIS_COL, ticksize=-0.0075, lwd=1,
  lend='round', ljoin='mitre'
)

# linhas de referência ordinárias
abline( h=seq(minor+10, M, 5), col=PALE, lty=DOTTED )

# linhas de referência da menor, da maior e da mediana das latências
lista <- list(
  valor=c(m, M, median(latencias)), nome=c('mínimo', 'máximo', 'mediana')
)
abline(h=lista$valor, col=HOT, lty=DOTTED)
x2 <- par()$usr[2]; ADJ=c(1, -0.5)  # alinha texto à direita e acima
for (j in 1:3) text(
  x2, lista$valor[j], lista$nome[j], adj=ADJ, cex=.7, font=BOLD, col=HOT
)

# renderiza "box & whiskers" antes da primeira coluna
boxplot(
  latencias, outline=T, frame.plot=F, add=T, at=-1.25,
  border=HOT, col=c(BOX_COL), yaxt='n'
)

# renderiza "footer" na extremidade direita inferior
mtext(
  "Gerado via GNU R-cran.", side=1, adj=1.03, line=4,
  cex=1, font=4, col=FOOTER_COL
)

dev.off() # finaliza a renderização e fecha arquivo