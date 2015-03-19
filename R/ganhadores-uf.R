#!/usr/bin/Rscript
#
library(RSQLite, quietly=TRUE)
con <- dbConnect(SQLite(), dbname='megasena.sqlite')
rs <- dbSendQuery(con, 'SELECT uf FROM ganhadores')
datum <- fetch(rs, n=-1)
dbClearResult(rs)
dbDisconnect(con)

tabela <- table( datum[1]$uf )

png(filename='img/ganhadores-uf.png', width=992, height=558, pointsize=12)

barplot(
  tabela,
  col=c('gold', 'forestgreen'),
  main=list(
      format(Sys.time(), 'MEGASENA - %d/%m/%Y'),
      cex=5/4,        # characters expansion
      font=2,         # bold
      col='darkgreen' # foreground color
    ),
  ylab=list(
      '#Ganhadores',
      font=3
    ),
  xlab=list(
      'Unidade Federativa',
      font=1
    ),
  yaxt='n'  # desabilita renderização padrão do eixo y
)

axis(
  2,                  # eixo y
  las=2,              # rótulos dispostos horizontalmente
  col.axis="#333333",
  at=c(0, 10, 20, 50, 100, 150)
)

# valores de referência e legendas

line_colors <- c('red', 'blue')
line_types <- c(3, 3)           # 1=continua, 2=tracejada, 3=pontilhada
legend_texts <- c('média', 'mediana')

abline(
  h=mean(tabela),
  col=line_colors[1],
  lty=line_types[1]
)

abline(
  h=median(tabela),
  col=line_colors[2],
  lty=line_types[2]
)

gd <- par()$usr   # coordenadas dos extremos do dispositivo de renderização
legend(
  1*(gd[1]+gd[2])/5, gd[4],   # coordenada (x,y) da legenda
  bty='n',                    # desabilita renderização de bordas
  col=line_colors,
  lty=line_types,
  legend=legend_texts
)

dev.off()