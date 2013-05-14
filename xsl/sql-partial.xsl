<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="text" encoding="utf-8" indent="no" omit-xml-declaration="yes"/>

  <xsl:param name="OFFSET" select="1"/>

  <xsl:include href="sql-insert.xsl"/>

  <xsl:template match="/">
BEGIN TRANSACTION;
PRAGMA foreign_keys = ON;

    <xsl:call-template name="SQL_INSERT">
      <xsl:with-param name="rows_offset" select="$OFFSET"/>
    </xsl:call-template>

COMMIT;
  </xsl:template>

</xsl:stylesheet>
