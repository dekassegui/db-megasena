#!/usr/bin/Rscript --slave --no-restore
#
# Renderiza o gráfico da série histórica das probabilidades do Erro Tipo I nos
# testes de aderência das distribuições de frequências das dezenas sorteadas nos
# concursos da Mega-Sena, criando e atualizando, se necessário, a tabela SQL de
# valores da estatística e respectivas probabilidades a cada concurso.
#
library(RSQLite)
con <- dbConnect(SQLite(), dbname='megasena.sqlite')

# verifica se entre as tabelas do db há alguma cujo nome é 'fit'
tabelas <- dbListTables(con)
for (nome in tabelas) {
  found <- nome == 'fit'  # preserva o resultado da comparação
  if (found) break        # finalização antecipada do loop conforme resultado
}
if (found) {
  # obtêm o número de registros na tabela de testes de aderência
  nr <- dbGetQuery(con, 'SELECT COUNT(*) FROM fit')[1,1]
} else {
  cat('\nAtenção: montagem da tabela "fit" em andamento.\n\n')
  # cria a tabela dos testes de aderência
  query <- "CREATE TABLE IF NOT EXISTS fit (
  concurso    INTEGER UNIQUE,
  estatistica DOUBLE,
  pvalue      DOUBLE CHECK (pvalue >= 0 AND pvalue <= 1),
  FOREIGN KEY (concurso) REFERENCES concursos(concurso)
)"
  dbGetQuery(con, query)
  nr <- 0
}

# consulta o número de registros da tabela de concursos
nrecs <- dbGetQuery(con, 'SELECT COUNT(*) AS NRECS FROM concursos')[1,1]

# atualiza a tabela de testes de aderência se o seu número de registros
# for menor que o número de registros da tabela de concursos
if (nr < nrecs) {
  # ativa a restrição que impede inserções de registros que
  # não correspondem a nenhum registro na tabela referenciada
  dbGetQuery(con, 'PRAGMA FOREIGN_KEYS = ON')
  # loop pelos registros na tabela concursos
  for (concurso in (nr+1):nrecs) {
    # obtêm a lista das dezenas sorteadas até o concurso corrente
    query <- sprintf('SELECT dezena FROM dezenas_sorteadas WHERE concurso <= %d', concurso)
    rs <- dbSendQuery(con, query)
    datum <- fetch(rs, n=-1)
    # monta a "tabela" de contingência
    frequencias <- tabulate(datum$dezena, nbins=60)
    # executa o teste de aderência
    teste <- chisq.test(frequencias, correct=FALSE)
    # atualiza a tabela de testes de aderência
    query <- sprintf('INSERT INTO fit (concurso, estatistica, pvalue) VALUES (%d, %f, %f)', concurso, teste$statistic, teste$p.value)
    dbSendQuery(con, query)
  }
}

# prepara arquivo como dispositivo de impressão do gráfico
# com tamanho igual a dos frames de vídeo HD1080
png(filename='img/fit.png', width=1920, height=1080,
    family='Liberation Sans', pointsize=28)

# obtêm todas as probabilidades dos testes de aderência
rs <- dbSendQuery(con, "SELECT pvalue FROM fit")
datum <- fetch(rs, n=-1)

# renderiza a sequencia de valores das probabilidades dos testes de aderência
plot(
  datum$pvalue,
  ylim=c(0, 1),
  main="Mega-Sena :: Série das Probabilidades do Erro Tipo I nos Testes de Aderência",
  cex.main=1.25,          # amplia o tamanho da fonte do título
  lab=c(8, 5, 4),
  ylab="Probabilidade",
  xlab="concurso",
  pch=1,                  # usa circulo vazado como símbolo
  col="#00CC99",          # cor de renderização dos simbolos
  col.lab="#993300",      # cor de renderização dos títulos dos eixos
  col.axis="#006633",     # cor de renderização dos valores nos eixos
  bty='n',                # inabilita renderização das bordas
  yaxt='n'
)
axis(2, las=2, col.axis="#006633")

# obtém os números dos primeiros concursos em cada ano
rs <- dbSendQuery(con, "SELECT MIN(concurso) as concurso FROM concursos GROUP BY STRFTIME('%Y', data_sorteio)")
datdois <- fetch(rs, n=-1)

# evidencia os valores dos primeiros concursos em cada ano
for (nr in 1:length(datdois$concurso)) {
  concurso <- datdois$concurso[nr]
  # usa cor diferente para o primeiro concurso
  color <- ifelse(concurso == 1, '#ff66cc', '#cc9900')
  points(concurso, datum$pvalue[concurso], col=color, pch=20)
}

# evidencia o valor do concurso mais recente
points(nrecs, datum$pvalue[nrecs], col='#ff2800', pch=18)

# renderiza linha horizontal de referência :: nível de confiança dos testes
#segments(0, 0.05, nrecs, 0.05, col="red", lty=3)
abline(
  h=0.05,
  col="red", lty=1
)

# renderiza a reta de mínimos quadrados ajustada a todas observações
abline(
  lm(datum$pvalue ~ c(1:nrecs)),
  col='blue', lty=1
)

# renderiza legenda dos segmentos de referência
gd <- par()$usr   # coordenadas dos extremos do dispositivo de renderização
legend(
  3*(gd[1]+gd[2])/4, gd[4],   # coordenada (x,y) da legenda
  bty='n',                    # omite renderização de bordas
  col=c('red','blue'),        # cores dos segmentos
  lty=c(1, 1),                # tipos de linhas
  legend=c(                   # textos associados
    '𝛂 = 0.05',
    'Best fit'
  )
)

dev.off()  # finaliza o dispositivo gráfico

dbClearResult(rs)
dbDisconnect(con)
