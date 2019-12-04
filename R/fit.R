#!/usr/bin/Rscript --slave --no-restore --no-init-file
#
# Renderiza o gráfico da série histórica das probabilidades do Erro Tipo I nos
# testes de aderência das distribuições de frequências dos números sorteadas nos
# concursos da Mega-Sena, criando e se necessário, atualizando a tabela de
# valores da estatística e respectivas probabilidades a cada concurso.
#
library(RSQLite)
con <- dbConnect(SQLite(), "megasena.sqlite")

# verifica se o db contém a tabela "fit"
if (dbExistsTable(con, "fit")) {
  # requisita o número de registros na tabela de resultados dos testes
  nr=dbGetQuery(con, "SELECT COUNT(*) FROM fit")[1,1]
} else {
  cat('\n> Criação e preenchimento da tabela "fit" em andamento.\n')
  query <- "-- tabela dos testes de aderência dos números nos concursos
CREATE TABLE IF NOT EXISTS fit (
  concurso    INTEGER UNIQUE,
  estatistica DOUBLE,
  pvalue      DOUBLE CHECK (pvalue >= 0 AND pvalue <= 1),
  FOREIGN KEY (concurso) REFERENCES concursos(concurso)
)"
  rs <- dbSendStatement(con, query)
  dbClearResult(rs)
  nr=0
}

# requisita o número de registros da tabela de concursos
nrecs=dbGetQuery(con, "SELECT COUNT(*) AS NRECS FROM concursos")[1,1]

# atualiza a tabela de testes de aderência se o seu número de registros
# é menor que o número de registros da tabela de concursos
if (nr < nrecs) {
  # notifica a operação em andamento
  cat("\n> Inclusão de", nrecs-nr, 'registro(s) à tabela "fit" iniciada.')
  # ativa a restrição que impede inserções de registros que
  # não correspondem a nenhum registro na tabela referenciada
  rs <- dbSendStatement(con, "PRAGMA FOREIGN_KEYS = ON")
  dbClearResult(rs)
  # requisita todos os números sorteados na série histórica dos concursos
  mega <- dbGetQuery(con, "SELECT concurso, dezena FROM dezenas_sorteadas")
  # atualização conforme número de registros a inserir
  if (nrecs-nr == 1) {
    teste <- chisq.test(tabulate(mega$dezena, nbins=60), correct=F)
    # registra os resultados do único teste
    query=sprintf("INSERT INTO fit SELECT %d, %f, %f", nrecs, as.double(teste$statistic), teste$p.value)
    rs <- dbSendStatement(con, query)
  } else {
    # "prepared statement" para inserção de registro na tabela fit
    query="INSERT INTO fit (concurso, estatistica, pvalue) VALUES ($concurso, $statistic, $pvalue)"
    rs <- dbSendStatement(con, query)
    if (nr == 0) {
      frequencias <- vector("integer", length=60)
    } else {
      frequencias <- tabulate(mega$dezena[mega$concurso <= nr], nbins=60)
    }
    # loop para inclusão de registros na tabela "fit"
    for (concurso in (nr+1):nrecs) {
      numeros <- mega$dezena[mega$concurso == concurso]
      frequencias[numeros] <- frequencias[numeros] + 1
      # executa o teste com dados tabulados até "concurso"
      teste <- chisq.test(frequencias, correct=(concurso < 1000))
      # registra os resultados do teste
      parameters <- list("concurso"=concurso, "statistic"=as.double(teste$statistic), "pvalue"=teste$p.value)
      dbBind(rs, parameters)
    }
  }
  dbClearResult(rs)
  cat(".finalizada.\n\n")
}

# requisita números de concursoss, respectivas probabilidades de testes de
# aderência e datas de sorteio
query='SELECT concurso, pvalue, data_sorteio FROM fit NATURAL JOIN concursos WHERE concurso >= 1'
mega <- dbGetQuery(con, query)
dbDisconnect(con)

nrecs=length(mega$concurso)

# prepara arquivo como dispositivo de impressão do gráfico
# com tamanho igual a dos frames de vídeo HD1080
png(filename="img/fit.png", width=1920, height=1080, pointsize=28, family="Quicksand")

par(
  mar=c(3, 4, 4, 1), font=2, bg="white",
  cex.main=1.2, font.main=2, col.main="steelblue",
  cex.lab=.9, font.lab=2, col.lab="steelblue",
  cex.axis=.8, font.axis=2, col.axis="gray40"
)

# renderiza a série das probabilidades nos testes de aderência
plot(
  mega$concurso,
  mega$pvalue,
  xlim=c(mega$concurso[1], mega$concurso[nrecs]),
  ylim=c(0, 1),
  ylab="",      # evita renderização de "dummy" label
  xlab="",
  type="p",     # "nebula" de pontos
  pch=1,        # símbolo dos pontos == circulo
  col="gold",   # cor de renderização dos pontos
  axes=FALSE    # inibe renderização dos eixos e do frame
)

