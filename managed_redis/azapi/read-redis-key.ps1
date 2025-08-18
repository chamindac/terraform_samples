$ErrorActionPreference = "Stop"

$path = "redis_key.json"

try {
    if (Test-Path $path) {
        $json = Get-Content -Raw -Path $path | ConvertFrom-Json
        $jsonOut = $json | ConvertTo-Json -Compress

        # Print JSON to stdout FIRST so Terraform can read it
        Write-Output $jsonOut

        # Now that Terraform has read it, delete the file
        Remove-Item -Path $path -Force
    } else {
        @{ primary_key = "" } | ConvertTo-Json -Compress
    }
} catch {
    @{ primary_key = "" } | ConvertTo-Json -Compress
}
