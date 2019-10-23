#!/usr/bin/Rscript --no-init-file

# REINCIDÊNCIA é a repetição de um ou mais números em concursos consecutivos,
# cuja proporção do número de concursos em que ocorreram ao longo do tempo é
# hipoteticamente igual a 50% ou seja; ocorre a cada dois concursos.

library(RSQLite)
con <- dbConnect(SQLite(), dbname='megasena.sqlite')
datum <- dbGetQuery(con,
  "SELECT ((a.dezenas & b.dezenas) != 0) AS reincidente
   FROM dezenas_juntadas AS a JOIN dezenas_juntadas AS b
     ON a.concurso-1 == b.concurso"
)
dbDisconnect(con)

cat('Reincidências nos Concursos da Mega-Sena\n')

tabela <- table(datum$reincidente, useNA='no')  # tabela de contingência

cat('\nTabela de contingência dos dados observados:\n\n')
dimnames(tabela) <- list(
  '_reincidência_' = c('N', 'S')    # ordem natural da tabulação
)
ordem <- c('S', 'N')                # prioriza o números de sucessos
print(addmargins(tabela[ ordem ]))  # output de sumário da tabela

teste <- prop.test(
  tabela[ ordem ],            # reordenação das colunas coerente com o teste
  p = 0.5,                    # valor hipotético da proporção de reincidências
  conf.level = .05,           # nível de significância do teste
  alternative = 'two.sided',  # teste de igualdade
  correct = FALSE             # não aplica a correção de Yates
)

teste$desvio = sqrt(teste$estimate * (1 - teste$estimate) / sum(tabela))

cat('\nProporção do número de concursos em que ocorreram reincidências:\n\n')
cat(sprintf('\t%f ± %f', teste$estimate, teste$desvio))

cat('\n\nTeste da proporção amostral:\n')
cat('\n\tH0: A proporção é igual a', teste$null.value)
#cat('\n\tHA: A proporção não é igual a', teste$null.value)
cat('\n\n\tmétodo:', teste$method)
cat(sprintf('\n\n\t%21s %f', 'X²-amostral =', teste$statistic))
cat(sprintf('\n\t%20s %d', 'df =', teste$parameter))
cat(sprintf('\n\n\t%20s %f', 'p-value =', teste$p.value))
alfa = attr(teste$conf.int, "conf.level")
cat(sprintf('\n\t%21s %f', 'α =', alfa))

cat('\n\nConclusão:', ifelse((teste$p.value > alfa), 'Não rejeitamos', 'Rejeitamos'), 'H0.\n\n')
