library(RSQLite)
drv <- dbDriver('SQLite')
con <- sqliteNewConnection(drv, dbname='megasena.sqlite', loadable.extensions=TRUE)
dbGetQuery(con, 'SELECT LOAD_EXTENSION("./sqlite/more-functions.so")')

dbGetQuery(con, paste('CREATE TEMP TABLE t AS', 'SELECT acumulado, MASK60(dezenas) LIKE "%11%" AS sequenciado FROM concursos NATURAL JOIN dezenas_juntadas'))

oo <- dbGetQuery(con,
        paste(
  'SELECT * FROM',
  '(SELECT COUNT(*) AS a FROM t WHERE acumulado AND sequenciado),',
  '(SELECT COUNT(*) AS b FROM t WHERE acumulado AND NOT sequenciado),',
  '(SELECT COUNT(*) AS c FROM t WHERE NOT acumulado AND sequenciado),',
  '(SELECT COUNT(*) AS d FROM t WHERE NOT acumulado AND NOT sequenciado)'))
oo
m <- matrix(as.numeric(oo[1:4]), ncol=2, byrow=TRUE)
dimnames(m) <- list(acumulado=c('sim','não'), sequenciado=c('sim','não'))
m

cat('\n\nH₀: Os eventos "concurso acumular" X "dezenas consecutivas sorteadas" são independentes entre si.\nH₁: Os eventos são associados entre si.\n\n')

result <- chisq.test(m, correct=FALSE)
result

if (result$p.value > 0.05) {
  cat("\nConclusão: não rejeitamos H₀ ao nível de significância de 5%.\n\n")
} else {
  cat("\nConclusão: rejeitamos H₀ ao nível de significância de 5%.\n\n")
}
sqliteCloseConnection(con)
