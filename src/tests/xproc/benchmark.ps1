<#
.SYNOPSIS
 Measures the scenarios of benchmark.xpl from outside (wall-clock time of the whole processor run).

.DESCRIPTION
 Each scenario runs in a fresh JVM; scenario "none" gives the start-up time to subtract.
 Results go to ..\output\benchmark\benchmark-<processor>.tsv. Same behaviour as benchmark.sh.

.EXAMPLE
 .\benchmark.ps1 -Processor morgana -Runs 3 -Options levels=5, branching=3

.EXAMPLE
 .\benchmark.ps1 -Processor calabash -SkipGenerate
 Reuses an existing tree (it must have been generated with the same options).
#>
param(
	[ValidateSet('calabash', 'morgana')]
	[string] $Processor = 'morgana',
	[int] $Runs = 3,
	# extra pipeline options as name=value
	[string[]] $Options = @(),
	[switch] $SkipGenerate
)
$ErrorActionPreference = 'Stop'

Set-Location $PSScriptRoot
$outDir = '..\output\benchmark'
New-Item -ItemType Directory -Force $outDir | Out-Null
$tsv = Join-Path $outDir "benchmark-$Processor.tsv"

$scenarios = @('none',
	'root-d1', 'root-d2', 'root-d3', 'root-dfull', 'root-dfull-all',
	'root-d2-dict1', 'root-dfull-dict1',
	'dict1-d1', 'dict1-dfull', 'dict1-dfull-l1',
	'archive-dict1-d1', 'archive-dict1-dfull', 'archive-root-dfull-dict1', 'archives-dict1')

# Runs one scenario and returns the result element on one line, or 'FAILED'.
function Invoke-Scenario([string] $Scenario) {
	$arguments = @("scenario=$Scenario") + $Options
	$output = switch ($Processor) {
		'calabash' { & xmlcalabash benchmark.xpl @arguments 2>&1 }
		'morgana' { & Morgana benchmark.xpl @($arguments | ForEach-Object { "-option:$_" }) 2>&1 }
	}
	$text = ($output | Out-String) -replace '\s+', ' '
	$match = [regex]::Match($text, '<dxt:result[^>]*>')
	if ($match.Success) { $match.Value -replace ' xmlns:dxt="[^"]*"', '' } else { 'FAILED' }
}

if (-not $SkipGenerate) {
	Write-Host "Generating tree ($(if ($Options) { $Options -join ' ' } else { 'defaults' })) ..."
	$generated = Invoke-Scenario 'generate'
	if ($generated -eq 'FAILED') {
		throw "Tree generation failed; run 'scenario=generate' by hand to see the error."
	}
	Write-Host $generated
}

"scenario`trun`tms`tresult" | Set-Content -Encoding utf8NoBOM $tsv
foreach ($s in $scenarios) {
	for ($i = 1; $i -le $Runs; $i++) {
		$watch = [Diagnostics.Stopwatch]::StartNew()
		$result = Invoke-Scenario $s
		$watch.Stop()
		$line = "$s`t$i`t$($watch.ElapsedMilliseconds)`t$result"
		Write-Host $line
		$line | Add-Content -Encoding utf8NoBOM $tsv
	}
}
Write-Host "Results: $tsv"
