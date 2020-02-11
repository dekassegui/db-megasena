#!/usr/bin/Rscript --no-init-file
#
# ECDFs dos "tempos de espera" dos números da Mega-Sena, confrontadas com a CDF
# da distribuição Geométrica com probabilidade de sucesso igual a 10%, que é a
# probabilidade de qualquer número arbitrário ser um dos seis números sorteados.
#
library(RSQLite)
con <- dbConnect(SQLite(), "megasena.sqlite")

dat <- structure(vector("list", 100), class="data.frame")

# sql paramétrico para requisitar as sequências de incidências de NUMERO nos
# concursos, finalizadas no primeiro concurso com aposta vencedora, tal que:
#
#     N -> NUMERO arbitrário entre 1 e 60
#   ndx -> número de ordem de sequência
#   fim -> número serial do concurso com aposta vencedora que finaliza sequência
#   len -> tamanho de sequência de concursos = tempo de espera + 1
#
query="
with cte(s) as (
  select group_concat(dezenas >> ($NUMERO-1) & 1, '') from dezenas_juntadas
), one(n, p) as (
  select 1, instr(s, '1') from cte
  union all
  select n+1, p+instr(substr(s, p+1), '1') as m from cte, one where m > p
) select $NUMERO as N, n as ndx, p as fim, p as len from one where n == 1
  union all
  select $NUMERO, t.n, t.p, t.p-x.p from one as t join one as x on t.n == x.n+1
"
rs <- dbSendQuery(con, query)
for (n in 1:60) {
  dbBind(rs, list('NUMERO'=n))
  dat <- rbind(dat, dbFetch(rs))
}
dbClearResult(rs)
dbDisconnect(con)

# probabilidade de número arbitrário ser um dos 6 números retirados sem
# reposição do subconjunto dos números naturais entre 1 e 60
p.sucesso = dhyper(1, 1, 59, 6)

png(
  filename="img/espera.png",
  width=1000, height=640, pointsize=10, family="Roboto Condensed"
)

layout(
  matrix(c(rep.int(1, 10), 2:61), nrow=7, ncol=10, byrow=T),
  heights=c(lcm(1.25), rep.int(1, 10), rep.int(2, 60))
)

# renderização do título/legenda no topo da imagem (1a. linha)
par(mar=c(0, 0, 0, 0))
plot(0, 0, type="n", xlim=c(0, 10), ylim=c(0, 1), axes=F)
text(x=5.12, y=.56, adj=c(1, .5), "ECDF dos Tempos de Espera", cex=4, font=2, col="darkviolet")
text(x=5.25, y=.56, adj=c(.5, .5), "×", cex=4, font=2, col="dimgray")
text(
  x=5.38, y=.56, adj=c(0, .5),
  paste0("CDF da Geométrica(", signif(p.sucesso, 3), ")"),
  cex=4, font=2, col="green3"
)
points(
  x=seq(1.05, 1.75, .1), y=rep.int(.56, 8), pch=20, cex=2, col="darkviolet"
)
segments(8.25, .56, 8.95, .56, col="green2", lty="solid", lwd=3)

par(mar=rep.int(.25, 4), fg="green", xaxs="r", yaxs="r", xaxt='n', yaxt='n')

for (n in 1:60) {
  x <- dat[dat$N==n,]$len-1
  m <- max(x)
  RcmdrMisc::plotDistr(
    0:m, pgeom(0:m, .1), cdf=T, discrete=T, bty="n", lwd=3, xaxt='n', yaxt='n',
    xlab="", ylab="", main="", ylim=c(0, 1), xlim=c(0, m)
  )
  abline(h=c(.2, .4, .6, .8), col="gray77", lty="dotted")
  plot(
    ecdf(x), add=T, bty="n", verticals=F, pch=20, cex=1.5,
    col.points="darkviolet", main="", xlab="", ylab=""
  )
  a <- par("usr")
  rect(a[1], a[3], a[2], a[4], col="transparent", border="gray20")
  text(
    m/2, .5, adj=c(.4, .5), sprintf("%02d", n), cex=4, font=2, col="slategray"
  )
  pr <- with(tail(dat[dat$N==n,], 1), ndx/fim)
  text(m/2, .225, adj=c(.4, .5), sprintf("p=%5.3f", pr), cex=3, font=2, col="darkviolet")
  text(m/2, .225, adj=c(2.93, .45), "\u02C6", cex=3, font=2, col="darkviolet")
}

dev.off()

plota <- function (numero) {
  fname <- "img/cdf.png"
  png(fname, width=640, height=640, family='Roboto', pointsize=16)
  par(mar=c(4, 4, 2, 1), fg='green3', font=2)
  x <- dat[dat$N==numero,]$len-1
  m <- max(x)
  RcmdrMisc::plotDistr(
    0:m, pgeom(0:m, p.sucesso), cdf=T, discrete=T,
    bty='n', lwd=3, ylim=c(-.05, 1), xlim=c(0, m), yaxt='n', xaxt='n',
    main=paste0('ECDF x CDF Geométrica(', p.sucesso, ')'), xlab='', ylab=''
  )
  plot(ecdf(x), add=T, verticals=T, col='darkviolet', pch=20)

  par(fg="gray20")
  title(xlab=paste0('tempo de espera N=', numero), line=2.3)
  axis(side=1, seq.int(0, m, 10))
  rug(side=1, seq.int(5, m, 10), ticksize=-.0125, lwd=1)

  title(ylab='probabilidade', line=2.65)
  axis(side=2, seq(0, 1, .2), las=1)
  rug(side=2, seq(.1, .9, .2), ticksize=-.0125, lwd=1)

  a <- par('usr')
  rect(a[1], a[3], a[2], a[4], col='transparent', border='gray20')

  text(
    sprintf("%02d", numero), x=m/2, y=.5, adj=c(.5, .5), cex=10, col='gray92'
  )
  text(
    with(tail(dat[dat$N==numero,], 1), sprintf("p=%5.3f", ndx/fim)),
    x=m/2, y=.25, adj=c(.5, .5), cex=4, col='gray92'
  )
  text(x=m/2, y=.25, adj=c(3.7, .45), "\u02C6", cex=4, col="gray92")

  boxplot(
    x, add=T, horizontal=T, frame=F, at=-.04, cex=.6, boxwex=.05,
    col='pink', border='darkviolet', xaxt='n', yaxt='n'
  )

  legend(
    x=4*m/5, y=.8, legend=c("ECDF", "CDF"), bg="#fcfcfc",
    col=c("darkviolet", "green2"), lty="solid", lwd=3
  )

  dev.off()

  system(paste('display', fname))
}

doit <- function (numero) {
  x <- dat[dat$N == numero,]$len-1
  gf <- vcd::goodfit(x, type="nbinomial", par=list(size=1, prob=p.sucesso))
  summary(gf)
  #plot(gf)
}
