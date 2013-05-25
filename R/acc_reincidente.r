library(RSQLite)
drv <- dbDriver('SQLite')
con <- sqliteNewConnection(drv, dbname='megasena.sqlite')

dbGetQuery(con, paste('CREATE TEMP TABLE t AS', 'SELECT acumulado, CASE WHEN (SELECT dezenas FROM dezenas_juntadas WHERE concurso == concursos.concurso) & (SELECT dezenas FROM dezenas_juntadas WHERE concurso == concursos.concurso-1) > 0 THEN 1 ELSE 0 END AS reincidente FROM concursos'))

oo <- dbGetQuery(con,
        paste(
  'SELECT * FROM',
  '(SELECT COUNT(*) AS a FROM t WHERE acumulado AND reincidente),',
  '(SELECT COUNT(*) AS b FROM t WHERE acumulado AND NOT reincidente),',
  '(SELECT COUNT(*) AS c FROM t WHERE NOT acumulado AND reincidente),',
  '(SELECT COUNT(*) AS d FROM t WHERE NOT acumulado AND NOT reincidente)'))
oo
m <- matrix(as.numeric(oo[1:4]), ncol=2, byrow=TRUE)
dimnames(m) <- list(acumulado=c('sim','não'), reincidente=c('sim','não'))
m

cat('\n\nH₀: Os eventos "concurso acumular" X "sorteio de dezenas reincidentes" são independentes entre si.\nH₁: Os eventos são associados entre si.\n\n')

result <- chisq.test(m, correct=FALSE)
result

if (result$p.value > 0.05) {
  cat("\nConclusão: não rejeitamos H₀ ao nível de significância de 5%.\n\n")
} else {
  cat("\nConclusão: rejeitamos H₀ ao nível de significância de 5%.\n\n")
}
sqliteCloseConnection(con)
