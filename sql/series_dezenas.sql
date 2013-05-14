-- tabela de incidência das dezenas ao longo do tempo
SELECT dezena, group_concat((dezenas >> dezena-1) & 1, "") AS serie
FROM (SELECT DISTINCT dezena FROM dezenas_sorteadas), dezenas_juntadas
GROUP BY dezena;
