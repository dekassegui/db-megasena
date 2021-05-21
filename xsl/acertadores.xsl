<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text" encoding="utf-8" indent="no" omit-xml-declaration="yes"/>

  <!-- separador de campos dos registros -->
  <xsl:param name="SEPARATOR"/>

  <!-- Lista CONCURSO|CIDADE|UF de apostas acertadoras da Mega-Sena. -->

  <xsl:template name="LISTA_DADOS_GANHADORES_MEGA" match="/">

    <xsl:for-each select="//tbody/tr[count(td)>2][position()>=$OFFSET][td[9]>0]">
      <xsl:for-each select="td[16]/table/tr">
        <xsl:value-of select="ancestor::tr[count(td)>2]/td[1]"/>
        <xsl:value-of select="$SEPARATOR"/>
        <xsl:choose>
          <xsl:when test="string-length(td[1])>0">
            <xsl:value-of select="td[1]"/>
          </xsl:when>
          <xsl:otherwise>NULL</xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="$SEPARATOR"/>
        <xsl:choose>
          <xsl:when test="string-length(td[2])>0">
            <xsl:value-of select="td[2]"/>
          </xsl:when>
          <xsl:otherwise>NULL</xsl:otherwise>
        </xsl:choose>
        <xsl:text>&#xA;</xsl:text>
      </xsl:for-each>
    </xsl:for-each>

  </xsl:template>

</xsl:stylesheet>
