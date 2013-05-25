library(RSQLite)
drv <- dbDriver('SQLite')
con <- sqliteNewConnection(drv, dbname='megasena.sqlite')

rs <- dbGetQuery(con, 'SELECT a, n-a FROM (SELECT SUM(acumulado) AS a, COUNT(acumulado) AS n FROM concursos)')

x <- as.table(as.numeric(rs[,1:2]))
names(x) <- c('ACC', 'WIN')
x

prop.test(x, p=0.5, alternative='t')

sqliteCloseConnection(con)
