#!/usr/bin/Rscript

library(RSQLite)
con <- dbConnect(SQLite(), dbname='megasena.sqlite')

rs <- dbSendQuery(con, 'SELECT COUNT(concurso) as size FROM concursos')
size=dbFetch(rs)$size
dbClearResult(rs)

rs <- dbSendQuery(con, paste(
    'SELECT M-odd AS even, odd FROM',
    '(SELECT count(*) AS M, SUM(dezena % 2) AS odd FROM dezenas_sorteadas)'))
datum <- dbFetch(rs)

dbClearResult(rs)
dbDisconnect(con)

rownames(datum)=' amount'
ph = 0.5
teste <- prop.test(as.matrix(datum), p=ph, alternative='t', correct=FALSE)
teste$desvio = sqrt(teste$estimate * (1 - teste$estimate) / sum(datum))

cat('Paridades das dezenas nos', size, 'concursos da Mega-Sena:\n\n')
print(datum)
cat('\nProporção de dezenas pares:\n\n')
cat(sprintf(' estimativa ± desvio padrão = %.4f ± %.4f', teste$estimate, teste$desvio), '\n\n')
cat('Teste da proporção amostral:\n')
cat('\n', 'H0: A proporção é igual a', ph)
cat('\n', 'HA: A proporção não é igual a', ph)
cat(sprintf('\n\n\tX-square = %.4f', teste$statistic))
cat(sprintf('\n\t      df = %d', teste$parameter))
cat(sprintf('\n\t p-value = %.4f', teste$p.value))

if (teste$p.value > 0.05) action='Não rejeitamos' else action='Rejeitamos'
cat('\n\n', 'Conclusão:', action, 'H0 conforme evidências estatísticas.\n\n')
