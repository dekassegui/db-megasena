library(RSQLite)
drv <- dbDriver('SQLite')
con <- sqliteNewConnection(drv, dbname='megasena.sqlite')

resultSet <- dbGetQuery(con, 'select frequencia from info_dezenas')
frequencias <- as.vector(as.numeric(resultSet[,]))

cat('\n\nH₀: As dezenas tem distribuição uniforme.\nH₁: Há alguma tendência nos sorteios.\n\n')

result <- chisq.test(frequencias, correct=FALSE)
result

if (result$p.value > 0.05) {
  cat("\nConclusão: não rejeitamos H₀ ao nível de significância de 5%.\n\n")
} else {
  cat("\nConclusão: rejeitamos H₀ ao nível de significância de 5%.\n\n")
}
sqliteCloseConnection(con)
