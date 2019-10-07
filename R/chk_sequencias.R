#!/usr/bin/Rscript

library(RSQLite)
con <- dbConnect(SQLite(), dbname='megasena.sqlite')

rs <- dbGetQuery(con, 'select count(*) from concursos')
nrec=as.integer(rs)

rs <- dbGetQuery(con, 'select count(*) from bitmasks where mask like "%11%"')
yes <- as.integer(rs)

dbDisconnect(con)

datum <- matrix(c(yes, nrec-yes), nrow=1, ncol=2, byrow=FALSE)

dimnames(datum) <- list(' frequência', sequenciado=c('sim', 'não'))

ph = 0.4
teste <- prop.test(datum, correct=FALSE, p=ph, alternative='t')

teste$desvio = sqrt(teste$estimate * (1 - teste$estimate) / nrec)

cat('Ocorrência de dezenas consecutivas nos', nrec, 'concursos da Mega-Sena:\n\n')
print(datum)

cat('\nProporção de concursos com ocorrência de dezenas consecutivas:\n')
cat('\n', sprintf('estimativa ± desvio padrão = %.4f ± %.4f\n', teste$estimate, teste$desvio))
cat('\nTeste da proporção amostral:\n')

cat('\n H0: A proporção é igual a', ph)
cat('\n HA: A proporção não é igual a', ph, '\n')

cat('\n', sprintf('X-square = %.4f', teste$statistic))
cat('\n', sprintf('      df = %d', teste$parameter))
cat('\n', sprintf(' p-value = %.4f', teste$p.value))

action = ifelse(teste$p.value > 0.05, 'Não rejeitamos', 'Rejeitamos')
cat('\n\n', 'Conclusão:', action, 'H0 conforme evidências estatísticas.\n\n')
