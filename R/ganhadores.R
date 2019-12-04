#!/usr/bin/Rscript --no-init-file

library(RSQLite)
con <- dbConnect(SQLite(), dbname='megasena.sqlite')
datum <- dbGetQuery(con, 'SELECT uf FROM ganhadores')
dbDisconnect(con)

brasil <- list(
  "norte"=list( ufs=c("AC", "AM", "AP", "PA", "RO", "RR", "TO"), acro='N' ),
  "nordeste"=list( ufs=c("AL", "BA", "CE", "MA", "PB", "PE", "PI", "RN", "SE"), acro='NE' ),
  "sul"=list( ufs=c("PR", "RS", "SC"), acro='S' ),
  "sudeste"=list( ufs=c("ES", "MG", "RJ", "SP"), acro='SE' ),
  "centroeste"=list( ufs=c("DF", "GO", "MS", "MT"), acro='CE' ),
  "online"=list( ufs=c("XX"), acro='OL' )
)
# ordem preferencial das regiões
ordem <- vector("integer", 6)
for (i in 1:6) ordem[i] <- brasil[[i]]$acro

# monta data frame com a tabela de contingência das unidades federativas
dat <- data.frame(table(datum$uf))
names(dat) <- c('uf', 'count')
# agrega coluna das regiões de cada unidade federativa
for (regiao in brasil) {
  dat[dat$uf %in% regiao$ufs, "regiao"] <- regiao$acro
}

# inicia data frame com as somas das frequências das unidades federativas
# nas regiões, nomeando a respectiva coluna convenientemente
regioes <- aggregate(dat$count, list(regiao=dat$regiao), sum)
names(regioes)[2] <- "count"
# agrega colunas das médias e variâncias das regiões
regioes$media <- tapply(dat$count, dat$regiao, mean)
regioes$variancia <- tapply(dat$count, dat$regiao, var)
# reordena linhas na ordem preferencial das regiões e exclui a coluna "regiao"
regioes <- regioes[match(ordem, regioes$regiao), -1]
# renomeia linhas com acronismos das regiões na ordem preferencial
row.names(regioes) <- ordem

cat("Ganhadores da Mega-Sena x Região:\n\n")
options(digits=4)
print(regioes)
