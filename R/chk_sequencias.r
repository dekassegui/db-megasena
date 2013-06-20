#!/usr/bin/Rscript

library(RSQLite)
con <- sqliteNewConnection(dbDriver('SQLite'), dbname='megasena.sqlite', loadable.extension=TRUE)

dbGetQuery(con, 'SELECT LOAD_EXTENSION("sqlite/more-functions.so")')
dbGetQuery(con, 'CREATE TEMP TABLE t AS SELECT mask60(dezenas) AS mask FROM dezenas_juntadas WHERE mask LIKE "%11%";')

rs <- dbSendQuery(con, 'SELECT nt AS yes, n-nt AS no FROM (SELECT COUNT(*) AS nt FROM t), (SELECT COUNT(*) AS n FROM concursos)')
datum <- fetch(rs, n=-1)

dbClearResult(rs)
sqliteCloseConnection(con)

dimnames(datum) <- list(' frequência', sequenciado=c('sim', 'não'))

ph = 0.4
teste <- prop.test(as.matrix(datum), correct=FALSE, p=ph, alternative='t')

nrec= sum(datum)
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
