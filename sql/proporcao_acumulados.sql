-- estimativa da proporção de concursos acumulados e desvio padrão
-- SELECT n, m, round(p*100,3), round(d*100,3)
-- FROM (
  SELECT
    n,
    m,
    p,                          -- estimativa da proporção
    power(p*(1-p)/n, .5) AS d   -- estimativa do desvio padrão da proporção
  FROM (
    SELECT
      m, n,
      cast(m AS real)/n AS p    -- cálculo da estimativa da proporção
    FROM (
      SELECT
        sum(acumulado) AS m,    -- número de concursos acumulados
        count(acumulado) AS n   -- número de concursos
      FROM concursos
    )
  )
-- )
;
