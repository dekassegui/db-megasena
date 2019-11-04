#!/usr/bin/Rscript --no-init-file

library(RSQLite)
con <- dbConnect(SQLite(), dbname='megasena.sqlite')
concurso <- dbGetQuery(con, 'SELECT concurso FROM concursos ORDER BY concurso DESC LIMIT 1')$concurso
latencias <- dbGetQuery(con, 'SELECT latencia FROM info_dezenas')$latencia
dbDisconnect(con)

# dispositivo de renderização: arquivo PNG
png(filename='img/latencias.png', width=1200, height=600, pointsize=12, family="Quicksand")

BOLD=2
DOTTED='dotted'
Y_AXIS=2

AXIS_COL='gray5'
HOT='red'

major=max(latencias)+1  # limite superior do eixo Y

barplot(
  latencias,
  main=list(
    sprintf('Latências dos Números #%d', concurso),
    cex=1.5, font=BOLD, col='black'
  ),
  names.arg=c(sprintf('%02d', 1:60)),
  cex.names=1.25, font.axis=BOLD, col.axis=AXIS_COL,
  border='gray70', space=.25, col=c('orange', 'gold'),
  ylim=c(0, major),
  yaxt='n'  # evita renderização padrão do eixo Y
)

# renderiza o eixo Y com visual amigável
y=seq(0, major, 10)
axis(Y_AXIS, las=2, col.axis=AXIS_COL, cex.axis=1.25, font.axis=BOLD, at=y)
# adiciona "tick marks" extras no eixo Y
rug(
  head(y,-1)+5, side=Y_AXIS, col=AXIS_COL, ticksize=-.0075, lwd=.85,
  lend='round', ljoin='mitre'
)

# renderiza linhas de referência ordinárias
abline(h=c(0, 5, 15, y[y >= 20]), col='gray', lty=DOTTED)
# renderiza texto e linha da esperança das latências = 60 / 6 = 10
abline(h=10, col=HOT, lty=DOTTED)
text(par()$usr[2], 10, "esperança", adj=c(1, -0.5), cex=.7, font=BOLD, col=HOT)

# renderiza "box & whiskers" adicionado antes da primeira coluna
boxplot(
  latencias, outline=T, frame.plot=F, add=T, at=-1.25,
  border=HOT, col=c('mistyrose'), yaxt='n'
)

# renderiza "footer" na extremidade inferior à direita
mtext(
  "Gerado via GNU R-cran.", side=1, adj=1.025, line=4,
  cex=1.1, font=4, col='gray70'
)

dev.off() # finaliza a renderização e fecha o arquivo PNG
