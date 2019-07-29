-- TABELA DOS NÚMEROS DA MEGASENA, RESPECTIVAS MASCARAS DE INCIDÊNCIAS E MÁXIMAS
-- LATÊNCIAS AO LONGO DO TEMPO
--
-- AVISO: CÁLCULO DAS LATÊNCIA É DEMORADO SE O NÚMERO DE CONCURSOS FOR GRANDE.
drop table if exists t;
create temp table t as
  with cte (n, mask, latencia) as (
    select 1, null, null union all select n+1, null, null from cte where n < 60
  ) select n, mask, latencia from cte;
.print "> construindo mascaras"
update t set mask=(
  select group_concat(dezenas & numero == numero, "")
  from ( select 1 << n-1 as numero ),
    ( select dezenas from dezenas_juntadas where concurso > 1665 )
);
.print "> calculando latências máximas"
update t set latencia=(
  with me (len) as ( select length(mask) ),
    etc (p, size) as (
      with bag (q) as (
        with this (q, isSeparator) as (
          values (0, 1) --> PSEUDO SEPARATOR IN FRONT OF SOURCE STRING
          union all
          select q+1, substr(mask, q+1, 1) == "1" --> SEPARATOR
          from me, this where q+1 <= len
        ) select q from this where isSeparator  --> POSITIONS OF ALL SEPARATORS
        union all
        select len+1 from me --> PSEUDO SEPARATOR AT BOTTOM OF SOURCE STRING
      ) select p, --> POSITION OF NEAREST RIGHT SEPARATOR
          ( select min(q) from bag where q > p )-1-p as size
        from ( -- POSITIONS OF SEPARATORS PRECEDING NON SEPARATORS
          select q as p from bag where not p+1 in bag
        ) where size
    ) select max(size) from etc
);
