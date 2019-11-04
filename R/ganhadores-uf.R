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

# dispositivo de renderização: arquivo PNG
png(filename='img/ganhadores-uf.png', width=1080, height=640, pointsize=13, family='Quicksand')

# prepara parâmetros conforme ordem preferencial das regiões
CORES <- c(norte$cores, nordeste$cores, sul$cores, sudeste$cores, centroeste$cores, online$cores)
DENSIDADES <- rep.int(30, 28); DENSIDADES[28]=-1
SPACES <- rep.int(.1, 28); SPACES[1]=0; SPACES[ c(8, 17, 20, 24, 28) ]=.3

BOLD=2
BOLD_ITALIC=4
DOTTED='dotted'
Y_AXIS=2

COL_AXIS='#202020'
TITLE_COL='gray2'

barplot(
  tabela[UFS],
  names.arg=UFS,
  main=list(
    'Apostas Vencedoras na Mega-Sena', cex=11/8, font=BOLD, col=TITLE_COL
  ),
  # simula subtitle personalizando label do eixo x
  xlab=list(
    'Quantidade × Unidade Federativa', cex=5/4, font=BOLD, col=TITLE_COL
  ),
  #offset=0,
  cex.name=1.025, font.axis=BOLD, col.axis=COL_AXIS,
  border="#555555", col=CORES, density=DENSIDADES, space=SPACES,
  # desabilita renderização padrão do eixo y -- personalizada a seguir
  yaxt='n',
  ylim=c(0, max(tabela)+5)
)

Y <- c(0, 10, 20, 50, 100, 150, 200, max(tabela)) # valores preferenciais

axis(Y_AXIS, las=2, cex.axis=1, font.axis=BOLD, col.axis=COL_AXIS, at=Y)

# renderiza linhas de referência ordinárias com valor acima da média
media=mean(tabela)
abline( h=Y[ Y > media ], col="#acacac", lty=DOTTED )

# renderiza texto e linha de referência da média e da mediana
yStat <- list(
  nome=c('média', 'mediana'), valor=c(media, median(tabela)), color=c('#003399', '#990033')
)
x2 <- par()$usr[2]; ADJ=c(1, -0.5)  # alinha texto à direita e "acima"
for (i in 1:2) {
  abline( h=yStat$valor[i], col=yStat$color[i], lty=DOTTED )
  text(
    x2, yStat$valor[i], yStat$nome[i], adj=ADJ,
    cex=1, font=BOLD_ITALIC, col=yStat$color[i]
  )
}

# renderiza "box & whiskers" adicionado ao diagrama antes da primeira coluna
boxplot(
  as.vector(tabela), outline=T, frame.plot=F, add=T, at=-0.65,
  border="red", col=c('mistyrose'), yaxt='n'
)

# renderiza "footer" na extremidade inferior direita
mtext(
  format(Sys.time(), 'Gerado via GNU R-cran em %d-%m-%Y.'),
  side=1, adj=1.035, line=4, cex=1, font=BOLD_ITALIC, col='lightslategray'
)

dev.off() # finaliza a renderização e fecha arquivo PNG
