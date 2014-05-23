-- tabela de sumários dos concursos do ano corrente
SELECT
  concurso,
  data_sorteio,
  " { " || GROUP_CONCAT(ZEROPAD(dezena,2)," ") || " } ",  -- dezenas sorteadas
  CASE acumulado WHEN 1 THEN valor_acumulado END          -- valor acumulado
FROM
  (SELECT DATE("now","start of year") AS inicio_do_ano),  -- início do ano
  concursos NATURAL JOIN dezenas_sorteadas
WHERE
--  data_sorteio >= inicio_do_ano
  concurso >= (select max(concurso)-20 from concursos)
GROUP BY
  concurso;
