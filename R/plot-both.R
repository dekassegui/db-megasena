#!/usr/bin/Rscript --no-init-file
#
# Montagem dos gráficos das frequências e latências combinados em única imagem
# que faz parte do relatório sobre o concurso mais recente da Mega-Sena.
#
library(RSQLite, quietly=TRUE)
con <- dbConnect(SQLite(), dbname='megasena.sqlite')

rs <- dbSendQuery(con, 'SELECT dezena FROM dezenas_sorteadas')
datum <- dbFetch(rs)

dbClearResult(rs)

nrec <- length(datum$dezena) / 6;
titulo <- sprintf('Frequências das dezenas #%d', nrec)

# monta a tabela das classes com suas respectivas frequências
tabela <- table(datum$dezena)

# prepara os rótulos das classes formatando os números das dezenas
rotulos <- c(sprintf('%02d', 1:60))
dimnames(tabela) <- list(rotulos)

# arquivo para armazenamento da imagem com declaração das dimensões do
# device gráfico e tamanho da fonte de caracteres
fname=sprintf('img/both-%d.png', nrec)
png(filename=fname, width=1100, height=600, pointsize=9)

# preserva configuração do dispositivo gráfico antes de personalizar
# layout posicionando os dois gráficos alinhados horizontalmente
op <- par(mfrow=c(2, 1))

bar_colors <- c('gold', 'orange')

barplot(
  tabela,
  main=titulo,
  ylab='frequência',
  col=bar_colors,
  space=0.25,
  ylim=c(120, (1 + max(tabela) %/% 25) * 25),
  xpd=FALSE
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

rs <- dbSendQuery(con, 'SELECT latencia FROM info_dezenas')
datum <- dbFetch(rs)

dbClearResult(rs)
dbDisconnect(con)

titulo <- sprintf('Latências das dezenas #%d', nrec)

x <- as.vector(datum$latencia)

names(x) <- rotulos

barplot(
  x,
  main=titulo,
  ylab='latência',
  col=bar_colors,
  space=0.25
)

abline(
  h=10,             # esperança das latências
  col='red', lty=3
)

gd <- par()$usr

legend(
  3*(gd[1]+gd[2])/4, 4*gd[4]/5,
  bty='n',
  col='red', lty=3,
  legend=c('esperança')
)

par <- op  # restaura device gráfico

dev.off()   # finaliza a renderização e fecha o arquivo
