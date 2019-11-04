#!/usr/bin/Rscript --no-init-file

library(RSQLite)
con <- dbConnect(SQLite(), 'megasena.sqlite')
concurso <- dbGetQuery(con, 'SELECT concurso FROM concursos ORDER BY concurso DESC LIMIT 1')$concurso
datum <- dbGetQuery(con, 'SELECT dezena FROM dezenas_sorteadas')
dbDisconnect(con)

frequencias <- table(datum$dezena)

# x11(display=":0.0", 16, 9, 11)
# dispositivo de renderização: arquivo PNG
png(filename='img/frequencias.png', width=1200, height=600, pointsize=12, family="Quicksand")

BOLD=2
DOTTED='dotted'
Y_AXIS=2

AXIS_COL='gray0'
HOT='red'

minor=10*(min(frequencias)%/%10-1)  # limite inferior do eixo Y
major=1+max(frequencias)            # limite superior do eixo Y

barplot(
  frequencias,
  main=list(
    sprintf('Frequências dos Números #%d', concurso),
    cex=1.5, font=BOLD, col='black'
  ),
  names.arg=c(sprintf('%02d', 1:60)),
  cex.names=1.25, font.axis=BOLD, col.axis=AXIS_COL,
  border='gray77', space=.25, col=c('orange', 'gold'),
  ylim=c(minor, major),
  xpd=FALSE,  # evita renderização de coluna fora dos limites
  yaxt='n'    # evita renderização padrão do eixo Y
)

# renderiza eixo Y com visual amigável
y <- seq(from=minor, to=major, by=10)
axis(Y_AXIS, las=2, cex.axis=1.25, font.axis=BOLD, col.axis=AXIS_COL, at=y)

esperanca=concurso/10 # frequência esperada de cada número = 6 * N / 60

# renderiza linhas de referência ordinárias evitando sobreposição
abline(h=y[y>minor & abs(y-esperanca)>3], col="gray", lty=DOTTED)
# renderiza texto e linha de referência da esperança
abline(h=esperanca, col=HOT, lty=DOTTED)
x2=par()$usr[2]
text(x2, esperanca, 'esperança', adj=c(1, -0.5), cex=.7, font=BOLD, col=HOT)

# renderiza "box & whiskers" adicionado antes da primeira coluna
boxplot(
  as.vector(frequencias), outline=T, frame.plot=F, add=T, at=-1.25,
  border=HOT, col=c('mistyrose'), yaxt='n'
)

# renderiza "footer" na extremidade direita ao fundo
mtext(
  'Gerado via GNU R-cran.', side=1, adj=1.025, line=3.9,
  cex=1.15, font=4, col='gray70'
)

dev.off() # finaliza a renderização e fecha o arquivo
