#!/usr/bin/Rscript

chi.df = 59

chi.density <- function(x) { dchisq(x, chi.df) }

chi.critical <- function(x) { qchisq(x, chi.df) }

chi.tail <- function(x) { pchisq(x, chi.df, lower.tail=FALSE) }

args = commandArgs(TRUE)
estatistica = as.numeric(args[1])
usingPNG = FALSE
if (is.na(estatistica)) {
  # renderização em ambiente interativo
  estatistica = chi.critical(0.5)
  X11(display=":0.0", family='serif', 12.7, 6, 9)
} else {
  # renderização em batch
  png(filename='img/chi-59.png', width=640, height=480,
      family='DejaVu Serif', pointsize=9)
  usingPNG = TRUE
}

opar=par(bg='white', fg='#333333')

curve(
  chi.density,
  xlim=c(0, 120),
  ylim=c(0, 0.04),
  bty='n',          # renderiza apenas eixos
  col='blue',
  main = list(
    sprintf("Distribuição χ² (gl=%d)", chi.df),
    cex=1.75,   # font size scale
    font=4      # bold + italic
  ),
  ylab = list(''),
  xlab = list('')
)

valores <- c(estatistica, chi.critical(0.95))
cores <- c('#00cc00', '#cc0000')

abline(v=valores, lty='solid', col=cores)

densidade = 25  # número de linhas por polegadas das hachuras

# renderiza hachuras no intervalo [from, to] e cor arbitrária
hatch <- function(from, to, color) {
  xx = from
  yy = 0
  while (from < to) {
    y = chi.density(from)
    if (y < 1E-4) break
    xx <- c(xx, from)
    yy <- c(yy, y)
    from = from + 0.35
  }
  if (length(xx) > 2) {
    xx <- c(xx, from)
    yy <- c(yy, 0)
    polygon(xx, yy, density=densidade, col=color, border=NA)
  }
}

hatch(valores[1], valores[2], cores[1])

gd <- par()$usr # coordenadas dos extremos da área de renderização da função

hatch(valores[2], gd[2], cores[2])

legend(
  2*gd[2]/3, 4*gd[4]/5,
  bty='n',
  cex=1.5,
  text.font=2,
  density=densidade,
  fill=cores,
  legend=c(sprintf("%.3f (%5.3f)", valores, chi.tail(valores)))
)

if (usingPNG) dev.off()
