#!/usr/bin/Rscript --no-init-file

# library(graphics)
# display value found in environment variable $DISPLAY
# x11(display=":0.0", 16, 9, 11)

library(RSQLite, quietly=TRUE)
con <- dbConnect(SQLite(), dbname='megasena.sqlite')
datum <- dbGetQuery(con, 'SELECT dezena FROM dezenas_sorteadas')
dbDisconnect(con)

# monta a tabela das classes com suas respectivas frequências
tabela <- table(datum$dezena)

# prepara os rótulos das classes formatando os números das dezenas
dimnames(tabela) <- list(sprintf('%02d', 1:length(tabela)))

# arquivo para armazenamento da imagem com declaração das dimensões do
# display gráfico e tamanho da fonte de caracteres
png(filename='img/frequencias.png', width=1200, height=600, pointsize=12, family="Quicksand")

minor=10 * (min(tabela) %/% 10 - 1)
major=1 + max(tabela)

barplot(
  tabela,
  main=list(
    paste('Frequências dos Números no Concurso', (length(datum$dezena)/6), 'da Mega-Sena'),
    cex=1.5, font=2, col='black'
  ),
  #ylab='frequência',
  cex.names=1.25, font.axis=2,
  ylim=c(minor, major),
  border='#333333',
  col=c('orange', 'gold'),
  #density=26,
  space=.25,
  xpd=FALSE,
  yaxt='n'
)

r <- seq(from=minor, to=major, by=10)

axis(
  2,                  # eixo y
  las=2,              # labels dispostos perpendicularmente
  col.axis="#333333",
  cex.axis=1.25,
  font.axis=2,
  at=r
)

m=mean(tabela)
r <- tail(r, -1)
abline(h=r[abs(m-r) > 2], col="gray", lty=3)

# sobrepõe linha horizontal de referência
abline(
  h=m,          # esperança das frequências observadas
  col='red',    # cor da linha
  lty=3         # 1=continua, 2=tracejada, 3=pontilhada
)

legend(
  "topright",
  legend='esperança', # texto correspondente da linha
  bty='n',            # omite renderização de bordas
  col='red', lty=3    # atributos da única linha amostrada
)

# renderiza texto na margem direita alinhado ao fundo em negrito com 70% do
# tamanho default de fonte
mtext('Gerado via GNU R-cran.',
  side=1, adj=1.025, line=3.9, cex=1.15, font=4, col='slategray')

dev.off()   # finaliza a renderização e fecha o arquivo
