SELECT
  concurso,
  data_sorteio,
  " { " || GROUP_CONCAT(ZEROPAD(dezena,2)," ") || " } ",
  CASE acumulado WHEN 1 THEN valor_acumulado END
FROM
  (SELECT DATE("now","start of year") AS inicio_do_ano),
  concursos NATURAL JOIN dezenas_sorteadas
WHERE
  data_sorteio >= inicio_do_ano
GROUP BY
  concurso;
