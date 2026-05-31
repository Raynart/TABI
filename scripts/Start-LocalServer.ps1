param(
  [int]$Port = 4200,
  [int]$MaxPort = 4210,
  [switch]$Worker
)

$ErrorActionPreference = "Stop"

$Root = Resolve-Path (Join-Path $PSScriptRoot "..")
$LogPath = Join-Path $Root "local-server.log"
$HostName = "127.0.0.1"

function Write-Log {
  param([string]$Message)

  $Line = "{0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
  try {
    Add-Content -Path $LogPath -Value $Line -ErrorAction Stop
  } catch {
    Write-Warning "Could not write to ${LogPath}: $($_.Exception.Message)"
  }
  Write-Host $Line
}

function Test-PortAvailable {
  param([int]$CandidatePort)

  $Listener = $null
  try {
    $Listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Parse($HostName), $CandidatePort)
    $Listener.Start()
    return $true
  } catch {
    return $false
  } finally {
    if ($null -ne $Listener) {
      $Listener.Stop()
    }
  }
}

function Get-AvailablePort {
  for ($Candidate = $Port; $Candidate -le $MaxPort; $Candidate++) {
    if (Test-PortAvailable -CandidatePort $Candidate) {
      return $Candidate
    }
  }

  throw "No available port found from $Port to $MaxPort."
}

function Get-ContentType {
  param([string]$Path)

  switch ([System.IO.Path]::GetExtension($Path).ToLowerInvariant()) {
    ".css" { return "text/css; charset=utf-8" }
    ".html" { return "text/html; charset=utf-8" }
    ".js" { return "text/javascript; charset=utf-8" }
    ".json" { return "application/json; charset=utf-8" }
    ".svg" { return "image/svg+xml" }
    ".webp" { return "image/webp" }
    ".png" { return "image/png" }
    ".jpg" { return "image/jpeg" }
    ".jpeg" { return "image/jpeg" }
    ".xml" { return "application/xml; charset=utf-8" }
    ".txt" { return "text/plain; charset=utf-8" }
    default { return "application/octet-stream" }
  }
}

function Send-Bytes {
  param(
    [System.Net.HttpListenerResponse]$Response,
    [byte[]]$Bytes,
    [string]$ContentType,
    [int]$StatusCode = 200
  )

  $Response.StatusCode = $StatusCode
  $Response.ContentType = $ContentType
  $Response.ContentLength64 = $Bytes.Length
  $Response.OutputStream.Write($Bytes, 0, $Bytes.Length)
}

function Resolve-RequestPath {
  param([string]$RawPath)

  $DecodedPath = [System.Uri]::UnescapeDataString($RawPath)
  if ($DecodedPath -eq "/" -or [string]::IsNullOrWhiteSpace($DecodedPath)) {
    foreach ($DefaultFile in @("index.html", "tabi-mockup.html")) {
      $DefaultPath = Join-Path $Root $DefaultFile
      if (Test-Path -LiteralPath $DefaultPath -PathType Leaf) {
        return $DefaultPath
      }
    }
  }

  $RelativePath = $DecodedPath.TrimStart("/") -replace "/", [System.IO.Path]::DirectorySeparatorChar
  $CandidatePath = Join-Path $Root $RelativePath
  $ResolvedCandidate = [System.IO.Path]::GetFullPath($CandidatePath)
  $ResolvedRoot = [System.IO.Path]::GetFullPath($Root)

  if (-not $ResolvedCandidate.StartsWith($ResolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    return $null
  }

  if (Test-Path -LiteralPath $ResolvedCandidate -PathType Container) {
    foreach ($DefaultFile in @("index.html", "tabi-mockup.html")) {
      $DefaultPath = Join-Path $ResolvedCandidate $DefaultFile
      if (Test-Path -LiteralPath $DefaultPath -PathType Leaf) {
        return $DefaultPath
      }
    }
  }

  if (Test-Path -LiteralPath $ResolvedCandidate -PathType Leaf) {
    return $ResolvedCandidate
  }

  return $null
}

function Start-ServerWorker {
  param([int]$ListenPort)

  $env:TABI_HOST = $HostName
  $env:TABI_PORT = "$ListenPort"
  & node (Join-Path $PSScriptRoot "local-server-worker.mjs")
}
if ($Worker) {
  Start-ServerWorker -ListenPort $Port
  exit 0
}

$SelectedPort = Get-AvailablePort
$ScriptPath = $MyInvocation.MyCommand.Path
$Arguments = @(
  "-NoProfile",
  "-ExecutionPolicy", "Bypass",
  "-File", $ScriptPath,
  "-Port", $SelectedPort,
  "-MaxPort", $MaxPort,
  "-Worker"
)

Write-Log "supervisor starting local server at http://${HostName}:$SelectedPort/"
Write-Log "health check available at http://${HostName}:$SelectedPort/healthz"

while ($true) {
  $Process = Start-Process -FilePath "powershell" -ArgumentList $Arguments -WorkingDirectory $Root -WindowStyle Hidden -PassThru
  Write-Log "worker process started: pid=$($Process.Id)"
  $Process.WaitForExit()
  Write-Log "worker process exited: pid=$($Process.Id) code=$($Process.ExitCode); restarting in 2s"
  Start-Sleep -Seconds 2
}
