-- frequências de sequências de duas dezenas consecutivas no mesmo concurso
SELECT zeropad(frequencia,2), group_concat(dupla, '  ')
FROM (
  SELECT zeropad(dezena,2)||'-'||zeropad(dezena+1,2) AS dupla, count(concurso) AS frequencia
  FROM dezenas_juntadas, (
    SELECT dezena, ((1 << dezena-1) | (1 << dezena)) AS mask
    FROM (
      SELECT DISTINCT dezena FROM dezenas_sorteadas WHERE dezena < 60
    )
  )
  WHERE (dezenas & mask) == mask
  GROUP BY dezena
  --ORDER BY frequencia
)
GROUP BY frequencia
ORDER BY frequencia DESC;
