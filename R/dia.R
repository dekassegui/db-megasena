#!/usr/bin/Rscript --no-init-file
#
# Diagrama de frequências e latências dos números sorteados na Mega-Sena até o
# concurso mais recente - cujos dados estejam armazenados localmente - exibindo
# sumário de estatísticas de cada número, dos sorteios e do concurso.
#
library(RSQLite)
con <- dbConnect(SQLite(), 'megasena.sqlite')
# requisita o número do concurso mais recente e respectivo status de acumulação
mega <- dbGetQuery(con, 'SELECT MAX(concurso) AS concurso, acumulado FROM concursos')
# se ocorreu acumulação, então requisita a "latência da premiação principal"
if (mega$acumulado == 1) {
  mega$acumulado <- dbGetQuery(con, paste("
WITH RECURSIVE cte(n) AS (
  SELECT", mega$concurso, "
  UNION ALL
  SELECT n-1 AS m FROM cte, concursos WHERE concurso == m AND acumulado
) SELECT COUNT(1) FROM cte"))[1,1]
}
# requisita frequências e latências dos números no concurso mais recente
numeros <- dbGetQuery(con, 'SELECT frequencia, latencia FROM info_dezenas ORDER BY dezena')
# envia "prepared statement" para requisição da maior latência histórica de cada
# número -- identificada via SQL com muito bom desempenho
rs <- dbSendQuery(con, "SELECT MAX(latencia) AS maxLatencia FROM (
  WITH RECURSIVE this (s) AS (
    SELECT GROUP_CONCAT(NOT(dezenas >> ($NUMERO - 1) & 1), '') || '0'
    FROM dezenas_juntadas
  ), core (i) AS (
    SELECT INSTR(s, '1') FROM this
    UNION ALL
    SELECT i + INSTR(SUBSTR(s, i), '01') AS k FROM this, core WHERE k > i
  ) SELECT INSTR(SUBSTR(s, i), '0')-1 AS latencia FROM this, core
)")
# loop das requisições das máximas latências históricas de cada número
for (n in 1:60) {
  dbBind(rs, list('NUMERO'=n))
  dat <- dbFetch(rs)
  numeros[n, "maxLatencia"] <- dat$maxLatencia
}
dbClearResult(rs)
# requisita números sorteados no concurso anterior ao mais recente
anterior <- dbGetQuery(con, paste('SELECT dezena FROM dezenas_sorteadas where concurso ==', mega$concurso-1))
dbDisconnect(con)

rm(con, dat, rs)

{
  # probabilidade do erro tipo I se H: X ~ U[1;60]
  pvalue <- signif(chisq.test(numeros$frequencia, correct=F)$p.value, 4)

  cores <- colorRampPalette(c("lightgoldenrod1", "orange"))(60)
  ordem <- rank(numeros$frequencia, ties.method="min")
  numeros$corFundo <- cores[ordem]
  # garante matiz mais intenso para números com máxima frequência
  n <- numeros[which(ordem == 60), "frequencia"]
  numeros[numeros$frequencia == n, "corFundo"] <- "darkorange"

  cores <- colorRampPalette(c("gray25", "gray35", "gray75"))(60)
  numeros$corFrente <- cores[rank(numeros$latencia, ties.method="min")]
  # garante máxima tonalidade de cinza para números com mínima latência (=zero)
  numeros[numeros$latencia == 0, "corFrente"] <- "black"

  rm(cores, ordem)

  MIDDLE <- c(.5, .5); LEFTUP <- c(0, 1); LEFTDN <- c(0, 0)
  RIGHTUP <- c(1, 1); RIGHTDN <- c(1, 0)
}

png(filename='img/dia.png', width=1000, height=640, pointsize=10, family='Quicksand')

par(
  mar=c(.75, .75, 4.25, .75), font=2, cex.main=3.75, col.main="black"
)

plot(
  NULL, NULL, type="n", axes=F, xaxs='i', yaxs='i', xlim=c(0, 10), ylim=c(0, 6)
)

title(paste("Mega-Sena", mega$concurso), adj=0, line=1.1875)

# "background" do modelo de quadricula na área de notificação
rect(7.92, 6.06, 10, 6.45, xpd=TRUE, col="khaki1", border=NA)

# notificações e modelo de quadrícula renderizados como texto marginal
mtext(
  c("concursos acumulados:", mega$acumulado, "X~U[1;60] \u27A1 p.value:", pvalue, "frequência", "Atípico⁄Reincidente", "latência", "maior latência"),
  col=c("gray35", "darkred", "gray35", "darkred", "darkred", "black", "violetred", "firebrick"),
  side=3, cex=1.26,
  adj=c(1, 0, 1, 0, 0, 1, 0, 1),
  at=c(4.55, 4.59, 4.39, 4.43, 7.98, 9.94, 7.98, 9.94),
  line=c(2.4, 2.4, .9, .9, 2.1, 2.1, .7, .7)
)

# complementa a estatística com símbolo qualificador adequado
if (pvalue >= .05) n <- c("\uF00C", "dodgerblue") else n <- c("\uF00D", "red")
mtext(n[1], side=3, at=5, line=.9, adj=.5, cex=1.75, col=n[2])

for (n in 1:60) {
  x <- (n-1) %% 10
  y <- (n-1) %/% 10
  attach(numeros[n,])
  # renderiza a quadricula com cor em função da frequência
  rect(x, 5-y, x+1, 6-y, col=corFundo, border="white")
  # renderiza o número com cor em função da latência
  text(x+.5, 5-y+.5, sprintf("%02d", n), adj=MIDDLE, cex=4, col=corFrente)
  # frequência histórica
  text(x+.1, 6-y-.1, frequencia, adj=LEFTUP, cex=1.5, col="darkred")
  # checa se frequência abaixo do esperado e latência acima do esperado
  if (10*frequencia < mega$concurso & latencia >= 10) {
    text(x+1-.1, 6-y-.1, "A", adj=RIGHTUP, cex=1.25, col="black")
  } else if (latencia == 0) {
    # renderiza borda extra para evidenciar número recém sorteado
    #rect(
    #  x+.025, 5-y+.025, x+1-.025, 6-y-.025, col="transparent", border="black", lwd=2
    #)
    # checa se número é reincidente -- sorteado no concurso anterior
    if (n %in% anterior$dezena) {
      text(x+1-.1, 6-y-.1, "R", adj=RIGHTUP, cex=1.25, col="black")
    }
  }
  # latência imediata
  text(x+.1, 5-y+.1, latencia, adj=LEFTDN, cex=1.5, col="violetred")
  # máxima latência histórica
  text(x+1-.1, 5-y+.1, maxLatencia, adj=RIGHTDN, cex=1.5, col="firebrick")
  detach(numeros[n,])
}

dev.off()
