#!/bin/bash
#
# listagem de todas as combinações de três dezenas que ocorreram ao longo do
# tempo, agrupadas por frequência e ordenadas em ordem crescente de número de
# ocorrências
#
datafile="/tmp/ternos.dat"
#
[[ -e $datafile ]] || ./scripts/60itens3a3.sh > $datafile
#
sqlite3 -init sqlite/onload megasena.sqlite <<EOT
--
CREATE TEMP TABLE ternos (d1 INT, d2 INT, d3 INT, terno INT);
.import $datafile ternos
--
CREATE TEMP TABLE frequencias_ternos AS
  SELECT
    "{ " || zeropad(d1,2) || ' ' || zeropad(d2,2) || ' ' || zeropad(d3,2) || " }" AS trio,
    count(terno) AS frequencia
  FROM
    dezenas_juntadas INNER JOIN ternos ON (dezenas & terno) == terno
  GROUP BY terno
  ORDER BY terno;
--
SELECT count(trio) || " ternos distintos ocorreram", frequencia || " vezes."
FROM frequencias_ternos
GROUP BY frequencia;
--
EOT
