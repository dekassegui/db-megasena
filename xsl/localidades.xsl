<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text" encoding="utf-8" indent="no" omit-xml-declaration="yes"/>

  <!-- Listagem das localidades de ganhadores da megasena por concurso. -->

  <!-- número do concurso objeto da pesquisa -->
  <xsl:param name="CONCURSO"/>

  <!-- separador de campos dos registros -->
  <xsl:param name="FIELDS_SEPARATOR"/>

  <!-- separador de registros -->
  <xsl:param name="RECORDS_SEPARATOR"/>

  <xsl:template name="LOCALIDADES_GANHADORES_SENA" match="/">

    <!-- loop de iteração única somente para obter o contexto do elemento -->
    <xsl:for-each select="//table/tr[count(td)=21][td[1]=$CONCURSO]">

      <xsl:variable name="numero_ganhadores" select="td[10]"/>

      <xsl:if test="$numero_ganhadores &gt; 0">

        <xsl:variable name="offset" select="1+count(preceding-sibling::*)"/>
        <xsl:variable name="upper" select="$offset+$numero_ganhadores"/>

        <xsl:value-of select="td[11]"/><xsl:value-of select="$FIELDS_SEPARATOR"/><xsl:value-of select="td[12]"/>

        <xsl:for-each select="//table/tr[position()&gt;$offset and position()&lt;$upper]">
          <xsl:choose>
            <xsl:when test="count(td)=2">
              <xsl:value-of select="$RECORDS_SEPARATOR"/><xsl:value-of select="td[1]"/><xsl:value-of select="$FIELDS_SEPARATOR"/><xsl:value-of select="td[2]"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$RECORDS_SEPARATOR"/><xsl:value-of select="$FIELDS_SEPARATOR"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>

      </xsl:if>

    </xsl:for-each>

  </xsl:template>

</xsl:stylesheet>
