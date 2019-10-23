#!/usr/bin/Rscript --no-init-file

# REINCIDÊNCIA é quando ocorre repetição de um ou mais números em concursos
# consecutivos e quando num concurso qualquer não há aposta vencedora do prêmio
# principal, haverá sua ACUMULAÇÃO para o seguinte. A hipótese de que esses
# eventos ocorrem independentemente entre si está confirmada a seguir.

library(RSQLite)
con <- dbConnect(SQLite(), dbname='megasena.sqlite')
datum <- dbGetQuery(con,
  "SELECT acumulado, reincidente FROM (
     SELECT a.concurso, ((a.dezenas & b.dezenas) != 0) AS reincidente
     FROM dezenas_juntadas AS a JOIN dezenas_juntadas AS b
       ON a.concurso-1 == b.concurso
   ) JOIN concursos USING(concurso)")
dbDisconnect(con)

cat('-- Acumulação x Reincidência nos Concursos da Mega-Sena --\n')

tabela <- table(datum)[c('1','0'),c('1','0')]

cat('\nTabela de contingência das observações:\n\n')
dimnames(tabela) <- list(
  'acumulado' = c('S', 'N'),
  'reincidente' = c('S', 'N')
)
print(addmargins(tabela)) # output de sumário da tabela

teste <- chisq.test(
  tabela,
  correct = FALSE   # não aplica a correção de Yates
)

cat('\n  H0: Os eventos são independentes.')
cat('\n\n  método:', teste$method)
cat(sprintf('\n\n%21s %f', 'X²-amostral =', teste$statistic))
cat(sprintf('\n%20s %d', 'gl =', teste$parameter))
cat(sprintf('\n\n%20s %f', 'p-value =', teste$p.value))
coef.level = .05
cat(sprintf('\n%21s %f', 'α =', coef.level))
cat('\n\nConclusão:',
  ifelse(teste$p.value > coef.level, 'Não rejeitamos', 'Rejeitamos'),
  'a hipótese nula.\n\n')
