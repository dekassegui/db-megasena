-- obtêm as 50 últimas incidências das dezenas sorteadas no último concurso
SELECT zeropad(dezena,2), group_concat(bitstatus(dezenas,dezena-1),'') AS mask
FROM (
  SELECT DISTINCT dezena FROM dezenas_sorteadas
), (
  SELECT dezenas
  FROM dezenas_juntadas
  WHERE concurso >= (SELECT max(concurso)-50+1 FROM concursos)
)
GROUP BY dezena
HAVING mask LIKE '%1';
