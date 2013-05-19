-- tabela dos possíveis ternos da megasena
CREATE TEMP TABLE ternos AS
  SELECT
    zeropad(a,2) as dezena1, zeropad(b,2) as dezena2, zeropad(c,2) as dezena3,
    ((1 << a-1) | (1 << b-1) | (1 << c-1)) AS terno
  FROM
    (SELECT DISTINCT dezena AS a FROM dezenas_sorteadas),
    (SELECT DISTINCT dezena AS b FROM dezenas_sorteadas),
    (SELECT DISTINCT dezena AS c FROM dezenas_sorteadas)
  WHERE
    a < b AND b < c
  ORDER BY a, b, c;

-- frequências dos ternos na série histórica dos concursos
CREATE TEMP TABLE frequencias_ternos AS
  SELECT terno, count(concurso) AS frequencia
  FROM
    dezenas_juntadas INNER JOIN ternos ON (dezenas & terno) == terno
  GROUP BY terno
  ORDER BY frequencia DESC;

-- concursos em que ocorreram o máximo terno entre os ternos com a máxima
-- frequência
SELECT zeropad(concurso,4), "{ " || group_concat(zeropad(dezena,2)," ") || " }" FROM
  dezenas_sorteadas natural JOIN dezenas_juntadas,
  (
   SELECT max(terno) as max_terno
   FROM frequencias_ternos
   WHERE frequencia == (SELECT MAX(frequencia) FROM frequencias_ternos)
  )
WHERE (dezenas & max_terno) == max_terno
GROUP BY concurso;
