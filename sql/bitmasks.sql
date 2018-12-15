-- listagem das "bitmasks" dos números sorteados em cada concurso
drop view if exists bitmasks;
create view bitmasks as
  select concurso, (
    with recursive bits (n, r) as (
      values (-1, "")
      union all
      select n+1, (dezenas >> n+1 & 1) || r from bits where n < 60
    ) select r from bits where n = 59
  ) as mask from dezenas_juntadas;
