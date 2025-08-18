$ErrorActionPreference = "Stop"

$path = "redis_key.json"

try {
    if (Test-Path $path) {
        $json = Get-Content -Raw -Path $path | ConvertFrom-Json
        $json | ConvertTo-Json -Compress
    } else {
        @{ primary_key = "" } | ConvertTo-Json -Compress
    }
} catch {
    @{ primary_key = "" } | ConvertTo-Json -Compress
}