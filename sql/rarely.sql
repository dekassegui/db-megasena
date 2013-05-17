-- lista dinâmica das dezenas com frequência abaixo do esperado e latência acima
-- do esperado ordenadas em ordem decrescente pelo índice de força relativa na
-- aposta
SELECT
  zeropad(dezena,2) AS decena,
  frequencia,
  latencia,
  (latencia + M) * 100 / frequencia / frequencia AS ifrap
FROM
  (SELECT MAX(concurso) * 6 / 60 AS E FROM concursos),  -- frequência esperada de qualquer dezena
  (SELECT 1 + 60/6 AS L),                               -- 1 + latência esperada de qualquer dezena
  (SELECT MAX(latencia) / 2.0 AS M FROM info_dezenas),  -- limite inferior da latência no cálculo de ifrap
  info_dezenas
WHERE (frequencia <= E) AND (latencia >= L)
ORDER BY ifrap DESC;
