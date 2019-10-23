#!/usr/bin/Rscript --no-init-file

require(RSQLite)
con <- dbConnect(dbDriver('SQLite'), 'megasena.sqlite')
datum <- dbGetQuery(con, 'SELECT dezena AS numero FROM dezenas_sorteadas')
dbDisconnect(con)

classes.amplitude = 10

cat('\nDistribuição dos', nrow(datum), 'números observados em',
  (60 %/% classes.amplitude), 'categorias:\n\n')

# sequência dos limitantes inferiores das categorias (ou classes)
classes.limites <- seq(
  from = 0, to = 60, by = classes.amplitude
)

tabela <- table(
  cut(
    datum$numero,
    classes.limites,
    right = TRUE
  )
)
print(cbind(tabela))

teste <- chisq.test(tabela)

cat('\nTeste de Aderência Chi-square\n')
cat('\nHØ: Os grupos de dezenas têm distribuição uniforme.\n')
#cat(' HA: Os grupos de dezenas não têm distribuição uniforme.\n')
cat(sprintf('\nFrequência esperada dos grupos = %f\n', teste$expected[1]))
cat(sprintf('\n%21s %f', 'X²-amostral =', teste$statistic))
cat(sprintf('\n%20s %d', 'df =', teste$parameter))
cat(sprintf('\n%20s %f', 'p-value =', teste$p.value))
cat('\n\nConclusão:', ifelse(teste$p.value > 0.05, 'Não rejeitamos', 'Rejeitamos'), 'HØ se α=5%.\n\n')

png(filename='img/histo-dezenas-agrupadas.png', width=560, height=560, family='DejaVu Serif', pointsize=11)
op <- par(bg = "white", fg="darkgray")
hist(
  datum$numero,
  classes.limites,
  right=TRUE,
  col=c('yellowgreen', 'greenyellow'),
  axes=TRUE,
  #labels=TRUE
  main=list(
    'Histograma das dezenas agrupadas',
    cex=1.25,
    font=2
  ),
  ylab='frequências',
  xlab='dezenas agrupadas'
)
abline(h=teste$expected[1], col='red', lty='dotted')
dev.off()
