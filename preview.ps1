# Preview the static site locally (no Node required)
$port = 8080
$root = $PSScriptRoot

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()

Write-Host "UC Minecraft preview: http://localhost:$port/"
Write-Host "Press Ctrl+C to stop."

$mime = @{
  ".html" = "text/html; charset=utf-8"
  ".css"  = "text/css; charset=utf-8"
  ".js"   = "application/javascript; charset=utf-8"
  ".png"  = "image/png"
  ".jpg"  = "image/jpeg"
  ".woff2" = "font/woff2"
  ".ico"  = "image/x-icon"
}

try {
  while ($listener.IsListening) {
    $context = $listener.GetContext()
  $request = $context.Request
  $response = $context.Response

  $path = [System.Uri]::UnescapeDataString($request.Url.AbsolutePath)
  if ($path -eq "/") { $path = "/index.html" }
  $filePath = Join-Path $root ($path.TrimStart("/") -replace "/", [IO.Path]::DirectorySeparatorChar)

  if (Test-Path $filePath -PathType Container) {
    $filePath = Join-Path $filePath "index.html"
  }

  if (Test-Path $filePath -PathType Leaf) {
    $bytes = [System.IO.File]::ReadAllBytes($filePath)
    $ext = [IO.Path]::GetExtension($filePath).ToLower()
    $response.ContentType = $mime[$ext]
    if (-not $response.ContentType) { $response.ContentType = "application/octet-stream" }
    $response.StatusCode = 200
    $response.OutputStream.Write($bytes, 0, $bytes.Length)
  } else {
    $fallback = Join-Path $root "404.html"
    if (Test-Path $fallback) {
      $bytes = [System.IO.File]::ReadAllBytes($fallback)
      $response.ContentType = "text/html; charset=utf-8"
      $response.StatusCode = 404
      $response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $response.StatusCode = 404
    }
  }

  $response.Close()
  }
} finally {
  $listener.Stop()
}
