#!/usr/bin/Rscript

library(RSQLite)
con <- dbConnect(SQLite(), dbname='megasena.sqlite')

rs <- dbSendQuery(con, paste(
    'SELECT acumulado, 6-SUM(dezena % 2) AS even',
    'FROM dezenas_sorteadas NATURAL JOIN concursos',
    'GROUP BY concurso'))
datum <- dbFetch(rs)

dbClearResult(rs)
dbDisconnect(con)

cat('Montagem da tabela de contingência:\n\n')
tabela <- table(datum)
tabela <- t(tabela)
dimnames(tabela) <- list(
  ' paridade'=c(sprintf('= %d', 0:(dim(tabela)[1]-1))),
    acumulado=c('sim', 'não'))
print(tabela)
#addmargins(tabela)

# teste exato de Fisher :: oneroso demais
#fisher.test(tabela, alternative="t", workspace=9000000)

cat('\nTeste Chi-Square com p-value simulado via Método de Monte Carlo:\n')
teste <- chisq.test(tabela, simulate.p.value=TRUE)
cat('\n\t', sprintf('X-square = %.4f', teste$statistic))
cat('\n\t', sprintf('      df = %d', teste$parameter))
cat('\n\t', sprintf(' p-value = %.4f', teste$p.value))

tabela <- rbind(tabela[1,]+tabela[2,], tabela[3:5,], tabela[6,]+tabela[7,])
dimnames(tabela) <- list(' paridade'=c('< 2', '= 2', '= 3', '= 4', '> 4'), acumulado=c('sim', 'não'))
cat('\n\nRemontagem da tabela c/combinação de linhas que contém baixas frequências:\n\n')
print(tabela)

cat('\nTeste de Independência entre Eventos:\n')
cat('\n', 'H0: Os eventos são independentes.')
cat('\n', 'HA: Os eventos não são independentes.')

teste <- chisq.test(tabela)

cat('\n\n\t', sprintf('X-square = %.4f', teste$statistic))
cat('\n\t', sprintf('      df = %d', teste$parameter))
cat('\n\t', sprintf(' p-value = %.4f', teste$p.value))

if (teste$p.value > 0.05) action='Não rejeitamos' else action='Rejeitamos'
cat('\n\n', 'Conclusão:', action, 'H0 conforme evidências estatísticas.\n\n')
