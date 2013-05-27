#!/bin/bash
#
# listagem de todas as combinações de duas dezenas que ocorreram ao longo do
# tempo, agrupadas por frequência e ordenadas em ordem crescente de número de
# ocorrências
#
datafile="/tmp/duplas.dat"
#
[[ -e $datafile ]] || ./scripts/60itens2a2.sh > $datafile
#
sqlite3 -init sqlite/onload megasena.sqlite <<EOT
--
CREATE TEMP TABLE duplas (d1 INT, d2 INT, dupla INT);
.import $datafile duplas
--
CREATE TEMP TABLE frequencias_duplas AS
  SELECT
    "{ " || zeropad(d1,2) || ' ' || zeropad(d2,2) || " }" AS par,
    count(dupla) AS frequencia
  FROM
    dezenas_juntadas INNER JOIN duplas ON (dezenas & dupla) == dupla
  GROUP BY dupla
  ORDER BY dupla;
--
SELECT count(par) || " duplas distintas ocorreram", frequencia || " vezes ==>", group_concat(par, "-")
FROM frequencias_duplas
GROUP BY frequencia;
--
EOT
