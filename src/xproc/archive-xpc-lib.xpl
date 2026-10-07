<p:library  xmlns:p="http://www.w3.org/ns/xproc" 
 xmlns:xs="http://www.w3.org/2001/XMLSchema" 
 xmlns:dxar="https://www.daliboris.cz/ns/xproc/archive"
 xmlns:c="http://www.w3.org/ns/xproc-step"
 xmlns:xhtml="http://www.w3.org/1999/xhtml"
 version="3.0">
 
 <p:documentation>
  <xhtml:section>
   <xhtml:h1></xhtml:h1>
   <xhtml:p></xhtml:p>
  </xhtml:section>
 </p:documentation>
 
 <p:declare-step type="dxar:archive-directory">
  
  <p:option name="input-directory" as="xs:string" />
  <p:option name="filter" as="xs:string*" />
  <p:option name="output-directory" as="xs:string" />
  <p:option name="output-file-name-pattern" as="xs:string" />
  <p:option name="directory-match" as="xs:string?" select="()" />
  <!-- {$project-acronym}-{$dictionary-id}-{$root-directory}.zip -->
  <p:option name="root-directory" as="xs:string?" /> <!-- concat($project-acronym, '/', $dictionary-id, '/') -->
  <p:option name="relative-to" as="xs:string?" /> <!-- ../Dictionary/entries/{$project-acronym} -->
  <p:option name="max-depth" as="xs:integer" select="1" />
  <p:option name="base-uri" as="xs:anyURI" select="static-base-uri()"/>
  
  <p:output port="result" pipe="report@archive" primary="true" serialization="map{'indent' : true()}" />
  <p:output port="result-uri" primary="false" pipe="result-uri@store" />
  <p:output port="manifest" primary="false" pipe="result@manifest" serialization="map{'indent' : true()}" />
  
  <p:variable name="input-directory-uri" select="resolve-uri($input-directory, $base-uri)" />
  <p:variable name="output-directory-uri" select="resolve-uri($output-directory, $base-uri)" />
  
  <p:directory-list path="{$input-directory-uri}/" max-depth="{$max-depth}">
   <p:with-option name="include-filter" select="$filter" />
  </p:directory-list>
  <p:identity message="path: {$input-directory-uri}/; include-filter: {string-join($filter, ' | ')}; max-depth: {$max-depth};" />
 
  <p:variable name="current-directory" select="/c:directory/@name" />
  <p:variable name="output-file-name" select="if (empty($directory-match) or $directory-match = '') then $output-file-name-pattern else replace($output-file-name-pattern, $directory-match, $current-directory)" />
  <p:variable name="files-count" select="count(//c:file)" />
  <p:xslt name="manifest" message="files-count: {$files-count}">
   <p:with-input port="stylesheet" href="../xslt/archive-directory-to-manifest.xsl" />
   <p:with-option name="parameters" select="map{'root' : $root-directory}" />
  </p:xslt>
  
  <p:variable name="entries-count" select="count(//c:entry)" />
  <p:archive name="archive" relative-to="{$relative-to}" message="entries-count: {$entries-count}">
   <p:with-input port="source">
    <p:empty />
   </p:with-input>
   <p:with-input port="manifest" pipe="@manifest"/>
  </p:archive>
  
  <p:store href="{$output-directory-uri}/{$output-file-name}" name="store" />
  
  
 </p:declare-step>
 
 <p:declare-step type="dxar:archive-directories">
  
  <p:option name="debug-path" select="()" as="xs:string?" />
  
  <p:option name="input-directory" as="xs:string" />
  <p:option name="filter" as="xs:string*" />
  <p:option name="output-directory" as="xs:string" />
  <p:option name="output-file-name-pattern" as="xs:string" />
  <p:option name="directory-match" as="xs:string?" select="()" />
  <p:option name="root-directory" as="xs:string?" />
  <p:option name="relative-to" as="xs:string?" />
  <p:option name="base-uri" as="xs:anyURI" select="static-base-uri()"/>
  
  
  <p:output port="result-uri" primary="true" pipe="result-uri@directories" serialization="map{'indent' : true()}" sequence="true"  />
  <p:output port="manifest" primary="false" pipe="manifest@directories" serialization="map{'indent' : true()}" sequence="true"  />
  
  <p:variable name="input-directory-uri" select="resolve-uri($input-directory, $base-uri)" />
  
  <p:directory-list path="{$input-directory-uri}/" message="Root: {$root-directory}; Path: {$input-directory}/; Filter: {string-join($filter, ' | ')}" max-depth="1" />
  

  <p:for-each name="directories">
   <p:with-input select="/c:directory//c:directory"/>
   <p:output port="result-uri" pipe="result-uri@archive-directory result-uri@archive-directories" sequence="true" primary="true" />
   <p:output port="manifest" pipe="manifest@archive-directory manifest@archive-directories" sequence="true" />
   <p:variable name="dir-name" select="/c:directory/@name" />
   <dxar:archive-directory 
    input-directory="{$input-directory}/{$dir-name}" 
    output-directory="{$output-directory}"
    output-file-name-pattern="{$output-file-name-pattern}"
    directory-match="{$directory-match}"
    root-directory="{$root-directory}"
    relative-to="{$relative-to}"
    base-uri="{$base-uri}"
    name="archive-directory"
    p:message="archiving directory: {$dir-name}">
    <p:with-option name="filter" select="$filter" />
   </dxar:archive-directory>
   
   <dxar:archive-directories 
    input-directory="{$input-directory}/{$dir-name}" 
    output-directory="{$output-directory}"
    output-file-name-pattern="{$output-file-name-pattern}"
    directory-match="{$directory-match}"
    root-directory="{$root-directory}"
    relative-to="{$relative-to}"
    base-uri="{$base-uri}"
    name="archive-directories"
    p:message="archiving directories in directory: {$dir-name}">
    <p:with-option name="filter" select="$filter" />
   </dxar:archive-directories>
  </p:for-each>
  
 </p:declare-step>
 
</p:library>