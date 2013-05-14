-- SELECT concurso
-- FROM dezenas_juntadas AS x
-- WHERE (concurso >= 2) AND
-- (SELECT dezenas FROM dezenas_juntadas WHERE concurso == x.concurso) &
-- (SELECT dezenas FROM dezenas_juntadas WHERE concurso == x.concurso-1);

-- cria tabela dos números de concursos que contém dezenas reincidentes
-- separadas por conveniência na coluna dezenas
CREATE TEMP TABLE IF NOT EXISTS reincidentes AS
SELECT
  concurso,
  (SELECT dezenas FROM dezenas_juntadas WHERE concurso == concursos.concurso) & (SELECT dezenas FROM dezenas_juntadas WHERE concurso == concursos.concurso-1) AS dezenas
FROM
  concursos
WHERE
  (concurso >= 2) AND dezenas;

-- conta número de registros na tabela dezenas reincidentes
SELECT count(concurso) FROM reincidentes;

-- lista dezenas reincidentes agrupadas por frequência
SELECT
  frequencia, '{ ' || group_concat(decena, ' ') || ' }'
FROM (
  SELECT
    zeropad(dezena,2) AS decena,
    sum((dezenas >> dezena-1) & 1) AS frequencia
  FROM (
      SELECT DISTINCT dezena FROM dezenas_sorteadas
    ), reincidentes
  GROUP BY dezena  --order by frequencia
)
GROUP BY frequencia;

CREATE TEMP VIEW IF NOT EXISTS t2 AS SELECT concurso FROM reincidentes;

-- teste de independência chi-quadrado p/variáveis "acumulado × reincidente"
-- ao nível de significância 5%
SELECT 'acumulado × reincidente', round(chi,3), (chi >= 3.841)
FROM (
  SELECT power(fa-ea,2)/ea + power(fb-eb,2)/eb + power(fc-ec,2)/ec + power(fd-ed,2)/ed AS chi
  FROM (
    SELECT
      (fa+fc)*(fa+fb)/total AS ea,
      (fb+fd)*(fa+fb)/total AS eb,
      (fa+fc)*(fc+fd)/total AS ec,
      (fb+fd)*(fc+fd)/total AS ed,
      fa, fb, fc, fd
    FROM (
      SELECT count(*) AS fa FROM concursos WHERE acumulado and concurso in t2
    ), (
      SELECT count(*) AS fb FROM concursos WHERE acumulado and not concurso in t2
    ), (
      SELECT count(*) AS fc FROM concursos WHERE not acumulado and concurso in t2
    ), (
      SELECT count(*) AS fd FROM concursos WHERE not acumulado and not concurso in
        t2
    ), (
      SELECT cast(count(*) AS real) AS total FROM concursos
    )
  )
);
