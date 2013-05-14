SELECT zeropad(dezena,2) AS decena, frequencia, latencia,
  (latencia + M) * 100.0 / frequencia / frequencia AS ifrap
FROM (SELECT MAX(concurso)*6/60 AS E FROM concursos),  -- esperança
  (SELECT MAX(latencia) / 2.0 AS M FROM info_dezenas), -- 
  info_dezenas
WHERE (frequencia <= E) AND (latencia >= 11)
ORDER BY ifrap DESC;
