library(RSQLite)
drv <- dbDriver('SQLite')
con <- sqliteNewConnection(drv, dbname='megasena.sqlite')

rs <- dbGetQuery(con,
  paste('SELECT M-N, N FROM',
  '(SELECT count(*) AS M, SUM(dezena % 2) AS N FROM dezenas_sorteadas)'))

x <- matrix(as.numeric(rs[,1:2]), ncol=2, byrow=TRUE)
dimnames(x) <- list(c('FREQ'), c('EVEN', 'ODD'))

cat('\nPARIDADES DAS DEZENAS DA MEGA-SENA\n\n')
x

prop.test(x, p=0.5, correct=FALSE)

sqliteCloseConnection(con)
