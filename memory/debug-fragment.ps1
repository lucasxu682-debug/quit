$json = Get-Content 'C:\Users\xumou\.openclaw\workspace\memory\conversations\fragments\2026-04-05.json' -Raw
Write-Host "JSON: $json"

$data = $json | ConvertFrom-Json -AsHashtable
Write-Host "Data type: $($data.GetType().Name)"
Write-Host "Has fragments key: $($data.ContainsKey('fragments'))"

if ($data.ContainsKey('fragments')) {
    Write-Host "Fragments type: $($data.fragments.GetType().Name)"
    Write-Host "Fragments count: $($data.fragments.Count)"
    Write-Host "First fragment: $($data.fragments[0])"
}
