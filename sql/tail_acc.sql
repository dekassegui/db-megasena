-- cálculo do número de concursos acumulados até o mais recente inclusive
SELECT (SELECT MAX(concurso) FROM concursos) - (SELECT MAX(concurso) FROM concursos WHERE NOT acumulado);
