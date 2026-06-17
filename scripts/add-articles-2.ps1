$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent

$articlesPath = Join-Path $root 'articles.json'
$newPath      = Join-Path $root 'new-articles-2.json'

$existing    = Get-Content $articlesPath -Raw | ConvertFrom-Json
$newArticles = Get-Content $newPath      -Raw | ConvertFrom-Json

$all = @($newArticles) + @($existing)

Write-Host "Total articles: $($all.Count)"

$json = $all | ConvertTo-Json -Depth 20
[System.IO.File]::WriteAllText($articlesPath, $json, [System.Text.UTF8Encoding]::new($false))

Write-Host "Done." -ForegroundColor Green
