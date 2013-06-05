#!/usr/bin/Rscript

# library(graphics)
# display value found in environment variable $DISPLAY
# x11(display=":0.0", 16, 9, 11)

library(RSQLite, quietly=TRUE)
con <- sqliteNewConnection(dbDriver('SQLite'), dbname='megasena.sqlite')

rs <- dbSendQuery(con, 'SELECT dezena FROM dezenas_sorteadas')
datum <- fetch(rs, n = -1)

dbClearResult(rs)
sqliteCloseConnection(con)

titulo = paste('Mega-Sena #', (length(datum$dezena) / 6), sep='')

# monta a tabela das classes com suas respectivas frequências
tabela <- table(datum$dezena)

# prepara os rótulos das classes formatando os números das dezenas
dimnames(tabela) <- list(sprintf('%02d', 1:length(tabela)))

# arquivo para armazenamento da imagem com declaração das dimensões do
# display gráfico e tamanho da fonte de caracteres
png(filename='frequencias.png', width=1000, height=558, pointsize=13)

barplot(
  tabela,
  main=titulo,
  ylab='frequência',
  col=c('pink', 'khaki'),
  space=.25,
  ylim=c(0, (1+max(tabela)%/%25)*25)
)

# sobrepõe linha horizontal de referência
abline(
  h=mean(tabela), # esperança das frequências observadas
  col='red',      # vermelho
  lty=3           # 1=continua, 2=tracejada, 3=pontilhada
)

d <- par()$usr

legend(
  3*(d[1]+d[2])/4, d[4],
  bty='n',
  legend=c('esperança'),
  col='red',
  lty=3
)

mtext('Made with the R Statistical Computing',
  side=4,
  adj=0,
  font=2,
  cex=.7
)

dev.off()   # finaliza a renderização e fecha o arquivo
