DROP TABLE IF EXISTS reincidentes;
-- tabela dos números reincidentes em concursos consecutivos
CREATE TEMP TABLE reincidentes AS
  SELECT concurso, numero, (
      WITH RECURSIVE bits (n, s) AS (
        SELECT -1, ""
        UNION ALL
        SELECT n+1, (numero >> n+1 & 1) || s
        FROM bits WHERE n < 60
      ) SELECT s FROM bits WHERE n == 59
    ) AS mask
  FROM (
    SELECT a.concurso, (a.dezenas & b.dezenas) AS numero
    FROM dezenas_juntadas AS a JOIN dezenas_juntadas AS b
      ON (a.concurso-1 == b.concurso) AND (numero > 0)
  );
