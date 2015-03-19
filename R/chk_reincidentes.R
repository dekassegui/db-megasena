#!/usr/bin/Rscript

library(RSQLite)
con <- dbConnect(SQLite(), dbname='megasena.sqlite', loadable.extension=TRUE)

rs <- dbSendQuery(con, "
  SELECT
    ((SELECT dezenas FROM dezenas_juntadas
      WHERE concurso == concursos.concurso)
     &
     (SELECT dezenas FROM dezenas_juntadas
      WHERE concurso == concursos.concurso-1)) >= 1 AS reincidente
  FROM
    concursos"
)
datum <- fetch(rs, n=-1)

dbClearResult(rs)
dbDisconnect(con)

tabela <- table(datum$reincidente, useNA='no')
aux <- tabela[1]
tabela[1] <- tabela[2]
tabela[2] <- aux
dimnames(tabela) <- list(c('sim', 'não'))
cat('Reincidências nos concursos da Mega-Sena:\n\n')
#print(tabela)
cat(sprintf('\t%s\t%s\n', 'sim', 'não'))
cat(sprintf('\t%d\t%d\n', tabela['sim'], tabela['não']))

ph = 0.5
teste <- prop.test(tabela, p=ph, alternative='t', correct=FALSE)
teste$desvio = sqrt(teste$estimate * (1 - teste$estimate) / sum(tabela))

cat('\nProporção de concursos em que ocorreram reincidências:\n\n')
cat(sprintf(' estimativa ± desvio padrão = %.4f ± %.4f', teste$estimate, teste$desvio), '\n\n')

cat('Teste da proporção amostral:\n')
cat('\n', 'H0: A proporção é igual a', ph)
cat('\n', 'HA: A proporção não é igual a', ph)
cat(sprintf('\n\n\tX-square = %.4f', teste$statistic))
cat(sprintf('\n\t      df = %d', teste$parameter))
cat(sprintf('\n\t p-value = %.4f', teste$p.value))

if (teste$p.value > 0.05) action='Não rejeitamos' else action='Rejeitamos'
cat('\n\n', 'Conclusão:', action, 'H0 conforme evidências estatísticas.\n\n')
