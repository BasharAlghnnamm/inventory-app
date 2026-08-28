# Standalone static file server (no Python, no Node). Uses .NET TcpListener
# so no admin rights or URL reservations are needed. Runs on Windows/PowerShell.
param(
  [int]$Port = 8080,
  [string]$Root = (Join-Path $PSScriptRoot 'web')
)

$ErrorActionPreference = 'Stop'
$Root = [IO.Path]::GetFullPath($Root)

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
$listener.Start()
Write-Host "Inventory app running at http://localhost:$Port  (close this window to stop)"

function Get-Mime([string]$ext) {
  switch (($ext.ToLower())) {
    '.html' { return 'text/html' }
    '.js'   { return 'text/javascript' }
    '.css'  { return 'text/css' }
    '.json' { return 'application/json' }
    '.wasm' { return 'application/wasm' }
    '.png'  { return 'image/png' }
    '.ico'  { return 'image/x-icon' }
    '.ttf'  { return 'font/ttf' }
    '.otf'  { return 'font/otf' }
    default { return 'application/octet-stream' }
  }
}

while ($true) {
  $client = $null
  try {
    $client = $listener.AcceptTcpClient()
    $stream = $client.GetStream()
    $reader = [IO.StreamReader]::new($stream, [Text.Encoding]::ASCII)
    $line = $reader.ReadLine()
    if ($null -eq $line) { $client.Close(); continue }

    # Skip remaining request headers.
    while (($h = $reader.ReadLine()) -ne $null -and $h -ne '') { }

    $parts = $line -split ' '
    $path = if ($parts.Count -gt 1) { $parts[1] } else { '/' }
    if ([string]::IsNullOrEmpty($path) -or $path -eq '/') { $path = '/index.html' }
    $path = [Uri]::UnescapeDataString(($path -split '\?')[0])

    $rel = $path.TrimStart('/').Replace('/', [IO.Path]::DirectorySeparatorChar)
    $full = [IO.Path]::GetFullPath((Join-Path $Root $rel))

    if (-not $full.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase) -and $full -ne $Root) {
      $status = '403 Forbidden'
      $bytes = [Text.Encoding]::UTF8.GetBytes('Forbidden')
      $mime = 'text/plain'
    } elseif ([IO.File]::Exists($full)) {
      $status = '200 OK'
      $bytes = [IO.File]::ReadAllBytes($full)
      $mime = Get-Mime ([IO.Path]::GetExtension($full))
    } else {
      $status = '404 Not Found'
      $bytes = [Text.Encoding]::UTF8.GetBytes('Not Found')
      $mime = 'text/plain'
    }

    $head = "HTTP/1.1 $status`r`n" +
      "Content-Type: $mime`r`n" +
      "Cache-Control: no-cache`r`n" +
      "Content-Length: $($bytes.Length)`r`n" +
      "Connection: close`r`n`r`n"
    $headerBytes = [Text.Encoding]::ASCII.GetBytes($head)
    $out = [IO.BinaryWriter]::new($client.GetStream())
    $out.Write($headerBytes)
    $out.Write($bytes)
    $out.Flush()
  } catch {
    # Connection aborted mid-request: ignore and keep serving.
  } finally {
    if ($client) { $client.Close() }
  }
}
$listener.Stop()