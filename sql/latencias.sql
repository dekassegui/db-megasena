DROP VIEW IF EXISTS latencias;
CREATE TEMP VIEW latencias AS
  WITH ME (numero, concurso) AS (
    VALUES(0, NULL)
    UNION ALL
    SELECT numero+1, (
      SELECT concurso FROM dezenas_sorteadas
        WHERE dezena == numero+1 ORDER BY concurso DESC LIMIT 1
    ) FROM ME WHERE numero < 60
  ) SELECT numero, concurso, recente-concurso AS latencia FROM (
      SELECT concurso AS recente FROM ME ORDER BY concurso DESC LIMIT 1
    ) CROSS JOIN ME WHERE numero > 0;
