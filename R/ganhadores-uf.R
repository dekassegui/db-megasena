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
  cores=rep_len(c('gold', 'orange'), 4)
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

par(mar=c(4.5, 3.5, 3, 1))

# prepara parâmetros conforme ordem preferencial das regiões
CORES <- c(norte$cores, nordeste$cores, sul$cores, sudeste$cores, centroeste$cores, online$cores)
#DENSIDADES <- rep.int(32, 28); DENSIDADES[28]=-1
SPACES <- rep.int(.1, 28); SPACES[1]=0; SPACES[ c(8, 17, 20, 24, 28) ]=.3

BOLD=2
BOLD_ITALIC=4
DOTTED='dotted'
Y_AXIS=2

COL_AXIS='gray20'

bar <- barplot(
  tabela[UFS],
  main='Apostas Vencedoras na Mega-Sena',
  cex.main=2.5, font.main=1, col.main="black",
  names.arg=UFS, cex.name=1.025, font.axis=BOLD, col.axis=COL_AXIS,
  border="gray80", col=CORES, space=SPACES, #density=DENSIDADES,
  # desabilita renderização padrão do eixo y -- personalizada a seguir
  yaxt='n',
  ylim=c(0, max(tabela)+5)
)

title (
  sub='Quantidade × Unidade Federativa', line=2.875,
  cex.sub=1.375, font.sub=BOLD, col.sub="gray20"
)

xx <- bar[UFS == online$ufs]; y <- tabela[online$ufs]
text(xx, y+40, "APOSTAS ONLINE", srt=90, adj=c(0, .5), cex=1.5, font=2, col="gray")
arrows(xx, y+38, xx, y+2, col="gray", lty="solid", angle=25, length=1/8)

Y <- c(0, 10, 20, 50, 75, 100, 150, 200, max(tabela)) # valores preferenciais

axis(Y_AXIS, las=2, cex.axis=1, font.axis=BOLD, col.axis=COL_AXIS, at=Y)
rug(c(30, 40), side=2, ticksize=-.01, col=COL_AXIS, lwd=1)

media=mean(tabela)
abline(h=media, col="dodgerblue", lty=DOTTED)
text(par("usr")[2], media, "média", adj=c(1, -0.5), cex=1, font=BOLD_ITALIC, col="dodgerblue")

# renderiza linhas de referência ordinárias
abline(h=Y[Y > media], col="gray80", lty=DOTTED)

# renderiza "box & whiskers" adicionado ao diagrama antes da primeira coluna
bp <- boxplot(
  as.vector(tabela), outline=T, frame.plot=F, add=T, at=-0.65,
  border="red", col=c('mistyrose'), yaxt='n'
)

abline(h=bp$stats, col="tomato", lty=DOTTED)

# renderiza "footer" na extremidade inferior direita
mtext(
  format(Sys.time(), 'Gerado via GNU R-cran em %d-%m-%Y.'),
  side=1, adj=1.01, line=3.4, cex=1, font=BOLD_ITALIC, col='lightslategray'
)

dev.off() # finaliza a renderização e fecha arquivo PNG
