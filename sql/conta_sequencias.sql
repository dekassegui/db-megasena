-- contagem de concursos com ocorrências de sequências de dezenas
create temp view t2 as select mask60(dezenas) as mask from dezenas_juntadas where mask like "%11%";
-- 2+ dezenas consecutivas
select '2+ ' || count(*) as c2 from t2;
-- 3+ dezenas consecutivas
create temp view t3 as select mask from t2 where mask like "%111%";
select '3+ ' || count(*) as c3 from t3;
-- 4+ dezenas consecutivas
create temp view t4 as select mask from t3 where mask like "%1111%";
select '4+ ' || count(*) as c4 from t4;
