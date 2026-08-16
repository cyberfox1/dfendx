# BuildHelp.ps1 — generate Lang\English.chm and Lang\German.chm via Free Pascal chmcmd.
# Stock .hhp [WINDOWS]/Binary TOC break chmcmd; we emit a clean project that keeps
# [FILES], full [MAP], and generated [ALIAS] so HELP_CONTEXT IDs work in the app.
#
# Usage: from repo root, or called by Install\BuildHelp.bat / BuildInstallers*.bat
# Requires: chmcmd.exe on PATH (resolved as chmcmd or chmcmd.exe)

param(
  [string]$RepoRoot = ""
)

$ErrorActionPreference = 'Stop'

if (-not $RepoRoot) {
  $RepoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
  # When script lives in Install\, parent is repo root (project is Src\DFend.dpr)
  if (Test-Path (Join-Path $PSScriptRoot '..\Src\DFend.dpr')) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
  } elseif (Test-Path (Join-Path $PSScriptRoot '..\DFend.dpr')) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
  } elseif (Test-Path (Join-Path (Get-Location) 'Src\DFend.dpr')) {
    $RepoRoot = (Get-Location).Path
  } elseif (Test-Path (Join-Path (Get-Location) 'DFend.dpr')) {
    $RepoRoot = (Get-Location).Path
  }
}

Set-Location $RepoRoot

function Resolve-ChmCmd {
  if ($env:CHMCMD -and (Test-Path -LiteralPath $env:CHMCMD)) {
    return (Resolve-Path -LiteralPath $env:CHMCMD).Path
  }
  foreach ($name in @('chmcmd', 'chmcmd.exe')) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
  }
  # Same default as test\runTests.bat
  $candidates = @(
    'g:\dev\fpc322\bin\i386-win32\chmcmd.exe',
    'G:\Dev\fpc322\bin\i386-Win32\chmcmd.exe',
    'C:\FPC\3.2.2\bin\i386-win32\chmcmd.exe',
    'C:\lazarus\fpc\3.2.2\bin\i386-win32\chmcmd.exe'
  )
  foreach ($c in $candidates) {
    if (Test-Path -LiteralPath $c) { return (Resolve-Path -LiteralPath $c).Path }
  }
  return $null
}

$chmcmdExe = Resolve-ChmCmd
if (-not $chmcmdExe) {
  Write-Error "chmcmd.exe not found. Put Free Pascal bin on PATH, set CHMCMD, or install at g:\dev\fpc322\bin\i386-win32\ (see test\runTests.bat)."
}
Write-Host "Using chmcmd: $chmcmdExe"

$wiki2help = Join-Path $PSScriptRoot 'wiki2help.py'
$wikiSrc = Join-Path $RepoRoot 'Src\wiki'
$helpEn = Join-Path $RepoRoot 'Help\English'
$py = $null
if ($env:WIKI_PYTHON -and (Test-Path -LiteralPath $env:WIKI_PYTHON)) {
  $py = (Resolve-Path -LiteralPath $env:WIKI_PYTHON).Path
} else {
  foreach ($name in @('python.exe', 'python')) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) { $py = $cmd.Source; break }
  }
}
if (-not $py) { throw "python.exe not found (needed for Install\wiki2help.py)" }
if (-not (Test-Path -LiteralPath $wiki2help)) { throw "Missing $wiki2help" }
if (-not (Test-Path -LiteralPath (Join-Path $wikiSrc 'Home.md'))) { throw "Missing Src\wiki\Home.md" }
Write-Host ""
Write-Host "=== wiki2help: Src\wiki -> Help\English ==="
& $py $wiki2help $wikiSrc -o $helpEn
if ($LASTEXITCODE -ne 0) { throw "wiki2help.py failed (exit $LASTEXITCODE)" }
if (-not (Test-Path -LiteralPath (Join-Path $helpEn 'Index.html'))) {
  throw "wiki2help did not produce Help\English\Index.html"
}

