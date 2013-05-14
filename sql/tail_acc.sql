select (select max(concurso) from concursos) - (select max(concurso) from concursos where not acumulado);
