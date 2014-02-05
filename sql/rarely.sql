-- lista dinâmica das números com frequência abaixo do esperado e latência acima
-- do esperado, ordenados em ordem decrescente pelo índice de força relativa na
-- aposta
SELECT
  zeropad(dezena,2) AS decena,
  frequencia,
  latencia,
  (latencia + M / 2.0) * 100 / frequencia / frequencia AS ifrap
FROM
  (SELECT MAX(concurso) * 6 / 60.0 AS E FROM concursos),  -- frequência esperada de qualquer número
  (SELECT 60 / 6 AS L),                               -- latência esperada de qualquer número
  (SELECT MAX(latencia) AS M FROM info_dezenas),  -- máximo valor da latência para cálculo do ifrap
  info_dezenas
WHERE (frequencia < E) AND (latencia >= L)
ORDER BY ifrap DESC;
