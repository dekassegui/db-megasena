#!/usr/bin/Rscript --no-init-file
#
# Diagrama de frequências e latências dos números sorteados na Mega-Sena até o
# concurso mais recente - cujos dados estejam armazenados localmente - exibindo
# sumário de estatísticas de cada número, dos sorteios e do concurso.
#
library(RSQLite)

source("R/param.R")   # checa disponibilidade da tabela "param" + atualização

con <- dbConnect(SQLite(), "megasena.sqlite")

# requisita o número do concurso mais recente, número de concursos acumulados
# e percentual de acumulação ao longo do tempo
mega <- dbGetQuery(con, "WITH cte(m, n) AS (
  SELECT MAX(concurso), SUM(acumulado) FROM concursos
) SELECT m AS concurso, m-MAX(concurso) AS acumulados, 100.0*n/m AS acumulacao
  FROM cte, concursos WHERE NOT acumulado")

# requisita frequências e latências dos números no concurso mais recente
numeros <- dbGetQuery(con, "SELECT frequencia, latencia FROM info_dezenas ORDER BY dezena")

latencias <- vector("list", 60)
# loop das requisições das séries das latências de cada número
for (n in 1:60) {
  dbExecute(con, sprintf('update param set status=1 where comentario glob "* %d"', n))
  latencias[[n]] <- dbReadTable(con, "esperas")$len-1
}

# requisita os números sorteados no concurso anterior ao mais recente
anterior <- dbGetQuery(con, paste("SELECT dezena FROM dezenas_sorteadas WHERE concurso+1 ==", mega$concurso))

dbDisconnect(con)
rm(con)

# testa HØ: números ~ U(1, 60)
teste <- chisq.test(numeros$frequencia, correct=F)
x <- ifelse(teste$p.value >= .05, 1, 2)

# testa HØ: latências de qualquer número têm a mesma distribuição
teste <- kruskal.test(latencias)
y <- ifelse(teste$p.value >= .05, 1, 2)

numeros$maxLatencia <- sapply(latencias, max)
rm(latencias, teste)

numeros$corFundo <- "white"

five <- fivenum(numeros$frequencia)

cores <- colorRamp(c("#FFCC66", "orange1"), bias=1, space="rgb", interpolate="spline")
selection <- which(numeros$frequencia>five[4])
numeros[selection,]$corFundo <- rgb(cores((numeros[selection,]$frequencia-five[4])/(five[5]-five[4])), max=255)

cores <- colorRamp(c("yellow1", "gold1"), bias=.75, space="rgb", interpolate="spline")
selection <- which(numeros$frequencia>five[3] & numeros$frequencia<=five[4])
numeros[selection,]$corFundo <- rgb(cores((numeros[selection,]$frequencia-five[3])/(five[4]-five[3])), max=255)

cores <- colorRamp(c("#D0FFD0", "seagreen2"), bias=1, space="rgb", interpolate="spline")
selection <- which(numeros$frequencia>five[2] & numeros$frequencia<=five[3])
numeros[selection,]$corFundo <- rgb(cores((numeros[selection,]$frequencia-five[2])/(five[3]-five[2])), max=255)

cores <- colorRamp(c("#ACECFF", "skyblue1"), bias=1, space="rgb", interpolate="spline")
selection <- which(numeros$frequencia<=five[2])
numeros[selection,]$corFundo <- rgb(cores((numeros[selection,]$frequencia-five[1])/(five[2]-five[1])), max=255)

cores <- colorRampPalette(c("gray25", "gray34", "gray75"))(60)
numeros$corFrente <- cores[rank(numeros$latencia, ties.method="last")]
# garante máxima tonalidade de cinza para números com mínima latência (=zero)
numeros[numeros$latencia == 0, "corFrente"] <- "black"

rm(cores, five, selection)

png(filename="img/dia.png", width=1000, height=640, pointsize=10, family="Quicksand")

par(mar=c(.75, .75, 4.25, .75), font=2)

plot(NULL, type="n", axes=F, xaxs="i", yaxs="i", xlim=c(0, 10), ylim=c(0, 6))

title(paste("Mega-Sena", mega$concurso), adj=0, line=1.1875, cex.main=3.75)

mtext(
  c("acumulados:", mega$acumulados, "acumulação:", sprintf("%5.2f%%", mega$acumulacao)),
  side=3, at=c(4.15, 4.19), line=c(2.4, 2.4, 1, 1), adj=c(1, 0),
  cex=1.26, col=c("gray33", "sienna"), family="Quicksand Bold"
)

dat <- matrix(c("\uF00C", "\uF00D", "dodgerblue", "red"), ncol=2, byrow=T)
mtext(
  c("números i.i.d. U\u276A1, 60\u276B", dat[1,x], "latências i.i.d. Geom\u276A0.1\u276B", dat[1,y]),
  side=3, at=c(6.99, 7.03), line=c(2.4, 2.4, 1, 1), adj=c(1, 0), cex=c(1.26, 1.75),
  col=c("gray33", dat[2,x], "gray33", dat[2,y]), family="Quicksand Bold"
)
rm(dat)

# LEGENDA DAS QUADRÍCULAS

rect(7.50, 6.06, 9.88, 6.46, xpd=T, col="#FFFFC0", border=NA) # background
mtext(
  c("frequência", "Atípico\u2215Reincidente", "latência", "latência recorde"),
  side=3, at=c(7.56, 9.82), line=c(2.2, 2.2, .8, .8), adj=c(0, 1), cex=1.26,
  col=c("darkred", "black", "violetred", "firebrick"), family="Quicksand Bold"
)

# ESCALA DE CORES DAS QUADRÍCULAS

mtext(
  rep("\u25A0", 4), side=3, at=10, line=seq(from=.42, by=.808, length.out=4),
  adj=1, cex=1.1, col=c("#33C9FF", "#66CC00", "gold2", "orange1")
)

for (n in 1:60) {
  x <- (n-1) %% 10
  y <- (n-1) %/% 10
  attach(numeros[n,])
  # renderiza a quadricula com cor em função da frequência
  rect(x, 5-y, x+1, 6-y, col=corFundo, border="white")
  # renderiza o número com cor em função da latência em relevo
  text(
    c(x+.51, x+.5), c(5.49-y, 5.5-y), sprintf("%02d", n),
    adj=c(.5, .5), cex=4, col=c("white", corFrente)
  )
  # frequência histórica
  text(x+.1, 5.9-y, frequencia, adj=c(0, 1), cex=1.5, col="darkred")
  # checa se frequência abaixo do esperado e latência acima do esperado
  if (10*frequencia < mega$concurso & latencia >= 10) {
    text(x+.9, 5.9-y, "A", adj=c(1, 1), cex=1.25, col="black")
  } else if (latencia == 0) {
    # renderiza borda extra para evidenciar número recém sorteado
    rect(
      x+.025, 5.025-y, x+.975, 5.975-y, col="transparent", border="black", lwd=2
    )
    # checa se número é reincidente -- sorteado no concurso anterior
    if (n %in% anterior$dezena) {
      text(x+.9, 5.9-y, "R", adj=c(1, 1), cex=1.25, col="black")
    }
  }
  # latência imediata
  text(x+.1, 5.1-y, latencia, adj=c(0, 0), cex=1.5, col="violetred")
  # máxima latência histórica
  text(x+.9, 5.1-y, maxLatencia, adj=c(1, 0), cex=1.5, col="firebrick")
  detach(numeros[n,])
}

dev.off()
