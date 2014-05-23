#!/usr/bin/Rscript
require(RSQLite)
con <- dbConnect(dbDriver('SQLite'), dbname='megasena.sqlite', loadable.extension=TRUE)
datum <- dbGetQuery(con, 'SELECT dezena FROM dezenas_sorteadas')
dbDisconnect(con)

classes.range = 10  # amplitude das classes

cat(sprintf('\nDistribuição das %d dezenas observadas em %d grupos:\n\n', nrow(datum), (60 %/% classes.range)))

classes.bounds <- seq(from=0, to=60, by=classes.range) # limites das classes

frequencias <- table(cut(datum$dezena, classes.bounds, right=TRUE))
print(cbind(frequencias))

teste <- chisq.test(frequencias)
cat('\nTeste de Aderência Chi-square\n\n')
cat(' H0: Os grupos de dezenas têm distribuição uniforme.\n')
cat(' HA: Os grupos de dezenas não têm distribuição uniforme.\n')
cat(sprintf('\n frequência esperada dos grupos = %.2f\n', teste$expected[1]))
cat(sprintf('\n\tX-squared = %.4f', teste$statistic))
cat(sprintf('\n\t       df = %d', teste$parameter))
cat(sprintf('\n\t  p-value = %.4f', teste$p.value))
action = ifelse(teste$p.value > 0.05, 'Não rejeitamos', 'Rejeitamos')
cat('\n\n', 'Conclusão:', action, 'H0 conforme evidências estatísticas.\n\n')

png(filename='img/histo-dezenas-agrupadas.png', width=560, height=560, family='DejaVu Serif', pointsize=11)
op <- par(bg = "white", fg="darkgray")
hist(
  datum$dezena,
  classes.bounds,
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
