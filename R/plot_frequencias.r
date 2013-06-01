#!/usr/bin/Rscript

library(RSQLite, quietly=TRUE)
con <- sqliteNewConnection(dbDriver('SQLite'), dbname='megasena.sqlite')

rs <- dbSendQuery(con, 'SELECT dezena FROM dezenas_sorteadas')
datum <- fetch(rs, n = -1)

dbClearResult(rs)
sqliteCloseConnection(con)

titulo = paste('Frequências das dezenas em', (length(datum$dezena) / 6), 'concursos da Mega-Sena')

# extrai a tabela das classes com suas respectivas frequências
tabela <- table(datum$dezena)

# prepara os rótulos das classes formatando os números das dezenas
dimnames(tabela) <- list(sprintf('%02d', 1:length(tabela)))

barplot(
  tabela,
  main=titulo,
  ylab='frequência',
  xlab='dezenas',
  border=c('#CC0000', '#CC00CC', '#FF6600', '#009933', '#0066FF'),
  space=4
)
