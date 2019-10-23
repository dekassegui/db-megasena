#!/usr/bin/Rscript --no-init-file

# Investigação da hipótese de independência entre os eventos ACUMULAÇÃO - quando
# não há aposta vencedora do prêmio principal num concurso - e PARIDADE - quando
# as quantidades de números pares e de números ímpares sorteados num concurso
# são iguais.

library(RSQLite)
con <- dbConnect(SQLite(), dbname='megasena.sqlite')
datum <- dbGetQuery(con,
  "SELECT acumulado, (sum(dezena % 2) == 3) AS paridade
   FROM dezenas_sorteadas NATURAL JOIN concursos GROUP BY concurso")
dbDisconnect(con)

cat('-- Acumulaçâo × Paridade nos Concursos da Mega-Sena --\n\n')

tabela <- table(datum)[c('1','0'),c('1','0')]   # prioriza número de sucessos

cat('Tabela de contingência das observações:\n\n')
dimnames(tabela) <- list(
   'acumulado' = c('S', 'N'), # Sim ou Não
  '  paridade' = c('S', 'N')
)
print(addmargins(tabela))     # sumário da tabela

cat('\nHØ: Os eventos são independentes.\n')

teste <- chisq.test(tabela, correct=F)
print(teste)

cat('Conclusão:', ifelse(teste$p.value >= .05, 'Não rejeitamos', 'Rejeitamos'),
  'HØ se α = 5%.\n')