#!/usr/bin/Rscript --no-init-file
#
# Script gerador da imagem do diagrama das frequências e do diagrama das
# latências dos números sorteados até o concurso mais recente disponível,
# visualmente homogêneos e alinhados verticalmente.
#
library(RSQLite, quietly=TRUE)
con <- dbConnect(SQLite(), dbname='megasena.sqlite')

# requisita o número serial do concurso mais recente disponível no db local
query='SELECT concurso FROM concursos ORDER BY concurso DESC LIMIT 1'
CONCURSO <- as.integer( dbGetQuery(con, query)$concurso )

# requisita frequências e latências dos números -- armazenadas num data.frame
query='SELECT frequencia, latencia FROM info_dezenas ORDER BY dezena'
numeros <- dbGetQuery(con, query)
dbDisconnect(con)

# parâmetros compartilhados pelos diagramas

BAR_LABELS <- c(sprintf("%02d", 1:60))  # labels das colunas (ou barras)
BAR_LABELS_CEX=1.28
BAR_LABELS_FONT=2
BAR_LABELS_COL="darkred"

# cores para preenchimento "zebrado" das colunas, exceto as filtradas
BAR_COLORS <- rep_len(c("gold", "orange"), 60)
attach(numeros)
BAR_COLORS[ 10*frequencia < CONCURSO & latencia > 9 ]="darkorange2"
detach(numeros)

BAR_BORDER='gray80' # cor das bordas das colunas
SPACE=0.25          # espaçamento entre colunas

RULE_COL="gray30"
TICKSIZE=-0.0175  # comprimento de "tick marks" secundários

ADJ=c(1, -0.5)  # ajuste para alinhar texto a direita e "acima"
TXT_CEX=0.9
TXT_FONT=2

HOT="tomato"    # cor para destacar linhas, textos, etc.
PALE="gray80"   # cor "discreta" das linhas de referência ordinárias
REF="purple"

BOX_AT=-1.25            # posição do "box & whiskers"
BOX_COL=c("mistyrose")  # cores de preenchimento dos "box & whiskers"

# dispositivo de renderização: arquivo PNG container da imagem resultante
png(
  filename=sprintf('img/both-%d.png', CONCURSO),
  width=1100, height=600, pointsize=9, family="Quicksand"
)

par(
  las=1, font=2,
  cex.axis=1.25, font.axis=2, col.axis="goldenrod4",  # labels do eixo Y
  cex.lab=1.5, font.lab=2, col.lab="dimgray"          # títulos laterais
)

minor=(min(numeros$frequencia)%/%10-1)*10 # limite inferior do eixo Y
major=(max(numeros$frequencia)%/%10+1)*10 # limite superior do eixo Y

# layout "2x1" com alturas das linhas proporcionais às amplitudes dos dados
layout(
  matrix(c(1, 2), nrow=2, ncol=1),
  heights=c(major-minor, 10*(max(numeros$latencia)%/%10+1))
)

# -- DIAGRAMA DAS FREQUÊNCIAS

par(mar=c(2.5, 5.5, 1, 1))

bar <- barplot(
  numeros$frequencia,
  names.arg=BAR_LABELS, cex.names=BAR_LABELS_CEX,
  font.axis=BAR_LABELS_FONT, col.axis=BAR_LABELS_COL,
  border=BAR_BORDER, col=BAR_COLORS, space=SPACE,
  ylim=c(minor, major),
  xpd=FALSE,            # inabilita renderização fora dos limites de Y
  yaxt='n'              # inabilita renderização default do eixo Y
)

title(ylab="Frequências", line=3.75)

yLab=seq.int(from=minor, to=major, by=10)
# renderiza o eixo Y conforme limites estabelecidos
axis(side=2, at=yLab, col=RULE_COL)
# renderiza "tick marks" extras no eixo Y
rug(head(yLab, -1)+5, side=2, ticksize=TICKSIZE, lwd=1, col=RULE_COL)

# renderiza texto e linha do valor esperado das frequências (= 6 * N / 60)
abline(h=CONCURSO/10, col=REF, lty="dotted")
X2=par("usr")[2]
text(X2, CONCURSO/10, "esperança", adj=ADJ, cex=TXT_CEX, font=TXT_FONT, col=REF)
# renderiza linhas de referência ordinárias evitando sobreposição
abline(h=yLab[yLab > minor & abs(10*yLab-CONCURSO) > 3], col=PALE, lty="dotted")

# renderiza o "box & whiskers" entre o eixo Y e primeira coluna
bp <- boxplot(
  numeros$frequencia, frame.plot=F, axes=F, add=T, at=BOX_AT,
  border=HOT, col=BOX_COL, yaxt='n', width=1.125
)

rect(
  0, bp$stats[2], bar[60]+bar[1], bp$stats[4], col="#ff00cc28",
  border="transparent", density=18
)

# renderiza o número do concurso mais recente na margem direita
text(X2, minor, CONCURSO, srt=90, adj=c(0, 0), cex=4, font=1, col="dimgray")

# -- DIAGRAMA DAS LATÊNCIAS

par(mar=c(2.5, 5.5, 0, 1))

major=(max(numeros$latencia)%/%10+1)*10   # limite superior do eixo Y

bar <- barplot(
  numeros$latencia,
  names.arg=BAR_LABELS, cex.names=BAR_LABELS_CEX,
  font.axis=BAR_LABELS_FONT, col.axis=BAR_LABELS_COL,
  border=BAR_BORDER, col=BAR_COLORS, space=SPACE,
  ylim=c(0, major),
  yaxt='n'
)

title(ylab="Latências", line=3.5)

yLab=seq.int(from=0, to=major, by=10)
axis(side=2, at=yLab, col=RULE_COL)
rug(head(yLab, -1)+5, side=2, ticksize=TICKSIZE, lwd=1, col=RULE_COL)

# renderiza texto e linha do valor esperado das latências (= 60 / 6)
abline(h=10, col=REF, lty="dotted")
text(X2, 10, "esperança", adj=ADJ, cex=TXT_CEX, font=TXT_FONT, col=REF)
# renderiza linhas de referência ordinárias evitando sobreposição
abline(h=c(5, yLab[yLab > 10]), col=PALE, lty="dotted")

bp <- boxplot(
  numeros$latencia, frame.plot=F, axes=F, add=T, at=BOX_AT,
  border=HOT, col=BOX_COL, yaxt='n', width=1.125
)

rect(
  0, bp$stats[2], bar[60]+bar[1], bp$stats[4], col="#ff00cc28",
  border="transparent", density=18
)

dev.off() # finaliza a renderização e fecha o arquivo
