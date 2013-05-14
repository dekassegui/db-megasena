-- cálculo do percentual de concursos acumulados entre os que ocorreram
-- 2+ dezenas sequenciadas
SELECT soma, total, round(100*cast(soma AS REAL)/total,3)||'%'
FROM (
  SELECT sum(acumulado) AS soma, count(acumulado) AS total
  FROM concursos INNER JOIN (
    -- tabela dos concursos com ocorrência de 2+ dezenas sequenciadas
    SELECT concurso AS n
    FROM dezenas_juntadas
    WHERE mask60(dezenas) LIKE '%11%'
  ) ON n == concurso
);
