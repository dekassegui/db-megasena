-- monta os respectivos rankings das frequências e latências
SELECT
  *, rownum(0) AS rank_latencia
FROM (
  SELECT
    *
  FROM (
    SELECT
      *, rownum(0) AS rank_frequencia
    FROM (
      SELECT * FROM info_dezenas ORDER BY frequencia DESC
    )
    ORDER BY dezena
  )
  ORDER BY latencia DESC
)
ORDER BY dezena;
