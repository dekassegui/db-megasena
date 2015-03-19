#!/usr/bin/Rscript

# library(graphics)
# display value found in environment variable $DISPLAY
# x11(display=":0.0", 16, 9, 11)

library(RSQLite, quietly=TRUE)
con <- dbConnect(SQLite(), dbname='megasena.sqlite')

rs <- dbSendQuery(con, 'SELECT dezena FROM dezenas_sorteadas')
datum <- fetch(rs, n = -1)

dbClearResult(rs)
dbDisconnect(con)

titulo = paste('Mega-Sena #', (length(datum$dezena) / 6), sep='')

# monta a tabela das classes com suas respectivas frequências
tabela <- table(datum$dezena)

# prepara os rótulos das classes formatando os números das dezenas
dimnames(tabela) <- list(sprintf('%02d', 1:length(tabela)))

# arquivo para armazenamento da imagem com declaração das dimensões do
# display gráfico e tamanho da fonte de caracteres
png(filename='img/frequencias.png', width=1000, height=558, pointsize=13)

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
  col='red',      # cor da linha
  lty=3           # 1=continua, 2=tracejada, 3=pontilhada
)

gd <- par()$usr   # coordenadas dos extremos do dispositivo de renderização

legend(
  3*(gd[1]+gd[2])/4, gd[4],   # coordenada (x,y) da legenda
  bty='n',                    # omite renderização de bordas
  col='red', lty=3,           # atributos da única linha amostrada
  legend=c('esperança')       # texto correspondente da linha
)

# renderiza texto na margim direita alinhado ao fundo em negrito com 70% do
# tamanho default de fonte
mtext('Made with the R Statistical Computing Environment',
      side=4, adj=0, font=2, cex=.7)

dev.off()   # finaliza a renderização e fecha o arquivo
