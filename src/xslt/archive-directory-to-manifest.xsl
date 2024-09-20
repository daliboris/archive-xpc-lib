<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:xs="http://www.w3.org/2001/XMLSchema"
 xmlns:math="http://www.w3.org/2005/xpath-functions/math"
 xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
 xmlns:c="http://www.w3.org/ns/xproc-step"
 exclude-result-prefixes="xs math xd"
 version="3.0">
 <xd:doc scope="stylesheet">
  <xd:desc>
   <xd:p><xd:b>Created on:</xd:b> May 11, 2023</xd:p>
   <xd:p><xd:b>Author:</xd:b> Boris</xd:p>
   <xd:p></xd:p>
  </xd:desc>
 </xd:doc>
 
 <xsl:output indent="yes" method="xml" />
 
 <xsl:param name="root" select="''" />
 <xsl:variable name="root-fix" select="if($root = '') 
  then $root 
  else 
   if (not(ends-with($root, '/'))) 
     then $root || '/' 
     else $root"/>
 
 <!--
 <c:archive>
  <c:entry name="a" href ="" comment="?" method = "?" level = "?" />
 </c:archive>
 -->
 
 <xsl:template match="/c:directory">
  <xsl:variable name="path" select="@xml:base"/>
  <xsl:variable name="dir-name" select="@name"/>
  <c:archive xmlns:c="http://www.w3.org/ns/xproc-step">
   <xsl:apply-templates mode="archive-entry">
    <xsl:with-param name="parent-base" select="$path" />
   </xsl:apply-templates>
  </c:archive>
 </xsl:template>
 
 <!--
  <xsl:with-param name="parent-base" select="$path" />
    <xsl:with-param name="parent-dir-name" select="@name" />
 -->
 
 <xsl:template match="c:directory" mode="archive-entry">
  <xsl:param name="parent-base" />
  <xsl:param name="parent-dir-name" />
  <xsl:variable name="base" select="@xml:base"/>
  <xsl:variable name="full-base" select="concat($parent-base, $base)"/>
  <xsl:variable name="separator" select="if($parent-dir-name = '' or ends-with($parent-dir-name, '/')) then '' else '/'"/>
  
  <xsl:apply-templates mode="archive-entry">
   <xsl:with-param name="parent-base" select="$full-base" />
   <xsl:with-param name="parent-dir-name" select="concat($parent-dir-name, $separator, @name, '/')" />
  </xsl:apply-templates>

 </xsl:template>

 <xsl:template match="c:file" mode="archive-entry">
  <xsl:param name="parent-base" />
  <xsl:param name="parent-dir-name" />
  <xsl:variable name="dir-path" select="if($parent-dir-name = '') then '' else concat($root-fix, $parent-dir-name)" />
  <xsl:variable name="base" select="@xml:base"/>
  <xsl:variable name="full-base" select="concat($parent-base, $base)"/>
  <c:entry name="{concat($dir-path, $base)}" href="{$full-base}" />
 </xsl:template>
 
</xsl:stylesheet>