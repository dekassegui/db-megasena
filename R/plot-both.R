#!/usr/bin/Rscript --no-init-file
#
# Montagem dos gráficos das frequências e latências combinados em única imagem
# que faz parte do relatório sobre o concurso mais recente da Mega-Sena.
#
library(RSQLite, quietly=TRUE)
con <- dbConnect(SQLite(), dbname='megasena.sqlite')
datum <- dbGetQuery(con, 'SELECT dezena FROM dezenas_sorteadas')

nrec <- length(datum$dezena) / 6;
titulo <- sprintf('Frequências dos números #%d', nrec)

# monta a tabela das classes com suas respectivas frequências
tabela <- table(datum$dezena)

# prepara os rótulos das classes formatando os números das dezenas
rotulos <- c(sprintf('%02d', 1:60))
dimnames(tabela) <- list(rotulos)

# arquivo para armazenamento da imagem com declaração das dimensões do
# device gráfico e tamanho da fonte de caracteres
fname=sprintf('img/both-%d.png', nrec)
png(filename=fname, width=1100, height=600, pointsize=9, family="Quicksand")

# preserva configuração do dispositivo gráfico antes de personalizar
# layout posicionando os dois gráficos alinhados horizontalmente
op <- par(mfrow=c(2, 1))

BAR_COLORS <- c('gold', 'orange')
SPC=.25

major=max(tabela)
minor=(min(tabela) %/% 10 - 1) * 10

barplot(
  tabela,
  main=list(titulo, cex=1.375),
  #ylab='frequência',
  cex.names=1.25, font.axis=2,
  border='#333333',
  col=BAR_COLORS,
  space=SPC,
  ylim=c(minor, major+1),
  xpd=FALSE,
  yaxt='n'
)

axis(
  2,                  # eixo y
  las=2,              # labels dispostos perpendicularmente
  col.axis="#333333",
  cex.axis=1.25,
  font.axis=2,
  at=seq(from=minor, to=major, by=10)
)

media <- mean(tabela)
r <- seq(from=minor+10, to=major, by=10)
abline( h=r[ which(r < media-3 | r > media+3) ], col="gray", lty=3 )

# renderiza linha horizontal da esperança das frequências :: média
abline(
  h=media,    # esperança = 6 * N / 60
  col='red',  # cor da linha
  lty=3       # 1=continua, 2=tracejada, 3=pontilhada
)

legend("topright", legend='esperança', bty='n', col='red', lty=3, cex=1.125)

datum <- dbGetQuery(con, 'SELECT latencia FROM info_dezenas')
dbDisconnect(con)

titulo <- sprintf('Latências dos números #%d', nrec)

x <- as.vector(datum$latencia)

names(x) <- rotulos

barplot(
  x,
  main=list(titulo, cex=1.375),
  #ylab='latência',
  cex.names=1.25, font.axis=2,
  border='#333333',
  col=BAR_COLORS,
  space=SPC,
  ylim=c(0, max(x)+1),
  yaxt='n'
)

axis(
  2,
  las=2,
  col.axis="#333333",
  cex.axis=1.25,
  font.axis=2,
  at=seq(from=0, to=max(x), by=10)
)

abline( h=c(5, seq(20, max(x), 10)), col="gray", lty=3 )

abline(
  h=10,             # esperança das latências :: 60 / 6
  col='red', lty=3
)

legend("topright", legend="esperança", bty='n', col='red', lty=3, cex=1.125)

# footer no canto inferior direito
mtext(sprintf("Concurso %d da Mega-Sena", nrec),
  side=1, adj=1.015, line=3.9, cex=1.15, font=4, col='lightslategray')

par <- op  # restaura device gráfico

dev.off()   # finaliza a renderização e fecha o arquivo
