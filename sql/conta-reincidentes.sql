CREATE TEMP TABLE reincidentes AS
  SELECT
    concursos.concurso,
    (SELECT dezenas FROM dezenas_juntadas
     WHERE concurso == concursos.concurso)
     & (SELECT dezenas FROM dezenas_juntadas
        WHERE concurso == concursos.concurso-1) AS R
  FROM
    concursos
  WHERE
    (concursos.concurso > 1) AND (R != 0);

CREATE TEMP VIEW v AS
  SELECT concurso, MASK60(R) AS mask FROM reincidentes;

CREATE TEMP VIEW w AS
  SELECT concurso, LENGTH(REPLACE(mask, '0', '')) AS len FROM v;

SELECT len, COUNT(*) FROM w GROUP BY len;
