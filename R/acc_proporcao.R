#!/usr/bin/Rscript

library(RSQLite)
con <- dbConnect(SQLite(), dbname='megasena.sqlite')

rs <- dbSendQuery(con, 'SELECT COUNT(concurso) AS NREC FROM concursos')
nrec = dbFetch(rs)$NREC
dbClearResult(rs)

rs <- dbSendQuery(con, paste(
  'SELECT ACC, ', nrec, '-ACC AS WIN FROM',
  '(SELECT SUM(acumulado) AS ACC FROM concursos)'))
datum <- dbFetch(rs)

dbClearResult(rs)
dbDisconnect(con)

rownames(datum)=' amount'
ph = 0.8
teste <- prop.test(as.matrix(datum), alternative='less', p=ph, correct=FALSE)
teste$desvio = sqrt(teste$estimate * (1 - teste$estimate) / nrec)

cat('Frequência de concursos que acumularam nos', nrec, 'concursos da Mega-Sena:\n\n')
print(datum)
cat('\nProporção de concursos que acumularam:\n')
cat('\n', sprintf('estimativa ± desvio padrão = %.4f ± %.4f\n', teste$estimate, teste$desvio))
cat('\nTeste da proporção amostral:\n')

cat('\n H0: A proporção é maior ou igual a', ph)
cat('\n HA: A proporção é menor que', ph, '\n')

cat('\n', sprintf('X-square = %.4f', teste$statistic))
cat('\n', sprintf('      df = %d', teste$parameter))
cat('\n', sprintf(' p-value = %.4f', teste$p.value))

if (teste$p.value > 0.05) action='Não rejeitamos' else action='Rejeitamos'
cat('\n\n', 'Conclusão:', action, 'H0 conforme evidências estatísticas.\n\n')
