#!/usr/bin/Rscript --no-init-file

# A proporção de números pares nos sorteios, 50% por intuição, é investigada
# a seguir.

library(RSQLite)
con <- dbConnect(SQLite(), dbname='megasena.sqlite')
datum <- dbGetQuery(con, 'SELECT (dezena % 2) as paridade FROM dezenas_sorteadas')
dbDisconnect(con)

cat('Paridade dos Números nos Concursos da Mega-Sena\n\n')

tabela <- table(datum$paridade, useNA='no') # tabela de contingência

dimnames(tabela) <- list(
  '__paridade__' = c('N', 'S')  # ordem natural da tabulação
)
ordem <- c('S', 'N')  # ordem que prioriza número de sucessos -- pares
cat('Tabela de contingência dos dados observados:\n\n')
print(addmargins(tabela[ ordem ]))

teste <- binom.test(
  tabela[ ordem ],    # reordenação priorizando número de sucessos
  p = .5,             # valor hipotético da proporção -- null.value
  alternative = 't'   # testa se a proporção é igual ao null.value
)

# estimativa do desvio padrão amostral -- dispersão
teste$desvio = sqrt(teste$estimate * (1 - teste$estimate) / sum(datum))

cat('\nProporção amostral de números pares:\n')
cat(sprintf('\n\t%f ± %f', teste$estimate, teste$desvio))

cat('\n\nTeste da proporção amostral:\n')
cat('\n\tmétodo:', teste$method)
cat('\n\n\tH0: A proporção é igual a', teste$null.value)
cat(sprintf('\n\n%20s %f', 'p-value =', teste$p.value))
alfa = .05
cat(sprintf('\n%21s %f', 'α =', alfa))

cat('\n\nConclusão:', ifelse((teste$p.value > 0.05), 'Não rejeitamos', 'Rejeitamos'), 'H0.\n\n')
