#!/usr/bin/Rscript --no-init-file

# Histograma das quantidades de apostas vencedoras nos concursos da Mega-Sena
# por unidade federativa.

library(RSQLite, quietly=TRUE)
con <- dbConnect(SQLite(), dbname='megasena.sqlite')
datum <- dbGetQuery(con, 'SELECT uf FROM ganhadores')
dbDisconnect(con)

tabela <- table(datum$uf)   # contabiliza frequências por ufs ignorando NA

if (is.na(tabela['AP'])) {  # enquanto não houver aposta vencedora do Amapá
  aux <- as.vector(tabela)
  names(aux) <- names(tabela)
  aux['AP']=0
  tabela <- aux
  rm(aux)
}

norte <- list(
  ufs=c("AC", "AM", "AP", "PA", "RO", "RR", "TO"),
  cores=rep_len(c('green4','green'), 7)
)
nordeste <- list(
  ufs=c("AL", "BA", "CE", "MA", "PB", "PE", "PI", "RN", "SE"),
  cores=rep_len(c('red','tomato'), 9)
)
sul <- list(
  ufs=c("PR", "RS", "SC"),
  cores=rep_len(c('dodgerblue','royalblue'), 3)
)
sudeste <- list(
  ufs=c("ES", "MG", "RJ", "SP"),
  cores=rep_len(c('orange', 'gold'), 4)
)
centroeste <- list(
  ufs=c("DF", "GO", "MS", "MT"),
  cores=rep_len(c('violetred','violet'), 4)
)
online <- list( ufs="XX", cores="lightgray" )

# disposição das ufs na ordem preferencial das regiões
UFS <- c(norte$ufs, nordeste$ufs, sul$ufs, sudeste$ufs, centroeste$ufs, online$ufs)

png(filename='img/ganhadores-uf.png', width=1080, height=640, pointsize=13, family='Quicksand')

# prepara parâmetros conforme ordem preferencial das regiões
CORES <- c(norte$cores, nordeste$cores, sul$cores, sudeste$cores, centroeste$cores, online$cores)
DENSIDADES <- rep.int(30, 28); DENSIDADES[28]=-1
SPACES <- rep.int(.1, 28); SPACES[1]=0; SPACES[ c(8, 17, 20, 24, 28) ]=.3

barplot(
  tabela[UFS],
  names.arg=UFS,
  main=list('Apostas Vencedoras na Mega-Sena', cex=11/8, font=2, col='#222222'),
  # simula subtitle personalizando label do eixo x
  xlab=list('Quantidade × Unidade Federativa', cex=5/4, font=2, col='#222222'),
  #offset=0,
  cex.name=1.025, font.axis=2, col.axis='#202020',
  border="#555555",
  col=CORES,
  density=DENSIDADES,
  space=SPACES,
  # desabilita renderização padrão do eixo y -- personalizada a seguir
  yaxt='n'
)

Y <- c(0, 10, 20, 50, 100, 150, 200, max(tabela)) # valores preferenciais

axis(
  2,                  # eixo y
  las=2,              # labels dispostos perpendicularmente
  col.axis="#202020",
  cex.axis=1,
  font.axis=2,
  at=Y
)

# renderiza linhas horizontais de referência

media=mean(tabela)

yStat <- list(
  list( texto='média', valor=media, color='#003399' ),
  list( texto='mediana', valor=median(tabela), color='#990033' )
)

abline( h=Y[ Y > media ], col="#acacac", lty=3 )

gd <- par()$usr   # extremidades do dispositivo de renderização

for (i in 1:2) {
  abline( h=yStat[[i]]$valor, col=yStat[[i]]$color, lty=3 )
  text(
    ( 3 * gd[1] / 4 ),
    ( 1.1 + yStat[[i]]$valor ),
    yStat[[i]]$texto,
    col=yStat[[i]]$color,
    font=4, cex=1, adj=c(0, 0)
  )
}

# footer no canto inferior direito
mtext(format(Sys.time(), 'Gerado via GNU R-cran em %d-%m-%Y.'),
  side=1, adj=1.035, line=4, cex=1, font=4, col='lightslategray')

dev.off()