function Build-OneChm {
  param(
    [string]$LangDirRel,
    [string]$HhpName,
    [string]$ChmName,
    [string]$Title
  )

  $base = Join-Path $RepoRoot $LangDirRel
  $hhpPath = Join-Path $base $HhpName
  if (-not (Test-Path -LiteralPath $hhpPath)) {
    throw "Missing $hhpPath"
  }

  Write-Host ""
  Write-Host "=== Building $LangDirRel\$ChmName ==="

  $files = New-Object System.Collections.Generic.List[string]
  $mapLines = New-Object System.Collections.Generic.List[string]
  $aliasLines = New-Object System.Collections.Generic.List[string]
  $section = ''

  Get-Content -LiteralPath $hhpPath | ForEach-Object {
    $line = $_
    if ($line -match '^\[(.+)\]\s*$') {
      $section = $Matches[1].ToUpperInvariant()
      return
    }
    switch ($section) {
      'FILES' {
        $t = $line.Trim()
        if ($t -ne '' -and (Test-Path -LiteralPath (Join-Path $base $t))) {
          [void]$files.Add($t)
        }
      }
      'MAP' {
        if ($line -match '^\s*#define\s+(\w+)\s+(\d+)\s*$') {
          $sym = $Matches[1]
          $id = $Matches[2]
          [void]$mapLines.Add("#define $sym $id")
          $html = "$sym.html"
          if (Test-Path -LiteralPath (Join-Path $base $html)) {
            [void]$aliasLines.Add("$sym=$html")
          } else {
            Write-Warning "MAP $sym ($id): no $html in $LangDirRel"
          }
        }
      }
    }
  }

  if ($files.Count -eq 0) { throw "No FILES found in $HhpName" }
  if ($mapLines.Count -eq 0) { throw "No MAP #defines found in $HhpName" }

  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine('[OPTIONS]')
  [void]$sb.AppendLine("Compiled file=$ChmName")
  [void]$sb.AppendLine('Contents file=toc.hhc')
  [void]$sb.AppendLine('Index file=Index.hhk')
  [void]$sb.AppendLine('Default topic=Index.html')
  [void]$sb.AppendLine("Title=$Title")
  [void]$sb.AppendLine('Language=0x409 English (United States)')
  [void]$sb.AppendLine('Full-text search=Yes')
  [void]$sb.AppendLine('')
  # Required for the HH contents tree pane. Stock English.hhp has this; without it
  # chmcmd builds a CHM with topics but no left-hand TOC UI. Do not use Binary TOC=Yes
  # (breaks chmcmd). Style flags match the stock project window definition.
  [void]$sb.AppendLine('[WINDOWS]')
  [void]$sb.AppendLine(("default=`"{0}`",`"toc.hhc`",`"Index.hhk`",`"Index.html`",`"Index.html`",,,,,0x2520,200,0x3046,[0,0,649,513],0xb0000,,,,,,0" -f $Title))
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('[FILES]')
  foreach ($f in $files) { [void]$sb.AppendLine($f) }
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('[MAP]')
  foreach ($m in $mapLines) { [void]$sb.AppendLine($m) }
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('[ALIAS]')
  foreach ($a in $aliasLines) { [void]$sb.AppendLine($a) }

  $gen = Join-Path $base '_chmcmd_build.hhp'
  [IO.File]::WriteAllText($gen, $sb.ToString(), (New-Object System.Text.UTF8Encoding $false))
  Write-Host ("  files={0} map={1} alias={2}" -f $files.Count, $mapLines.Count, $aliasLines.Count)

  Push-Location $base
  try {
    & $chmcmdExe --verbosity 0 _chmcmd_build.hhp
    if ($LASTEXITCODE -ne 0) { throw "chmcmd failed for $LangDirRel (exit $LASTEXITCODE)" }
  } finally {
    Pop-Location
  }

  $built = Join-Path $base $ChmName
  if (-not (Test-Path -LiteralPath $built)) {
    throw "chmcmd did not produce $built"
  }

  $destDir = Join-Path $RepoRoot 'Lang'
  if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir | Out-Null }
  $dest = Join-Path $destDir $ChmName
  Copy-Item -Force -LiteralPath $built -Destination $dest
  Write-Host ("  OK -> Lang\{0} ({1} bytes)" -f $ChmName, (Get-Item $built).Length)
  Remove-Item -Force -LiteralPath $gen -ErrorAction SilentlyContinue
}

function Write-HelpContextMapPas {
  param(
    [string]$LangDirRel,
    [string]$HhpName
  )

  $base = Join-Path $RepoRoot $LangDirRel
  $hhpPath = Join-Path $base $HhpName
  if (-not (Test-Path -LiteralPath $hhpPath)) {
    throw "Missing $hhpPath"
  }

  $topicOverrides = @{
    'Menu' = 'Index.html'   # Menu.html only meta-refreshes to Index#Menu
  }

  $entries = @()
  $section = ''

  Get-Content -LiteralPath $hhpPath | ForEach-Object {
    $line = $_
    if ($line -match '^\[(.+)\]\s*$') {
      $section = $Matches[1].ToUpperInvariant()
      return
    }
    if ($section -eq 'MAP' -and $line -match '^\s*#define\s+(\w+)\s+(\d+)\s*$') {
      $sym = $Matches[1]
      $id = [int]$Matches[2]

      if ($topicOverrides.ContainsKey($sym)) {
        $entries += @{ id = $id; sym = $sym; file = $topicOverrides[$sym] }
      } else {
        $html = "$sym.html"
        if (Test-Path -LiteralPath (Join-Path $base $html)) {
          $entries += @{ id = $id; sym = $sym; file = $html }
        } else {
          Write-Warning "HelpContextMap: MAP $sym ($id): no $html in $LangDirRel — skipping"
        }
      }
    }
  }

  if ($entries.Count -eq 0) {
    throw "No MAP entries found for HelpContextMap generation in $HhpName"
  }

  $sorted = $entries | Sort-Object { $_.id }

  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine('unit HelpContextMap;')
  [void]$sb.AppendLine('{ Auto-generated from ' + ($LangDirRel -replace '/','\') + '\' + $HhpName + ' [MAP] by BuildHelp.ps1; do not hand-edit. }')
  [void]$sb.AppendLine('interface')
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('function HelpContextToTopic(const ContextID: Integer): string;')
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('implementation')
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('function HelpContextToTopic(const ContextID: Integer): string;')
  [void]$sb.AppendLine('begin')
  [void]$sb.AppendLine('  Result := '''';')
  [void]$sb.AppendLine('  case ContextID of')

  foreach ($e in $sorted) {
    $idStr = $e.id.ToString().PadLeft(5)
    if ($topicOverrides.ContainsKey($e.sym)) {
      [void]$sb.AppendLine('    { ' + $e.sym + '.html only meta-refreshes to Index#' + $e.sym + '; open ' + $topicOverrides[$e.sym] + ' at top (Welcome). }')
    }
    [void]$sb.AppendLine("$idStr : Result := '$($e.file)';")
  }

  [void]$sb.AppendLine('  end;')
  [void]$sb.AppendLine('end;')
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine('end.')

  $outPath = Join-Path $RepoRoot 'Src\HelpContextMap.pas'
  [IO.File]::WriteAllText($outPath, $sb.ToString(), (New-Object System.Text.UTF8Encoding $false))
  Write-Host ("  -> Src\HelpContextMap.pas ({0} entries)" -f $entries.Count)
}

Build-OneChm -LangDirRel 'Help\English' -HhpName 'English.hhp' -ChmName 'English.chm' -Title 'DFendX help'
Write-HelpContextMapPas -LangDirRel 'Help\English' -HhpName 'English.hhp'
Build-OneChm -LangDirRel 'Help\German'  -HhpName 'German.hhp'  -ChmName 'German.chm'  -Title 'DFendX Hilfe'

Write-Host ""
Write-Host "Help CHMs ready:"
Get-ChildItem (Join-Path $RepoRoot 'Lang\English.chm'), (Join-Path $RepoRoot 'Lang\German.chm') |
  ForEach-Object { Write-Host ("  {0}  {1}" -f $_.Name, $_.Length) }
