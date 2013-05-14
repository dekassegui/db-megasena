CREATE TEMP TABLE IF NOT EXISTS tempInfoTable AS
  SELECT
    dezena,
    count(dezena) AS frequencia,
    (m-max(concurso)) AS latencia
  FROM
    (
      SELECT max(concurso) AS m FROM concursos
    ), dezenas_sorteadas
  GROUP BY dezena;

SELECT
  dezena,
  frequencia,
  latencia,
  (latencia+L)*100.0/frequencia/frequencia AS ifrap
FROM (
  SELECT MAX(latencia)/2 AS L FROM tempInfoTable
), tempInfoTable;
