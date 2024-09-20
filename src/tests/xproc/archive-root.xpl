<p:declare-step 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:dxar="https://www.daliboris.cz/ns/xproc/archive"
	xmlns:c="http://www.w3.org/ns/xproc-step"
	xmlns:xhtml="http://www.w3.org/1999/xhtml"
	xmlns:dxt="https://www.daliboris.cz/ns/xproc/test"
	version="3.0">
	
	<p:import href="../../xproc/archive-xpc-lib.xpl" />
	
	<p:documentation>
		<xhtml:section>
			<xhtml:h2></xhtml:h2>
			<xhtml:p></xhtml:p>
		</xhtml:section>
	</p:documentation>
      
	<p:output port="result" primary="true" />
	
	<p:option name="debug-path" select="'../debug'" as="xs:string?" />
	
	<p:declare-step type="dxt:test-with-options">
		<p:output port="result-uri" primary="true" />

		<p:option name="debug-path" select="()" as="xs:string?" />
		
		<p:option name="input-directory" as="xs:string" />
		<p:option name="filter" as="xs:string" />
		<p:option name="output-directory" as="xs:string" />
		<p:option name="output-file-name-pattern" as="xs:string" />
		<p:option name="directory-match" as="xs:string?" />
		<p:option name="root-directory" as="xs:string?" />
		<p:option name="relative-to" as="xs:string?" />
		<p:option name="max-depth" as="xs:integer" select="1" />
		<p:option name="base-uri" as="xs:anyURI" select="static-base-uri()"/>

		<p:variable name="debug" select="not(empty($debug-path))" />
		<p:variable name="input-directory-uri" select="resolve-uri($input-directory, $base-uri)" />
		
		<p:directory-list path="{$input-directory-uri}/" include-filter="{$filter}" max-depth="{$max-depth}" />
		<p:identity message="path: {$input-directory-uri}/; include-filter: {$filter}; max-depth: {$max-depth};" />
		
		<p:if test="$debug">
			<p:store href="{$debug-path}/directory-list.xml" serialization="map {'indent' : true()}" />
		</p:if>
		
		<dxar:archive-directory p:use-when="true()"
			input-directory="{$input-directory}"
			output-directory="{$output-directory}"
			output-file-name-pattern="{$output-file-name-pattern}"
			filter="{$filter}"
			root-directory="{$root-directory}"
			relative-to="{$relative-to}"
			max-depth="{$max-depth}" 
			base-uri="{$base-uri}"/>
		
		<dxar:archive-directories p:use-when="false()"
			input-directory="{$input-directory}"
			output-directory="{$output-directory}"
			output-file-name-pattern="{$output-file-name-pattern}"
			directory-match="{$directory-match}"
			filter="{$filter}"
			root-directory="{$root-directory}"
			relative-to="{$relative-to}"
			base-uri="{$base-uri}" />
			
		
		
	</p:declare-step>
	
	
	<p:group use-when="true()">
		<dxt:test-with-options p:use-when="false()"
			debug-path="{$debug-path}"
			input-directory="../input/root"
			output-directory="../output"
			output-file-name-pattern="root___ID__.zip"
			directory-match="__ID__"
			filter=".*\.xml"
			relative-to="."
			root-directory="{()}"
			max-depth="3"
			base-uri="{static-base-uri()}"/>
		
		<p:variable name="project-acronym" select="'MORDigital'" />
		<p:variable name="dictionary-id" select="'MORAIS.DLP.1'" />
		
		<dxt:test-with-options
			debug-path="{$debug-path}"
			input-directory="../../../../../output/entries/{$project-acronym}" 
			output-directory="../output"
			output-file-name-pattern="{$project-acronym}-{$dictionary-id}-entries.zip"
			filter=".*\.xml" 
			max-depth="3" 
			root-directory="{$project-acronym}"   
			base-uri="{static-base-uri()}"
		/>
		
		<p:identity>
			<p:with-input pipe="result-uri" />
		</p:identity>
	</p:group>
</p:declare-step>
