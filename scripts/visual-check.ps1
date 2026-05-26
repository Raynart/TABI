$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$OutputDir = Join-Path $Root "screenshots\visual-check"
$EdgeCandidates = @(
  "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
  "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
)
$Edge = $EdgeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1

if (-not $Edge) {
  throw "Microsoft Edge was not found. Install Edge or update scripts/visual-check.ps1 with a browser path."
}

if (-not (Test-Path $OutputDir)) {
  New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
}

$Pages = @(
  @{ Name = "home-desktop"; Url = "http://127.0.0.1:4200/index.html"; Width = 1440; Height = 1200 },
  @{ Name = "home-mobile"; Url = "http://127.0.0.1:4200/index.html"; Width = 390; Height = 1200 },
  @{ Name = "article-desktop"; Url = "http://127.0.0.1:4200/articles/best-japanese-kitchen-knives-to-bring-home.html"; Width = 1440; Height = 1400 },
  @{ Name = "article-mobile"; Url = "http://127.0.0.1:4200/articles/best-japanese-kitchen-knives-to-bring-home.html"; Width = 390; Height = 1400 },
  @{ Name = "ja-home-mobile"; Url = "http://127.0.0.1:4200/ja/index.html"; Width = 390; Height = 1200 },
  @{ Name = "ja-policy-desktop"; Url = "http://127.0.0.1:4200/ja/source-policy.html"; Width = 1440; Height = 1200 }
)

$StartedServer = $false
try {
  Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:4200/" -TimeoutSec 2 | Out-Null
} catch {
  Start-Process -FilePath python -ArgumentList @("-m", "http.server", "4200", "--bind", "127.0.0.1") -WorkingDirectory $Root -WindowStyle Hidden | Out-Null
  $StartedServer = $true
  Start-Sleep -Seconds 2
}

foreach ($Page in $Pages) {
  $Target = Join-Path $OutputDir "$($Page.Name).png"
  $UserDataDir = Join-Path $OutputDir "profile-$($Page.Name)"
  $Arguments = @(
    "--headless",
    "--disable-gpu",
    "--hide-scrollbars",
    "--user-data-dir=$UserDataDir",
    "--window-size=$($Page.Width),$($Page.Height)",
    "--screenshot=$Target",
    $Page.Url
  )
  $Process = Start-Process -FilePath $Edge -ArgumentList $Arguments -Wait -PassThru -WindowStyle Hidden
  if ($Process.ExitCode -ne 0) {
    throw "Edge screenshot failed for $($Page.Name) with exit code $($Process.ExitCode)."
  }
  $File = Get-Item $Target
  if ($File.Length -lt 5000) {
    throw "Screenshot for $($Page.Name) looks too small: $($File.Length) bytes."
  }
}

Write-Host "Visual screenshots written to $OutputDir"
if ($StartedServer) {
  Write-Host "A local static server was started on http://127.0.0.1:4200/."
}
