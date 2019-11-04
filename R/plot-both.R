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

# -- parâmetros compartilhados pelos diagramas

MAIN_CEX=1.4      # fator de expansão da fonte de título de diagrama
MAIN_FONT=2       # estilo de fonte em negrito
MAIN_COL='gray9'  # cor do texto de título de diagrama

BAR_LABELS <- c(sprintf('%02d', 1:60))  # labels das colunas (ou barras)
BAR_LABELS_CEX=1.25
BAR_LABELS_FONT=2
BAR_LABELS_COL='gray0'

# cores para preenchimento "zebrado" das colunas, exceto as filtradas
BAR_COLORS <- rep_len(c('gold', 'orange'), 60)
attach(numeros)
BAR_COLORS[ 10*frequencia < CONCURSO & latencia > 9 ]='darkorange2'
detach(numeros)

BAR_BORDER='gray33' # cor das bordas das colunas
SPACE=0.25            # espaçamento entre colunas

Y_AXIS=2        # eixo Y -- lado esquerdo
AXIS_LAS=2      # labels perpendiculares ao eixo
AXIS_CEX=1.25
AXIS_FONT=2
AXIS_COL='gray0'  # cor do eixo e labels no eixo Y

TICKSIZE=-0.0175  # comprimento de "tick marks"
LWD=.75           # espessura de linha de "tick marks"
LEND='round'
LJOIN='mitre'

HOT='red'       # cor para destacar linhas, textos, etc.

ADJ=c(1, -0.5)  # ajuste para alinhar texto a direita e "acima"
TXT_CEX=0.85
TXT_FONT=2

PALE='gray79'   # cor "discreta" das linhas de referência ordinárias
LTY='dotted'    # estilo das linhas de referência

BOX_AT=-1.25            # posição do "box & whiskers"
BOX_COL=c('mistyrose')  # cores de preenchimento dos "box & whiskers"

# dispositivo de renderização: arquivo PNG container da imagem resultante
png(
  filename=sprintf('img/both-%d.png', CONCURSO),
  width=1100, height=600, pointsize=9, family="Quicksand"
)

split.screen(c(2, 1))   # configura layout "2 x 1"

screen(1)   # DIAGRAMA DAS FREQUÊNCIAS

minor=(min(numeros$frequencia) %/% 10 - 1) * 10   # limite inferior do eixo Y
major=max(numeros$frequencia) + 1                 # limite superior do eixo Y

barplot(
  numeros$frequencia,
  main=list(
    sprintf('Frequências dos números #%d', CONCURSO),
    cex=MAIN_CEX, font=MAIN_FONT, col=MAIN_COL
  ),
  names.arg=BAR_LABELS, cex.names=BAR_LABELS_CEX,
  font.axis=BAR_LABELS_FONT, col.axis=BAR_LABELS_COL,
  border=BAR_BORDER, col=BAR_COLORS, space=SPACE,
  ylim=c(minor, major),
  xpd=FALSE,            # evita renderização fora dos limites de Y
  yaxt='n'              # evita renderização default do eixo Y
)

yLab=seq.int(from=minor, to=major, by=10)

# renderiza o eixo Y conforme limites previamente estabelecidos
axis(
  Y_AXIS, las=AXIS_LAS,
  cex.axis=AXIS_CEX, font.axis=AXIS_FONT, col.axis=AXIS_COL,
  at=yLab
)

# renderiza "tick marks" extras no eixo Y
rug(
  head(yLab, -1)+5, side=Y_AXIS, col=AXIS_COL, ticksize=TICKSIZE, lwd=LWD,
  lend=LEND, ljoin=LJOIN
)

# renderiza texto e linha do valor esperado das frequências (= 6 * N / 60)
abline(h=CONCURSO/10, col=HOT, lty=LTY)
X2=par()$usr[2]
text(X2, CONCURSO/10, "esperança", adj=ADJ, cex=TXT_CEX, font=TXT_FONT, col=HOT)
# renderiza linhas de referência ordinárias evitando sobreposição
abline(h=yLab[yLab > minor & abs(10*yLab-CONCURSO) > 3], col=PALE, lty=LTY)

# renderiza o "box & whiskers" entre o eixo Y e primeira coluna
boxplot(
  numeros$frequencia, outline=T, frame.plot=F, add=T, at=BOX_AT,
  border=HOT, col=BOX_COL, yaxt='n'
)

screen(2)   # DIAGRAMA DAS LATÊNCIAS

major=max(numeros$latencia) + 1   # limite superior do eixo Y

barplot(
  numeros$latencia,
  main=list(
    sprintf('Latências dos números #%d', CONCURSO),
    cex=MAIN_CEX, font=MAIN_FONT, col=MAIN_COL
  ),
  names.arg=BAR_LABELS, cex.names=BAR_LABELS_CEX,
  font.axis=BAR_LABELS_FONT, col.axis=BAR_LABELS_COL,
  border=BAR_BORDER, col=BAR_COLORS, space=SPACE,
  ylim=c(0, major),
  yaxt='n'
)

yLab=seq.int(from=0, to=major, by=10)

axis(
  Y_AXIS, las=AXIS_LAS,
  cex.axis=AXIS_CEX, font.axis=AXIS_FONT, col.axis=AXIS_COL,
  at=yLab
)

rug(
  head(yLab, -1)+5, side=Y_AXIS, col=AXIS_COL, ticksize=TICKSIZE, lwd=LWD,
  lend=LEND, ljoin=LJOIN
)

# renderiza texto e linha do valor esperado das latências (= 60 / 6)
abline(h=10, col=HOT, lty=LTY)
text(X2, 10, "esperança", adj=ADJ, cex=TXT_CEX, font=TXT_FONT, col=HOT)
# renderiza linhas de referência ordinárias evitando sobreposição
abline(h=c(5, yLab[yLab > 10]), col=PALE, lty=LTY)

boxplot(
  numeros$latencia, outline=T, frame.plot=F, add=T, at=BOX_AT,
  border=HOT, col=BOX_COL, yaxt='n'
)

# renderiza footer na extremidade inferior direita
mtext(
  paste("Concurso", CONCURSO, "da Mega-Sena"),
  side=1, adj=1.015, line=3.9, cex=1.15, font=4, col='lightslategray'
)

close.screen(all=T)

dev.off() # finaliza a renderização e fecha o arquivo
