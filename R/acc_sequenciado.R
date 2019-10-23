#!/usr/bin/Rscript --no-init-file

# Investigamos a seguir, se a acumulação do prêmio principal nos concursos está
# relacionada com ocorrência de números consecutivos nos sorteios dos concursos.

library(RSQLite)
con <- dbConnect(SQLite(), dbname='megasena.sqlite')
datum <- dbGetQuery(con,
  "SELECT acumulado,
    (mask GLOB '*11*') AS sequenced      --> ao menos uma sequência
   FROM concursos NATURAL JOIN bitmasks"
)
dbDisconnect(con)

cat('-- Acumulação x Sequências nos Concursos da Mega-Sena --\n\n')

tabela <- table(datum)[c('1','0'), c('1','0')]  # reordenação prioriza sucessos

cat('Tabela de contingência das observações:\n\n')
dimnames(tabela) <- list(
   'acumulado' = c('S', 'N'),  # Sim ou Não
  ' sequência' = c('S', 'N')
)
print(addmargins(tabela))   # sumário da tabela

teste <- chisq.test(
  tabela,
  correct=FALSE   # não aplica a correção de Yates
)

cat('\nTeste de Independência entre Eventos:\n')
cat('\n\tH0: Os eventos são independentes.')
#cat('\n\tHA: Os eventos não são independentes.'
cat('\n\n\tmétodo:', teste$method)
cat(sprintf('\n\n%21s %f', 'X²-amostral =', teste$statistic))
cat(sprintf('\n%20s %d', 'df =', teste$parameter))
cat(sprintf('\n\n%20s %f', 'p-value =', teste$p.value))

cat('\n\nConclusão:',
  ifelse((teste$p.value > 0.05), 'Não rejeitamos', 'Rejeitamos'), 'H0.\n\n')
