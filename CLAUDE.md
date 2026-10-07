# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

XProc 3.0 helper library for building ZIP archives from directory trees. There is no build system, package manifest, or processor configuration in the repo — pipelines are run directly with an XProc 3.0 processor (e.g. XML Calabash 3 or MorganaXProc-IIIse), which must support `p:directory-list`, `p:archive`, and `p:xslt` (XSLT 3.0).

## Running the tests

`src/tests/xproc/test-suite.xpl` is the automated test suite (run from `src/tests/xproc/`, or pass the path):

```
xmlcalabash src/tests/xproc/test-suite.xpl
morgana src/tests/xproc/test-suite.xpl       # Git Bash; "Morgana" in PowerShell
```

- Run it with **both** processors; they must give identical results.
- Each scenario calls a `dxar` step on the fixture `src/tests/input/root` (output into `src/tests/output/<scenario>/`, git-ignored), then `dxt:check-archives` reads every created ZIP back with `p:archive-manifest` and compares archive file names and entry names (order-independent) with an expected `map(xs:string, xs:string*)` (archive name → entries) via `src/tests/xslt/check-archives.xsl`. It also compares the entry names of the manifests the library returns on its `manifest` port (paired with the archives by position, which holds because `result-uri` and `manifest` are emitted in the same order) with those read back from the ZIPs.
- The report (`dxt:test-results` with `passed`/`failed` counts and missing/unexpected entries) goes to the `result` port and `src/tests/output/test-results.xml`; any failure raises `dxt:test-failed` (non-zero exit). Option `fail-on-error=false()` suppresses the error.
- Each test also stores the compared data (output port `check` of `dxt:check-archives`: archive manifests read from the ZIPs + generated manifests) to `src/tests/output/<scenario>/check.xml` for debugging.
- To add a scenario: copy a block (step with unique `name` → `dxt:check-archives name="<scenario>-check"` fed with `result-uri@name` and `manifest@name` → `p:identity name="tNN"` → `p:store` of `check@<scenario>-check`) and add `result@tNN` to the final `p:wrap-sequence`. The fixture deliberately mixes `.xml`, `.txt` and `.json` files across three levels to exercise filters; changing it changes the expectations of most tests.
- Processor quirk: Morgana evaluates `-option:name=value` as XPath, so string values need quotes (`"-option:dir='...'"`); Calabash takes `name=value` literally.

`src/tests/xproc/archive-root.xpl` is an older manual driver: its active case reads from `../../../../../output/entries/MORDigital`, a path **outside this repo**; cases are switched with `p:use-when`.

## Architecture

All steps live in `src/xproc/archive-xpc-lib.xpl` (namespace `dxar` = `https://www.daliboris.cz/ns/xproc/archive`); consumers `p:import` it.

- **`dxar:archive-directory`** — the core step. Pipeline: `p:directory-list` (with `include-filter` and `max-depth`) → `p:xslt` with `src/xslt/archive-directory-to-manifest.xsl` turning the `c:directory` tree into a `c:archive` manifest of `c:entry name/href` → `p:archive` → `p:store`. Primary output is the archive report; `result-uri` is the stored file's URI.
- **`dxar:archive-directories`** — lists immediate subdirectories (`max-depth=1`) and, for each one, calls `dxar:archive-directory` and then **recursively calls itself**, so every directory at every depth gets its own ZIP. Its output is the sequence of `result-uri`s.
- **`filter` option is `xs:string*`:** a sequence of regexes passed to `p:directory-list/@include-filter` (a file is included if it matches any; `()` includes all files; directory names are not filtered). It must always be passed on with `<p:with-option name="filter" select="$filter"/>`, never as an attribute value template `filter="{$filter}"`, which would join the sequence into one space-separated string. A single regex can still be given as a plain attribute by callers.
- **Outputs:** both steps expose a non-primary `manifest` port with the XSLT-generated `c:archive` manifest(s), in the same order as `result-uri`. In `dxar:archive-directories` the step-level outputs must be wired explicitly (`pipe="…@directories"`) to the named `p:for-each`; an unconnected non-primary output silently yields an empty sequence in both processors.
- **Output file naming:** `output-file-name-pattern` is used literally unless `directory-match` is set, in which case that regex in the pattern is replaced by the current directory's name (e.g. pattern `root___ID__.zip`, match `__ID__`).
- **Entry paths inside the ZIP:** built by the XSLT. Every entry name is `root-directory` (if non-empty; trailing `/` added automatically) + the subdirectory path relative to the listed directory + the file name. `href` is built by concatenating the nested `xml:base` values.
- **Path resolution:** `input-directory` and `output-directory` are resolved against the `base-uri` option, which defaults to `static-base-uri()` of the library. Callers should pass their own `static-base-uri()` (as the test does) so relative paths resolve from the caller, and the recursive step forwards `base-uri` unchanged.
