-- tabela das possíveis duplas da megasena
CREATE TEMP TABLE duplas AS
  SELECT
    ZEROPAD(a,2) AS dezena1, ZEROPAD(b,2) AS dezena2,
    ((1 << a-1) | (1 << b-1)) AS dupla
  FROM
    (SELECT DISTINCT dezena AS a FROM dezenas_sorteadas),
    (SELECT DISTINCT dezena AS b FROM dezenas_sorteadas)
  WHERE
    a < b
  ORDER BY a, b;

-- frequências das duplas na série histórica dos concursos
CREATE TEMP TABLE frequencias_duplas AS
  SELECT dupla, count(concurso) AS frequencia
  FROM
    dezenas_juntadas INNER JOIN duplas ON (dezenas & dupla) == dupla
  GROUP BY dupla
  ORDER BY frequencia DESC;

-- concursos em que ocorreram a máxima dupla dentre as duplas com a máxima
-- frequência
SELECT ZEROPAD(concurso,4), "{ " || GROUP_CONCAT(ZEROPAD(dezena,2)," ") || " }" FROM
  dezenas_sorteadas natural JOIN dezenas_juntadas,
  (
   SELECT MAX(dupla) AS max_dupla
   FROM frequencias_duplas
   WHERE frequencia == (SELECT MAX(frequencia) FROM frequencias_duplas)
  )
WHERE (dezenas & max_dupla) == max_dupla
GROUP BY concurso;
