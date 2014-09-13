<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text" encoding="utf-8" indent="no" omit-xml-declaration="yes"/>

  <!-- número de ordem do primeiro registro da lista -->
  <xsl:param name="OFFSET" select="1"/>

  <!-- separador de campos dos registros -->
  <xsl:param name="SEPARATOR"/>

  <!-- monta a lista de registros que serão importados pelo SQLite -->
  <xsl:template name="LIST_BUILDER" match="/">
    <xsl:for-each select="//table/tr[count(td)=21][position() &gt;= $OFFSET]">
<xsl:value-of select="td[1]"/><xsl:value-of select="$SEPARATOR"/><xsl:value-of select="substring(td[2],7)"/>-<xsl:value-of select="substring(td[2],4,2)"/>-<xsl:value-of select="substring(td[2],1,2)"/><xsl:value-of select="$SEPARATOR"/><xsl:for-each select="td[position() &gt; 2 and position() &lt; 11]"><xsl:value-of select="."/><xsl:value-of select="$SEPARATOR"/></xsl:for-each><xsl:choose><xsl:when test="string-length(td[11]) &gt; 0"><xsl:value-of select="td[11]"/></xsl:when><xsl:otherwise>NULL</xsl:otherwise></xsl:choose><xsl:value-of select="$SEPARATOR"/><xsl:choose><xsl:when test="string-length(td[12]) &gt; 0"><xsl:value-of select="td[12]"/></xsl:when><xsl:otherwise>NULL</xsl:otherwise></xsl:choose><xsl:value-of select="$SEPARATOR"/><xsl:for-each select="td[position() &gt; 12 and position() &lt; 21]"><xsl:value-of select="."/><xsl:value-of select="$SEPARATOR"/></xsl:for-each><xsl:value-of select="td[21]"/><xsl:text>&#xA;</xsl:text>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
