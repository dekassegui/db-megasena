#!/usr/bin/Rscript --slave --no-restore

library(RSQLite)
con <- sqliteNewConnection(dbDriver('SQLite'), dbname='megasena.sqlite')

rs <- dbSendQuery(con, 'SELECT dezena FROM dezenas_sorteadas')
datum <- fetch(rs, n = -1)

dbClearResult(rs)
sqliteCloseConnection(con)

nrecs <- length(datum$dezena) / 6;

tabela <- table(datum$dezena)
dimnames(tabela) <- list(sprintf('(%02d)', 1:length(tabela)))

teste <- chisq.test(tabela, correct=FALSE)

cat('Frequências das dezenas nos', nrecs, 'concursos da Mega-Sena:\n\n')
print(tabela)
cat('\nTeste de Aderência Chi-square\n\n')
cat(' H0: As dezenas têm distribuição uniforme.\n')
cat(' HA: As dezenas não têm distribuição uniforme.\n')
cat(sprintf('\n\tX-square = %.4f', teste$statistic))
cat(sprintf('\n\t      df = %d', teste$parameter))
cat(sprintf('\n\t p-value = %.4f', teste$p.value))

if (teste$p.value > 0.05) action='Não rejeitamos' else action='Rejeitamos'
cat('\n\n', 'Conclusão:', action, 'H0 conforme evidências estatísticas.\n\n')
