select soma, total, round(100*cast(soma as real)/total,3)||'%'
from (
  select sum(acumulado) as soma, count(acumulado) as total
  from concursos inner join (
    select concurso as n
    from dezenas_juntadas
    where mask60(dezenas) like '%11%'
  ) on n == concurso
);
