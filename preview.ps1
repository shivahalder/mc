# Preview the static site locally (no Node required)
$root = $PSScriptRoot
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
$listener.Start()
$port = ([System.Net.IPEndPoint]$listener.LocalEndpoint).Port

Write-Host "UC Minecraft preview: http://localhost:$port/"
Write-Host "Press Ctrl+C to stop."

$mime = @{
  ".html"  = "text/html; charset=utf-8"
  ".css"   = "text/css; charset=utf-8"
  ".js"    = "application/javascript; charset=utf-8"
  ".png"   = "image/png"
  ".jpg"   = "image/jpeg"
  ".jpeg"  = "image/jpeg"
  ".woff2" = "font/woff2"
  ".ico"   = "image/x-icon"
}

function Get-HttpResponseBytes {
  param(
    [int]$StatusCode,
    [string]$StatusText,
    [byte[]]$Body,
    [string]$ContentType = "text/plain; charset=utf-8"
  )

  $header = @(
    "HTTP/1.1 $StatusCode $StatusText"
    "Content-Type: $ContentType"
    "Content-Length: $($Body.Length)"
    "Connection: close"
    ""
    ""
  ) -join "`r`n"

  $headerBytes = [System.Text.Encoding]::ASCII.GetBytes($header)
  $combined = New-Object byte[] ($headerBytes.Length + $Body.Length)
  [Array]::Copy($headerBytes, 0, $combined, 0, $headerBytes.Length)
  [Array]::Copy($Body, 0, $combined, $headerBytes.Length, $Body.Length)
  return $combined
}

try {
  while ($true) {
    $client = $listener.AcceptTcpClient()
    try {
      $stream = $client.GetStream()
      $reader = [System.IO.StreamReader]::new($stream, [System.Text.Encoding]::ASCII, $false, 1024, $true)
      $requestLine = $reader.ReadLine()
      if (-not $requestLine) { continue }

      while ($true) {
        $line = $reader.ReadLine()
        if ([string]::IsNullOrEmpty($line)) { break }
      }

      $parts = $requestLine.Split(" ")
      $path = "/"
      if ($parts.Length -ge 2) { $path = $parts[1] }
      $path = $path.Split("?")[0]
      $path = [System.Uri]::UnescapeDataString($path)
      if ($path -eq "/") { $path = "/index.html" }

      $filePath = Join-Path $root ($path.TrimStart("/") -replace "/", [IO.Path]::DirectorySeparatorChar)
      if (Test-Path $filePath -PathType Container) {
        $filePath = Join-Path $filePath "index.html"
      }

      if (Test-Path $filePath -PathType Leaf) {
        $bytes = [System.IO.File]::ReadAllBytes($filePath)
        $ext = [IO.Path]::GetExtension($filePath).ToLower()
        $contentType = $mime[$ext]
        if (-not $contentType) { $contentType = "application/octet-stream" }
        $responseBytes = Get-HttpResponseBytes -StatusCode 200 -StatusText "OK" -Body $bytes -ContentType $contentType
      } else {
        $fallback = Join-Path $root "404.html"
        if (Test-Path $fallback) {
          $bytes = [System.IO.File]::ReadAllBytes($fallback)
          $responseBytes = Get-HttpResponseBytes -StatusCode 404 -StatusText "Not Found" -Body $bytes -ContentType "text/html; charset=utf-8"
        } else {
          $bytes = [System.Text.Encoding]::UTF8.GetBytes("Not Found")
          $responseBytes = Get-HttpResponseBytes -StatusCode 404 -StatusText "Not Found" -Body $bytes -ContentType "text/plain; charset=utf-8"
        }
      }

      $stream.Write($responseBytes, 0, $responseBytes.Length)
      $stream.Flush()
    } catch {
      # Ignore request-level errors to keep server alive.
    } finally {
      try { $client.Close() } catch {}
    }
  }
} finally {
  try { $listener.Stop() } catch {}
}
