#!/usr/bin/Rscript --no-init-file

# O sorteio de "números consecutivos" nos concursos não surpreende, pois o
# universo dos possíveis números a sortear é muito pequeno. A proporção da
# quantidade de concursos com ocorrência do evento é investigada a seguir.

library(RSQLite)
con <- dbConnect(SQLite(), dbname='megasena.sqlite')
datum <- dbGetQuery(con, 'SELECT (mask GLOB "*11*") FROM bitmasks')
dbDisconnect(con)

cat('-- Números Consecutivos nos Concursos da Mega-Sena --\n')

tabela <- table(datum[[1]])[c('1','0')]

cat('\nTabela de contingência das observações:\n\n')
dimnames(tabela) <- list(
  'sequência' = c('S', 'N')
)
print(addmargins(tabela))  # sumário da tabela

p.null = round(tabela['S'] / sum(tabela) * 100) / 100

teste <- prop.test(
  tabela,
  p = p.null,       # valor hipotético da proporção
  correct = FALSE   # não aplica correção de Yates
)

teste$desvio = sqrt(teste$estimate * (1 - teste$estimate) / sum(tabela))

cat('\nProporção de concursos com ocorrência de números consecutivos:\n')
cat(sprintf('\n\t\t%f ± %f\n', teste$estimate, teste$desvio))

cat('\nTeste da proporção amostral:\n')
cat('\n\tHØ: A proporção é igual a', teste$null.value)
#cat('\n HA: A proporção não é igual a', ph, '\n')
cat('\n\n\tmétodo:', teste$method)

cat(sprintf('\n\n%21s %f', 'X²-amostral =', teste$statistic))
cat(sprintf('\n%20s %d', 'df =', teste$parameter))
cat(sprintf('\n\n%20s %f', 'p-value =', teste$p.value))
alfa = .05
cat(sprintf('\n%21s %f', 'α =', alfa))

cat('\n\nConclusão:',
    ifelse(teste$p.value > alfa, 'Não rejeitamos', 'Rejeitamos'),
    'HØ.\n')
