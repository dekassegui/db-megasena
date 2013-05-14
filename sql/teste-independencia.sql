-- tabela dos concursos em que ocorreram ao menos duas dezenas sequenciadas
CREATE TEMP TABLE t2 AS
  SELECT concurso FROM dezenas_juntadas WHERE mask60(dezenas) LIKE '%11%';

-- teste chi-quadrado para verificar independência entre eventos "concurso ter
-- dezenas sequenciadas" e "concurso não ter ganhadores" ou seja: testar se
-- ocorrências de dezenas sequenciadas influem na ausência de ganhadores
SELECT
  round(chi,3),   -- estatística do teste
  (chi >= 3.841)  -- comparação com valor crítico para nível de significância 5%
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
