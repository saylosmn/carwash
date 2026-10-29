param(
    [string]$ProjectUrl,
    [string]$PublishableKey,
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $ProjectUrl) { $ProjectUrl = Read-Host 'Supabase Project URL' }
if (-not $PublishableKey) { $PublishableKey = Read-Host 'Supabase publishable / anon key' }
$ProjectUrl = $ProjectUrl.Trim().TrimEnd('/')
$PublishableKey = $PublishableKey.Trim()

$uri = $null
if (-not [Uri]::TryCreate($ProjectUrl, [UriKind]::Absolute, [ref]$uri) -or $uri.Scheme -ne 'https' -or -not $uri.Host) {
    throw 'Project URL нь хүчинтэй https:// хаяг байх ёстой.'
}
if ($PublishableKey -match '^(sb_secret_|sb_service_)' -or $PublishableKey -match 'service_role') {
    throw 'Secret/service_role key оруулж болохгүй. Publishable/anon key ашиглана уу.'
}
if ($PublishableKey.StartsWith('eyJ')) {
    try {
        $payload = $PublishableKey.Split('.')[1].Replace('-', '+').Replace('_', '/')
        $payload = $payload.PadRight($payload.Length + (4 - $payload.Length % 4) % 4, '=')
        $claims = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload)) | ConvertFrom-Json
        if ($claims.role -ne 'anon') { throw 'JWT key-ийн role нь anon байх ёстой.' }
    } catch {
        throw 'JWT key-ийг шалгаж чадсангүй. Anon key эсэхийг баталгаажуулна уу.'
    }
} elseif (-not $PublishableKey.StartsWith('sb_publishable_')) {
    throw 'Publishable key нь sb_publishable_ эсвэл хуучин anon JWT байх ёстой.'
}

if ($DryRun) {
    Write-Host "Тохиргоо зөв: $($uri.Host). Файл өөрчлөгдөөгүй."
    exit 0
}

$config = "// Public Supabase values only. Never place a secret key here.`nwindow.EASY_CONFIG = { supabaseUrl: $(($ProjectUrl | ConvertTo-Json -Compress)), supabaseAnonKey: $(($PublishableKey | ConvertTo-Json -Compress)) };`n"
$webPath = Join-Path $projectRoot 'dist/config.js'
$appPath = Join-Path $projectRoot 'admin-app/.env.local'
[IO.File]::WriteAllText($webPath, $config, [Text.UTF8Encoding]::new($false))
$appConfig = "EXPO_PUBLIC_SUPABASE_URL=$ProjectUrl`nEXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY=$PublishableKey`n"
[IO.File]::WriteAllText($appPath, $appConfig, [Text.UTF8Encoding]::new($false))
Write-Host 'Сайт болон Expo аппын public тохиргоо бэлэн. Дараа нь SQL-г ажиллуулж, админ хэрэглэгчээ нэмээд git push хийнэ.'
