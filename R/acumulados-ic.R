#!/usr/bin/Rscript --no-init-file
#
library(RSQLite)
con <- dbConnect(SQLite(), "megasena.sqlite")
query = "SELECT acumulado FROM concursos"
datum <- dbGetQuery(con, query)
dbDisconnect(con)
#
cat("-- Teste Exato do Percentual Amostral --\n\n")
#
acc = tabulate(datum$acumulado)
N = length(datum$acumulado)
cat("Dados:")
cat(sprintf("\n%20s %d", "#sucessos =", acc))
cat(sprintf("\n%20s %d", "#tentativas =", N))
#
p.sample = acc / N
cat(sprintf("\n\n%20s %f\n", "p-sample =", p.sample))
#
args = commandArgs(TRUE)
p.null = ifelse(length(args) > 0, as.numeric(args[1]),
  round(p.sample * 100) / 100
)
cat(sprintf("\nHØ: percentual de sucessos é %s.\n", format(p.null, drop0trailing=T)))
# normalização | Z ~ N(0,1)
z = (p.sample - p.null) / sqrt(p.null * (1 - p.null) / N)
cat(sprintf("\n%20s %f\n", "z ~ N(0,1) =", z))

alfa = 0.05   # nível de significância

# teste via intervalo de confiança
#z.meio.alfa = qnorm(1 - alfa/2)
#cat(sprintf("\n\tα = %.0f%% -> IC: [-%.3f ; %2$.3f]\n", alfa*100, z.meio.alfa))
#status = (abs(z) <= z.meio.alfa)

# teste via p-value
p.value = 2 * (1 - pnorm(abs(z)))
cat(sprintf("\n%20s %f", "p-value =", p.value))
cat(sprintf("\n%20s %s", "alfa =", format(alfa, drop0trailing=T)))

status = (p.value > alfa)
#
cat(sprintf("\n\nConclusão: %s HØ ao nível de significância de %s%%.\n",
  ifelse(status, "Não rejeitamos", "Rejeitamos"),
  format(100*alfa, drop0trailing=T)))
