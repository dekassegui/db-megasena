<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text" encoding="utf-8" indent="no" omit-xml-declaration="yes"/>

  <!-- separador de campos dos registros -->
  <xsl:param name="SEPARATOR"/>

  <!-- Lista concurso/cidade/estado de ganhadores da megasena. -->

  <xsl:template name="LISTA_DADOS_GANHADORES_SENA" match="/">

    <!-- percorre a lista de registros de concursos onde houve 1+ ganhadores -->
    <xsl:for-each select="//table/tr[td[10]>0]">

      <xsl:variable name="concurso" select="td[1]"/>
      <xsl:variable name="numero_ganhadores" select="td[10]"/>
      <xsl:variable name="offset" select="1+count(preceding-sibling::*)"/>
      <xsl:variable name="upper" select="$offset+$numero_ganhadores"/>

      <!-- imprime dados do primeiro ganhador -->
      <xsl:value-of select="$concurso"/><xsl:value-of select="$SEPARATOR"/><xsl:value-of select="td[11]"/><xsl:value-of select="$SEPARATOR"/><xsl:value-of select="td[12]"/><xsl:text>&#xA;</xsl:text>

      <!-- imprime dados dos demais ganhadores se houverem -->
      <xsl:for-each select="//table/tr[position()&gt;$offset and position()&lt;$upper]">
        <xsl:value-of select="$concurso"/><xsl:value-of select="$SEPARATOR"/><xsl:value-of select="td[1]"/><xsl:value-of select="$SEPARATOR"/><xsl:value-of select="td[2]"/><xsl:text>&#xA;</xsl:text>
      </xsl:for-each>

    </xsl:for-each>

  </xsl:template>

</xsl:stylesheet>
