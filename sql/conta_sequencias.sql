-- contagem de concursos com ocorrências de sequências de dezenas consecutivas

-- máscaras de todos os concursos onde ocorreram 2+ dezenas consecutivas
CREATE TEMP TABLE t2 AS
  SELECT mask60(dezenas) AS mask FROM dezenas_juntadas WHERE mask LIKE "%11%";

-- 2+ dezenas consecutivas
SELECT '2+ ' || count(*) FROM t2;

-- 3+ dezenas consecutivas
CREATE TEMP TABLE t3 AS
  SELECT mask FROM t2 WHERE mask LIKE "%111%";
SELECT '3+ ' || count(*) FROM t3;

-- 4+ dezenas consecutivas
CREATE TEMP TABLE t4 AS
  SELECT mask FROM t3 WHERE mask LIKE "%1111%";
SELECT '4+ ' || count(*) FROM t4;
