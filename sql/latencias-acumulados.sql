-- TABELA DOS NÚMEROS SERIAIS DOS CONCURSOS QUE INICIAM SEQUÊNCIAS DE UM OU MAIS -- CONCURSOS SEM ACERTADORES DA SENA E RESPECTIVAS LATÊNCIAS (TAMANHOS DAS
-- SEQUÊNCIAS) AO LONGO DO TEMPO
with me as (
  select count(1) as len, group_concat(acumulado,"") as mask from concursos
), bag (q) as (
  with this (q, isSeparator) as (
    values (0, 1) --> PSEUDO SEPARADOR À FRENTE DA STRING
    union all
    select q+1, substr(mask, q+1, 1) == "0" --> CHAR É SEPARADOR?
    from me, this where q+1 <= len
  ) select q from this where isSeparator  --> POSIÇÔES DE TODOS SEPARADORES
  union all
  select len+1 from me --> PSEUDO SEPARADOR AO FINAL DA STRING
) select p+1 as concurso, --> INÍCIO DA SEQUÊNCIA
    ( select min(q) from bag where q > p )-1-p as latencia
  from ( -- POSIÇÕES DE SEPARADORES PRECEDENDO "NÃO SEPARADORES"
    select q as p from bag where not p+1 in bag
  ) where latencia;
