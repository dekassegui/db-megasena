#!/usr/bin/Rscript --no-init-file

library(RSQLite)
con <- dbConnect(SQLite(), dbname='megasena.sqlite')
datum <- dbGetQuery(con, 'SELECT dezena AS numero FROM dezenas_sorteadas')
dbDisconnect(con)

cat('-- Frequências dos Números nos Concursos da Mega-Sena --\n\n')

tabela <- table(datum$numero)
dimnames(tabela) <- list(
  sprintf('(%02d)', 1:length(tabela))
)
print(tabela)

teste <- chisq.test(
  tabela,
  correct=FALSE
)

cat('\nTeste de Aderência X²:\n')
cat('\nHØ: Os números têm distribuição uniforme.\n')
#cat(' HA: As dezenas não têm distribuição uniforme.\n')
cat(sprintf('\n%21s %f', 'X²-amostral =', teste$statistic))
cat(sprintf('\n%20s %d', 'df =', teste$parameter))
cat(sprintf('\n%20s %f', 'p-value =', teste$p.value))

cat('\n\nConclusão:', ifelse(teste$p.value > 0.05, 'Não rejeitamos',
  'Rejeitamos'), 'HØ se α=5%.\n')
