-- tabela dos possíveis números da megassena
create temp table numeros as
  with me as (
    select 1 as n union all select n+1 from me where n < 60
  ) select n from me;

-- tabela dos possíveis ternos da megasena
create temp table ternos as
  select /* a.n, b.n, c.n, */ (1 << a.n-1) | (1 << b.n-1) | (1 << c.n-1) as terno
  from numeros as a inner join numeros as b on a.n < b.n inner join numeros as c on b.n < c.n;

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
