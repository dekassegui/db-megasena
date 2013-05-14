<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text" encoding="utf-8" indent="no" omit-xml-declaration="yes"/>

  <xsl:template name="SQL_INSERT" match="/">
    <xsl:param name="rows_offset"/>
    <xsl:for-each select="html/body/table/tr[position() &gt; $rows_offset]">
INSERT INTO concursos (concurso,data_sorteio,dezena1,dezena2,dezena3,dezena4,dezena5,dezena6,arrecadacao_total,ganhadores_sena,rateio_sena,ganhadores_quina,rateio_quina,ganhadores_quadra,rateio_quadra,acumulado,valor_acumulado,estimativa_premio,acumulada_mega_virada) VALUES (
      <xsl:value-of select="td[1]"/>,
      "<xsl:value-of select="substring(td[2],7)"/>-<xsl:value-of select="substring(td[2],4,2)"/>-<xsl:value-of select="substring(td[2],1,2)"/>",
      <xsl:for-each select="td[position() &gt; 2 and position() &lt; 9]">
        <xsl:value-of select="."/>,
      </xsl:for-each>
      <xsl:value-of select="translate(translate(td[9],'.',''),',','.')"/>,
      <xsl:value-of select="td[10]"/>,
      <xsl:value-of select="translate(translate(td[11],'.',''),',','.')"/>,
      <xsl:value-of select="td[12]"/>,
      <xsl:value-of select="translate(translate(td[13],'.',''),',','.')"/>,
      <xsl:value-of select="td[14]"/>,
      <xsl:value-of select="translate(translate(td[15],'.',''),',','.')"/>,
      <xsl:value-of select="number(td[16]='SIM')"/>,
      <xsl:value-of select="translate(translate(td[17],'.',''),',','.')"/>,
      <xsl:value-of select="translate(translate(td[18],'.',''),',','.')"/>,
      <xsl:value-of select="translate(translate(td[19],'.',''),',','.')"/>
);
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