title(main="Série do Erro Tipo I nos Testes das Frequências", line=2)
title(xlab="concursos", line=1.375)
title(ylab="probabilidade", line=2.5)

# eixo dos números dos concursos
z <- seq((mega$concurso[1] %/% 200 + 1)*200, mega$concurso[nrecs], 200)
axis(1, at=c(mega$concurso[1], z), tck=-0.015, mgp=c(0, .2, 0))
rug(z[z-100>mega$concurso[1]]-100, side=1, col="gray40", ticksize=-0.01, lwd=2)

# eixo das probabilidades
z <- seq(from=.1, to=1, by=.2)
axis(2, at=c(0, z+0.1), las=1, tck=-0.015, mgp=c(0, .75, 0))
rug(z, side=2, col="gray40", ticksize=-0.01, lwd=2)

# linhas referentes a valores de probabilidades
abline(h=c(0, z, z+0.1), lty="dotted", lwd=.8, col="gray50")

# texto e linha referente ao nível de confiança dos testes
abline(h=0.05, lty="dashed", lwd=1.125, col="red")
text(par("usr")[2], .05, "α = 5%", adj=c(1, -0.5), cex=.67, col="red")

# conecta os pontos da "nebula" para caracterização a priori
lines(mega$concurso, mega$pvalue, lty="solid", lwd=1, col="orangered")

# seleção dos primeiros concursos de cada ano componente da série
primeiros <- mega[!duplicated(substr(mega$data_sorteio, 0, 4)),]

# eixo dos anos de primeiros concursos -- somente labels visíveis
axis(
  3, at=primeiros$concurso,
  labels=substr(primeiros$data_sorteio, 0, 4),
  mgp=c(0, 0, 0),     # posiciona abaixo do default
  col='transparent',  # escala "invisível"
  font.axis=4, col.axis="mediumpurple"
)

# linhas verticais referentes aos anos de primeiros concursos
abline(v=primeiros$concurso, lty="dotted", lwd=1, col="gray50")

# anexa o concurso mais recente ao final de primeiros assegurando unicidade
if (tail(primeiros$concurso, 1) != mega$concurso[nrecs]) primeiros <- rbind(primeiros, mega[nrecs,])

# seleciona variáveis relevantes para ajustes
primeiros <- subset(primeiros, select=c("concurso", "pvalue"))

# evidencia os primeiros concursos de cada ano e o mais recente
points(primeiros, col="purple", pch=20)

# conecta os pontos dos primeiros concursos de cada ano e do mais recente
lines(primeiros, col="purple")

MODEL_NAME <- c("linear", "poly 2", "poly 3", "poly 4")
CORES <- c("darkgreen", "darkcyan", "navy", "darkred")
par(lwd=1.2)

# ajusta reta de mínimos quadrados às observações
fit <- lm(pvalue ~ concurso, data=primeiros)
lines(primeiros$concurso, predict(fit, primeiros), col=CORES[1])

# ajusta polinômio de grau 2
fit2 <- lm(pvalue ~ poly(concurso, 2, raw=T), data=primeiros)
lines(primeiros$concurso, predict(fit2, primeiros), col=CORES[2])

# ajusta polinômio de grau 3
fit3 <- lm(pvalue ~ poly(concurso, 3, raw=T), data=primeiros)
lines(primeiros$concurso, predict(fit3, primeiros), col=CORES[3])

# ajusta polinômio de grau 4
fit4 <- lm(pvalue ~ poly(concurso, 4, raw=T), data=primeiros)
lines(primeiros$concurso, predict(fit4, primeiros), col=CORES[4])

# pré-renderização da legenda para obter suas coordenadas e dimensões
leg <- legend(
  "topright", inset=c(0, 0.05), legend=MODEL_NAME, lwd=c(par("lwd")),
  cex=.75, seg.len=c(1), x.intersp=.5, lty=c(par("lty")), plot=FALSE
)

# renderização de facto usando as coordenadas e dimensões obtidas
legend(
  x=c(leg$rect$left-15, leg$rect$left+leg$rect$w),
  y=c(leg$rect$top, leg$rect$top-leg$rect$h),
  legend=MODEL_NAME, col=CORES, box.col="gray", box.lwd=1,
  seg.len=c(1), x.intersp=.5, lty=c(par("lty")), lwd=c(par("lwd")),
  cex=.75, text.col="gray50"
)

mtext(
  "Gerado via GNU R-cran.", side=1, line=2, adj=1.02, cex=.7, font=4, col="gray"
)

dev.off()  # finaliza o dispositivo gráfico
