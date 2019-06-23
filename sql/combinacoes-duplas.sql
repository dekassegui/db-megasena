-- tabela dos possíveis números da megassena
create temp table numeros as
  with me as (
    select 1 as n union all select n+1 from me where n < 60
  ) select n from me;

-- tabela das possíveis duplas da megasena
create temp table duplas as
  select /* a.n, b.n, */ (1 << a.n-1) | (1 << b.n-1) as dupla
  from numeros as a inner join numeros as b on a.n < b.n;

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
