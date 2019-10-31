#!/usr/bin/Rscript --no-init-file

# Máximas latências dos números da Mega-Sena

library(RSQLite)
con <- dbConnect(SQLite(), 'megasena.sqlite')

latencias <- vector(mode='integer', length=60)

for (numero in 1:60) {

  query <- paste("
WITH RECURSIVE this (z, s) AS (
    SELECT serie, serie || '0' FROM (
      SELECT GROUP_CONCAT(NOT(dezenas>>(", numero, "-1)&1), '') AS serie
      FROM dezenas_juntadas
    )
  ), zero (j) AS (
    SELECT INSTR(z, '00') FROM this
    UNION ALL
    SELECT j + INSTR(SUBSTR(z, j+1), '00') AS k FROM this, zero WHERE k > j
  ), core (i) AS (
    SELECT INSTR(s, '1') FROM this
    UNION ALL
    SELECT i + INSTR(SUBSTR(s, i), '01') AS k FROM this, core WHERE k > i
  ) SELECT INSTR(SUBSTR(s, i), '0')-1 AS latencia FROM this, core
    UNION ALL
    SELECT 0 AS latencia FROM zero")

  datum <- dbGetQuery(con, query)

  latencias[numero] = max(datum$latencia)
}

#print(latencias)

lastConcurso = dbGetQuery(con, 'SELECT MAX(concurso) FROM concursos')[1,1]
dbDisconnect(con)

X11(display=":0.0", family='Quicksand', width=12, height=6, pointsize=10)

m = min(latencias)
minor = m %/% 10 * 10
M = max(latencias);
major = ifelse((M %% 10 > 0), 10 * (M %/% 10 + 1), M)

barplot(
  latencias,
  main=list(sprintf('Máximas Latências #%d', lastConcurso), cex=1.25, font=2),
  names.arg=c(sprintf("%02d",1:60)), cex.names=1, col.axis='#222222', font.axis=2,
  space=.25, col=c('#ddeeff', '#ffff99'), border='#666666',
  ylim=c(minor, major+1), xpd=F, yaxt='n'
)

# personaliza o eixo y
axis(2, las=2, cex.axis=1, col.axis='#333333', font.axis=2, at=seq(minor, major, 10))

# linhas de referência ordinária
abline(h=seq((m %/% 10 + 1) * 10, M, 5), col="#aabbcc", lty=3)

# linhas que destacam o maior, o menor e a mediana das máximas latências
md = median(latencias)
abline(h=c(m, M, md), col='tomato', lty=3)

gd <- par()$usr; a=c(1, .3)
text(gd[2], md, "mediana", col='red', font=.88, adj=a)
text(gd[2], m, "mínimo", col='red', font=.88, adj=a)
text(gd[2], M, "máximo", col='red', font=.88, adj=a)

mtext("Gerado via GNU R-cran.", side=1, adj=1.03, line=4, cex=1, font=3, col='#999999')
