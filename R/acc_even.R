#!/usr/bin/Rscript --no-init-file

# ACUMULAÇÃO é quando não há aposta vencedora do prêmio principal num concurso
# e PARIDADE é a classificação dos números como par ou ímpar, que

library(RSQLite)
con <- dbConnect(SQLite(), dbname='megasena.sqlite')
datum <- dbGetQuery(con,
  "SELECT 6-SUM(dezena % 2) AS paridade, acumulado
   FROM dezenas_sorteadas NATURAL JOIN concursos GROUP BY concurso")
dbDisconnect(con)

cat('-- ACUMULAÇÂO x PARIDADE nos Concursos da Mega-Sena --\n\n')

tabela <- table(datum)[,c('1','0')]

cat('Tabela de contingência das observações:\n\n')
dimnames(tabela) <- list(
  'paridade' = c(sprintf('= %d', 0:(dim(tabela)[1]-1))),  # rótulos das classes
  ' acumulado' = c('S', 'N')
)
print(addmargins(tabela))  # sumário da tabela

cat('\nTeste de independência de eventos:\n')
cat('\n\tHØ: Os eventos são independentes.')

teste <- chisq.test(tabela, simulate.p.value=TRUE)

cat('\n\n\tmétodo:', teste$method)

cat(sprintf('\n\n%21s %f', 'X²-amostral =', teste$statistic))
cat(sprintf('\n%20s %d', 'df =', teste$parameter))
cat(sprintf('\n\n%20s %f', 'p-value =', teste$p.value))

cat('\n\nRemontagem da tabela c/combinação de linhas que contém baixas frequências:\n\n')
tabela <- rbind(tabela[1,]+tabela[2,], tabela[3:5,], tabela[6,]+tabela[7,])
dimnames(tabela) <- list(
  'paridade' = c('< 2', '= 2', '= 3', '= 4', '> 4'),
  'acumulado' = c('S', 'N')
)
print(addmargins(tabela))

cat('\nTeste de independência de eventos:\n')
cat('\n\tHØ: Os eventos são independentes.')
#cat('\n', 'HA: Os eventos não são independentes.')

teste <- chisq.test(tabela)

cat('\n\n\tmétodo:', teste$method)
cat(sprintf('\n\n%21s %f', 'X²-amostral =', teste$statistic))
cat(sprintf('\n%20s %d', 'df =', teste$parameter))
cat(sprintf('\n%20s %f', 'p-value =', teste$p.value))

cat('\n\nConclusão:', ifelse((teste$p.value >= 0.05), 'Não rejeitamos', 'Rejeitamos'), 'HØ se α = 5%.\n\n')
