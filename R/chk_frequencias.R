#!/usr/bin/Rscript --slave --no-restore

library(RSQLite)
con <- dbConnect(SQLite(), dbname='megasena.sqlite')

rs <- dbSendQuery(con, 'SELECT COUNT(*) AS NRECS FROM concursos')
nrecs = dbFetch(rs)$NRECS
dbClearResult(rs)

rs <- dbSendQuery(con, 'SELECT frequencia FROM info_dezenas')
datum <- dbFetch(rs)

dbClearResult(rs)
dbDisconnect(con)

teste <- chisq.test(datum$frequencia, correct=FALSE)

cat('Frequências das dezenas nos', nrecs, 'concursos da Mega-Sena:\n')
cat('\n', datum$frequencia, '\n')
cat('Teste de Aderência Chi-square\n\n')
cat(' H0: As dezenas têm distribuição uniforme.\n')
cat(' HA: As dezenas não têm distribuição uniforme.\n')
cat(sprintf('\n\tX-square = %.4f', teste$statistic))
cat(sprintf('\n\t      df = %d', teste$parameter))
cat(sprintf('\n\t p-value = %.4f', teste$p.value))

if (teste$p.value > 0.05) action='Não rejeitamos' else action='Rejeitamos'
cat('\n\n', 'Conclusão:', action, 'H0 conforme evidências estatísticas.\n\n')
