<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text" encoding="utf-8" indent="no" omit-xml-declaration="yes"/>

  <!-- número de ordem do primeiro registro da lista -->
  <xsl:param name="OFFSET" select="1"/>

  <!-- separador de campos dos registros -->
  <xsl:param name="SEPARATOR"/>

  <!-- monta a lista de registros que serão importados pelo SQLite -->
  <xsl:template name="LIST_BUILDER" match="/">
    <xsl:for-each select="//tbody/tr[count(td)=22][position() &gt;= $OFFSET]">
      <xsl:value-of select="td[1]"/><xsl:value-of select="$SEPARATOR"/>
      <!-- skip 2nd columnn -->
      <xsl:value-of select="substring(td[3],7)"/><xsl:text>-</xsl:text>
      <xsl:value-of select="substring(td[3],4,2)"/><xsl:text>-</xsl:text>
      <xsl:value-of select="substring(td[3],1,2)"/>
      <xsl:value-of select="$SEPARATOR"/>
      <xsl:for-each select="td[position() &gt; 3 and position() &lt; 16]">
        <xsl:value-of select="."/><xsl:value-of select="$SEPARATOR"/>
      </xsl:for-each>
      <!-- skip 16th column -->
      <xsl:for-each select="td[position() &gt; 16 and position() &lt; 20]">
        <xsl:value-of select="."/><xsl:value-of select="$SEPARATOR"/>
      </xsl:for-each>
      <xsl:choose>
        <xsl:when test="td[20]='SIM'">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
      <!-- skip 21st column -->
      <!-- skip 22nd column -->
      <xsl:text>&#xA;</xsl:text>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
