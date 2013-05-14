-- CALCULA ÍNDICE DE FORÇA RELATIVA DAS DEZENAS
SELECT
  zeropad(dezena,2),
  frequencia,
  zeropad(latencia,2),
  (latencia + M) * 100.0 / frequencia / frequencia AS ifrap
FROM
  (SELECT MAX(latencia) / 2.0 AS M FROM info_dezenas),
  info_dezenas
ORDER BY ifrap;
