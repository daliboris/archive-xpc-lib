<p:declare-step
	xmlns:p="http://www.w3.org/ns/xproc"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:dxar="https://www.daliboris.cz/ns/xproc/archive"
	xmlns:c="http://www.w3.org/ns/xproc-step"
	xmlns:xhtml="http://www.w3.org/1999/xhtml"
	xmlns:dxt="https://www.daliboris.cz/ns/xproc/test"
	name="benchmark"
	version="3.0">

	<p:import href="../../xproc/archive-xpc-lib.xpl" />

	<p:documentation>
		<xhtml:section>
			<xhtml:h2>Benchmark of directory listing depth and filters</xhtml:h2>
			<xhtml:p>Runs one scenario (option <xhtml:code>scenario</xhtml:code>) on a synthetic tree
				<xhtml:code>tree/dict-N/l1-N/l2-N/…</xhtml:code> in <xhtml:code>../output/benchmark</xhtml:code>
				(git-ignored) and returns the number of listed files or archived entries.
				The duration is measured from outside by <xhtml:code>benchmark.sh</xhtml:code>, because
				<xhtml:code>current-dateTime()</xhtml:code> inside a pipeline is not precise enough.
				Scenario <xhtml:code>generate</xhtml:code> (re)creates the tree, scenario <xhtml:code>none</xhtml:code>
				does nothing and measures the processor start-up.</xhtml:p>
		</xhtml:section>
	</p:documentation>

	<p:output port="result" primary="true" serialization="map {'indent' : true()}" />

	<p:option name="scenario" select="'none'" as="xs:string" />
	<p:option name="output-directory" select="'../output/benchmark'" as="xs:string" />
	<p:option name="dictionaries" select="5" as="xs:integer" />
	<p:option name="branching" select="4" as="xs:integer" />
	<p:option name="levels" select="4" as="xs:integer" />
	<p:option name="files" select="5" as="xs:integer" />

	<!-- Creates $files XML files and one TXT file in $dir and, below $levels, $branching subdirectories. -->
	<p:declare-step type="dxt:make-tree" name="make-tree">
		<p:output port="result" primary="true" pipe="result@notes" />
		<p:option name="dir" as="xs:string" required="true" />
		<p:option name="prefix" as="xs:string" required="true" />
		<p:option name="level" as="xs:integer" required="true" />
		<p:option name="levels" as="xs:integer" required="true" />
		<p:option name="branching" as="xs:integer" required="true" />
		<p:option name="files" as="xs:integer" required="true" />

		<p:for-each>
			<p:with-input select="(1 to $files)">
				<p:inline><dummy /></p:inline>
			</p:with-input>
			<p:variable name="n" select="." />
			<p:store href="{$dir}/{$prefix}.file-{$n}.xml">
				<p:with-input>
					<p:inline><file n="{$n}" /></p:inline>
				</p:with-input>
			</p:store>
		</p:for-each>
		<p:store href="{$dir}/{$prefix}.notes.txt" name="notes">
			<p:with-input>
				<p:inline content-type="text/plain">notes</p:inline>
			</p:with-input>
		</p:store>

		<p:if test="$level lt $levels">
			<p:for-each>
				<p:with-input select="(1 to $branching)">
					<p:inline><dummy /></p:inline>
				</p:with-input>
				<p:variable name="n" select="." />
				<dxt:make-tree dir="{$dir}/l{$level + 1}-{$n}" prefix="l{$level + 1}-{$n}"
					level="{$level + 1}" levels="{$levels}" branching="{$branching}" files="{$files}" />
			</p:for-each>
		</p:if>
	</p:declare-step>

	<!-- Lists a directory and reports the number of files and directories. -->
	<p:declare-step type="dxt:listing" name="listing">
		<p:output port="result" primary="true" />
		<p:option name="path" as="xs:string" required="true" />
		<p:option name="max-depth" as="xs:string" required="true" />
		<p:option name="filter" as="xs:string*" select="()" />

		<p:directory-list path="{$path}/" max-depth="{$max-depth}">
			<p:with-option name="include-filter" select="$filter" />
		</p:directory-list>
		<p:variable name="file-count" select="count(//c:file)" />
		<p:variable name="directory-count" select="count(//c:directory) - 1" />
		<p:identity>
			<p:with-input>
				<p:inline><dxt:result step="p:directory-list" max-depth="{$max-depth}" filter="{string-join($filter, ' | ')}"
					files="{$file-count}" directories="{$directory-count}" /></p:inline>
			</p:with-input>
		</p:identity>
	</p:declare-step>

	<!-- Creates one ZIP with dxar:archive-directory and reports the number of entries. -->
	<p:declare-step type="dxt:archive" name="archive">
		<p:output port="result" primary="true" />
		<p:option name="input-directory" as="xs:string" required="true" />
		<p:option name="output-directory" as="xs:string" required="true" />
		<p:option name="max-depth" as="xs:integer" required="true" />
		<p:option name="filter" as="xs:string*" select="()" />

		<dxar:archive-directory name="archive-directory"
			input-directory="{$input-directory}"
			output-directory="{$output-directory}"
			output-file-name-pattern="archive.zip"
			max-depth="{$max-depth}">
			<p:with-option name="filter" select="$filter" />
		</dxar:archive-directory>
		<p:variable name="entry-count" select="count(//c:entry)" pipe="manifest@archive-directory" />
		<p:identity>
			<p:with-input>
				<p:inline><dxt:result step="dxar:archive-directory" max-depth="{$max-depth}" filter="{string-join($filter, ' | ')}"
					archives="1" entries="{$entry-count}" /></p:inline>
			</p:with-input>
		</p:identity>
	</p:declare-step>

	<!-- Creates one ZIP per directory with dxar:archive-directories and reports the number of archives and entries. -->
	<p:declare-step type="dxt:archives" name="archives">
		<p:output port="result" primary="true" />
		<p:option name="input-directory" as="xs:string" required="true" />
		<p:option name="output-directory" as="xs:string" required="true" />
		<p:option name="filter" as="xs:string*" select="()" />

		<dxar:archive-directories name="archive-directories"
			input-directory="{$input-directory}"
			output-directory="{$output-directory}"
			output-file-name-pattern="archive-__DIR__.zip"
			directory-match="__DIR__">
			<p:with-option name="filter" select="$filter" />
		</dxar:archive-directories>
		<p:variable name="archive-count" select="count(collection())" collection="true" />
		<p:variable name="entry-count" select="count(collection()//c:entry)" collection="true" pipe="manifest@archive-directories" />
		<p:identity>
			<p:with-input>
				<p:inline><dxt:result step="dxar:archive-directories" max-depth="1 (recursive)" filter="{string-join($filter, ' | ')}"
					archives="{$archive-count}" entries="{$entry-count}" /></p:inline>
			</p:with-input>
		</p:identity>
	</p:declare-step>

	<p:variable name="base-uri" select="static-base-uri()" />
	<p:variable name="output-directory-uri" select="resolve-uri($output-directory, $base-uri)" />
	<p:variable name="tree" select="$output-directory-uri || '/tree'" />
	<p:variable name="zip" select="$output-directory-uri || '/zip/' || $scenario" />
	<!-- deepest files are $levels + 2 levels below the tree root (dict-N, l1 … l$levels) -->
	<p:variable name="full-depth" select="$levels + 2" />

	<p:choose>
		<p:when test="$scenario = 'none'">
			<p:identity>
				<p:with-input><p:inline><dxt:result /></p:inline></p:with-input>
			</p:identity>
		</p:when>
		<p:when test="$scenario = 'generate'">
			<p:file-delete href="{$tree}" recursive="true" fail-on-error="false" name="delete-tree" />
			<p:for-each depends="delete-tree">
				<p:with-input select="(1 to $dictionaries)">
					<p:inline><dummy /></p:inline>
				</p:with-input>
				<p:variable name="n" select="." />
				<dxt:make-tree dir="{$tree}/dict-{$n}" prefix="dict-{$n}"
					level="0" levels="{$levels}" branching="{$branching}" files="{$files}" />
			</p:for-each>
			<p:count />
			<p:identity>
				<p:with-input>
					<p:inline><dxt:result tree="dictionaries={$dictionaries}; branching={$branching}; levels={$levels}; files={$files}" /></p:inline>
				</p:with-input>
			</p:identity>
		</p:when>

		<!-- listing of the whole tree: depth only -->
		<p:when test="$scenario = 'root-d1'">
			<dxt:listing path="{$tree}" max-depth="1" filter=".*\.xml" />
		</p:when>
		<p:when test="$scenario = 'root-d2'">
			<dxt:listing path="{$tree}" max-depth="2" filter=".*\.xml" />
		</p:when>
		<p:when test="$scenario = 'root-d3'">
			<dxt:listing path="{$tree}" max-depth="3" filter=".*\.xml" />
		</p:when>
		<p:when test="$scenario = 'root-dfull'">
			<dxt:listing path="{$tree}" max-depth="{$full-depth}" filter=".*\.xml" />
		</p:when>
		<p:when test="$scenario = 'root-dfull-all'">
			<dxt:listing path="{$tree}" max-depth="{$full-depth}" />
		</p:when>

		<!-- listing of the whole tree, one dictionary selected by a filter -->
		<p:when test="$scenario = 'root-d2-dict1'">
			<dxt:listing path="{$tree}" max-depth="2" filter="dict-1/.*\.xml" />
		</p:when>
		<p:when test="$scenario = 'root-dfull-dict1'">
			<dxt:listing path="{$tree}" max-depth="{$full-depth}" filter="dict-1/.*\.xml" />
		</p:when>

		<!-- listing of one dictionary directory -->
		<p:when test="$scenario = 'dict1-d1'">
			<dxt:listing path="{$tree}/dict-1" max-depth="1" filter=".*\.xml" />
		</p:when>
		<p:when test="$scenario = 'dict1-dfull'">
			<dxt:listing path="{$tree}/dict-1" max-depth="{$full-depth - 1}" filter=".*\.xml" />
		</p:when>
		<p:when test="$scenario = 'dict1-dfull-l1'">
			<dxt:listing path="{$tree}/dict-1" max-depth="{$full-depth - 1}" filter="l1-1/.*\.xml" />
		</p:when>

		<!-- ZIP of one dictionary -->
		<p:when test="$scenario = 'archive-dict1-d1'">
			<dxt:archive input-directory="{$tree}/dict-1" output-directory="{$zip}" max-depth="1" filter=".*\.xml" />
		</p:when>
		<p:when test="$scenario = 'archive-dict1-dfull'">
			<dxt:archive input-directory="{$tree}/dict-1" output-directory="{$zip}" max-depth="{$full-depth - 1}" filter=".*\.xml" />
		</p:when>
		<p:when test="$scenario = 'archive-root-dfull-dict1'">
			<dxt:archive input-directory="{$tree}" output-directory="{$zip}" max-depth="{$full-depth}" filter="dict-1/.*\.xml" />
		</p:when>
		<p:when test="$scenario = 'archives-dict1'">
			<dxt:archives input-directory="{$tree}/dict-1" output-directory="{$zip}" filter=".*\.xml" />
		</p:when>
		<p:otherwise>
			<p:error code="dxt:unknown-scenario">
				<p:with-input><p:inline>Unknown scenario: {$scenario}</p:inline></p:with-input>
			</p:error>
		</p:otherwise>
	</p:choose>
	<p:add-attribute attribute-name="scenario" attribute-value="{$scenario}" />
	<p:namespace-delete prefixes="c dxar xs xhtml" />
</p:declare-step>
