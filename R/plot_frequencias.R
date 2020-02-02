#!/usr/bin/Rscript --no-init-file

library(RSQLite)
con <- dbConnect(SQLite(), 'megasena.sqlite')
concurso <- dbGetQuery(con, 'SELECT MAX(concurso) FROM concursos')[1,1]
datum <- dbGetQuery(con, 'SELECT dezena FROM dezenas_sorteadas')
dbDisconnect(con)

frequencias <- table(datum$dezena)

# x11(display=":0.0", 16, 9, 11)
# dispositivo de renderização: arquivo PNG
png(filename='img/frequencias.png', width=1200, height=600, pointsize=12, family="Quicksand")

par(mar=c(2.25, 3.5, 3, 1))

minor=10*(min(frequencias)%/%10-1)  # limite inferior do eixo Y
major=10*(max(frequencias)%/%10+1)  # limite superior do eixo Y

bar <- barplot(
  frequencias,
  main=list('Frequências dos Números', cex=2.5, font=1, col="black"),
  border='gray80', space=.25, col=c('orange', 'gold'),
  ylim=c(minor, major),
  xpd=FALSE,  # não renderiza fora da área de plotagem
  xaxt='n',
  yaxt='n'    # inabilita renderização default do eixo Y
)

axis(
  side=1, at=bar, labels=c(sprintf('%02d', 1:60)),
  mgp=c(0, .75, 0), col="transparent",
  cex.axis=1.275, font.axis=2, col.axis="orangered4"
)

# renderiza eixo Y com visual amigável
y <- seq(from=minor, to=major, by=10)
axis(
  side=2, at=y, las=2, col="gray10",
  cex.axis=1.25, font.axis=2, col.axis="orangered3"
)
z <- y[y+5 < major]+5
rug(z, side=2, ticksize=-0.0075, col="grey10", lwd=1)

esperanca=concurso/10 # frequência esperada de cada número = 6 * N / 60

# renderiza linhas de referência ordinárias evitando sobreposição
y <- union(y, z)
abline(h=y[y>minor & abs(10*y-concurso)>3], col="gray", lty='dotted')
# renderiza texto e linha de referência da esperança
abline(h=esperanca, col="dodgerblue", lty='dotted')
x2=par("usr")[2]
text(x2, esperanca, 'esperança', adj=c(1, -0.5), cex=.8, font=2, col="dodgerblue")

# renderiza "box & whiskers" adicionado antes da primeira coluna
bp <- boxplot(
  as.vector(frequencias), outline=T, frame.plot=F, axes=F, add=T, at=-1.25,
  border="red", col=c('pink'), yaxt='n', width=2
)

rect(
  0, bp$stats[2], bar[60]+bar[1], bp$stats[4], col="#ff00ff20",
  border="transparent", density=18
)

#abline(h=bp$stats, col="hotpink", lty="dotted")

mtext(
  paste("Mega-Sena", concurso), side=4, adj=0, line=-.75,
  cex=2.75, font=1, col='red'
)
dev.off() # finaliza a renderização e fecha o arquivo
