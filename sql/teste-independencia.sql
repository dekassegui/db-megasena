-- teste de independência chi-quadrado p/variáveis "sequênciado X acumulado"
-- ao nível de significância 5%
CREATE TEMP TABLE t2 AS
--  SELECT concurso AS N FROM concursos WHERE (N >= 2) AND (
--    (SELECT dezenas FROM dezenas_juntadas WHERE concurso == N)
--    & (SELECT dezenas FROM dezenas_juntadas WHERE concurso == N-1));
  SELECT concurso FROM dezenas_juntadas WHERE mask60(dezenas) LIKE '%11%';
SELECT round(chi,3), (chi >= 3.841)
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
