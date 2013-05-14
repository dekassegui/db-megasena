-- frequências de sequências de três dezenas consecutivas no mesmo concurso
select frequencia, group_concat(terno," ")
from (
  SELECT
    zeropad(dezena,2) || '-' || zeropad(dezena+1,2) || '-' || zeropad(dezena+2,2) AS terno,
    count(concurso) AS frequencia
  FROM dezenas_juntadas, (
    SELECT dezena, ((1 << dezena-1) | (1 << dezena) | (1 << dezena+1)) AS mask
    FROM (
      SELECT DISTINCT dezena FROM dezenas_sorteadas WHERE dezena <= 58
    )
  )
  WHERE (dezenas & mask) == mask
  GROUP BY dezena
)
group by frequencia;
