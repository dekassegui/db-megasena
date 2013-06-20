#!/usr/bin/Rscript

#x11(display=":0.0", family='serif', 12.7, 6, 9)

png(filename='chi-one.png', width=1000, height=558, family='DejaVu Serif', pointsize=11)

xmax = qchisq(0.995, 1)

curve(
  dchisq(x, 1),
  xlim=c(0, xmax),
  ylim=c(0, 1),
  bty='n',          # renderiza apenas eixos
  col='navy',
  main = list(
    "Distribuição χ² (df=1)",
    cex=1.75,   # font size scale
    font=1,     # italic
    col='navy'  # foreground color
  ),
  ylab = list(''),
  xlab = list('')
)

values = c(0.5, 0.9, 0.95)
quartis = 1:3
for (j in 1:3) quartis[j] = qchisq(values[j], 1)
line_type='solid'
cores = c('green', 'dodgerblue', 'tomato')
abline(v=quartis, lty=line_type, col=cores)

gd <- par()$usr   # coordenadas dos extremos do device
legend(
  11*gd[2]/15, 4*gd[4]/5,
  bty='n',
  text.font=1,
  text.col='navy',
  cex=1.25,
  lty=line_type,
  col=cores,
  legend=c(sprintf('%.3f (%5.2f%%)', quartis, (1-values)*100))
)

# renderiza hachuras num intervalo arbitrário
do_hatch <- function(from, to, color) {
  inc = 0.015
  while (from < to) {
    segments(from, 0, from, dchisq(from, 1), col=color, lty='solid', lwd=1)
    from = from + inc
  }
}

#do_hatch(quartis[1], quartis[2], cores[1])
#do_hatch(quartis[2], quartis[3], cores[2])
do_hatch(quartis[3], xmax, cores[3])

dev.off()
