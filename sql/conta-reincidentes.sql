-- tabela dos números sorteados em concursos consecutivos
create temp view reincidentes as
  select concurso, dezena from dezenas_sorteadas as s
  where (
    select 1 from dezenas_sorteadas
    where concurso == s.concurso-1 and dezena == s.dezena);

-- contagem de concursos pela quantidade de números sorteados em concursos
-- consecutivos
select n, count(concurso) from (
  -- tabela da quantidade de números sorteados em concursos consecutivos
  select concurso, count(dezena) as n from reincidentes group by concurso
) group by n;