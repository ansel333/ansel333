$ErrorActionPreference = 'Stop'

$assetDir = Join-Path $PSScriptRoot '../../assets/profile'
[xml]$activity = Get-Content -LiteralPath (Join-Path $assetDir 'stats.svg') -Raw
[xml]$languageCard = Get-Content -LiteralPath (Join-Path $assetDir 'languages.svg') -Raw

$metrics = [ordered]@{
    commits  = 'Commits (last year)'
    stars    = 'Stars earned'
    prs      = 'Pull requests'
    issues   = 'Issues'
    contribs = 'Contributed to (last year)'
}
$activitySummary = @()
$activityRows = foreach ($metric in $metrics.GetEnumerator()) {
    $node = $activity.SelectSingleNode("//*[@data-testid='$($metric.Key)']")
    if (-not $node -or [string]::IsNullOrWhiteSpace($node.InnerText)) {
        throw "GitHub Readme Stats did not return $($metric.Key)."
    }

    $value = $node.InnerText.Trim()
    $y = 236 + 21 * $activitySummary.Count
    $activitySummary += "$($metric.Value) $value"
    $escapedValue = [System.Security.SecurityElement]::Escape($value)
    @"
      <text x="27" y="$y" fill="#c4d1dc">$($metric.Value)</text>
      <text x="326" y="$y" fill="#f0f6fc" text-anchor="end">$escapedValue</text>
"@
}

$languageSummary = @()
$languageRows = foreach ($node in $languageCard.SelectNodes("//*[@data-testid='lang-name']")) {
    $label = $node.InnerText.Trim()
    if ($label -notmatch '^(?<language>.+?)\s+(?<share>[0-9]+(?:\.[0-9]+)?%)$') {
        throw "Unrecognized language statistic: $label"
    }

    $name = $Matches.language
    $share = $Matches.share
    $y = 236 + 21 * $languageSummary.Count
    $languageSummary += $label
    if ($name.Length -gt 22) {
        $name = $name.Substring(0, 21) + '…'
    }
    $escapedName = [System.Security.SecurityElement]::Escape($name)
    @"
      <text x="370" y="$y" fill="#c4d1dc">$escapedName</text>
      <text x="653" y="$y" fill="#f0f6fc" text-anchor="end">$share</text>
"@
}
if ($languageSummary.Count -eq 0) {
    if ($languageCard.DocumentElement.InnerText -notmatch 'No languages data') {
        throw 'GitHub Readme Stats did not return language statistics.'
    }
    $languageSummary = @('No language data')
    $languageRows = '      <text x="370" y="236" fill="#c4d1dc">No language data</text>'
}

$activityDescription = $activitySummary -join ', '
$languageDescription = $languageSummary -join ', '
$description = [System.Security.SecurityElement]::Escape(
    "hi there. Ansel on GitHub as @ansel333. $activityDescription. Repository languages $languageDescription."
)
$rowCount = [Math]::Max($activitySummary.Count, $languageSummary.Count)
$footer = 236 + 21 * $rowCount + 10
$height = $footer + 20
$borderHeight = $height - 1
$dividerEnd = $footer - 25
$svg = @"
<svg xmlns="http://www.w3.org/2000/svg" width="680" height="$height" viewBox="0 0 680 $height" role="img" aria-labelledby="title description">
  <title id="title">Ansel in macOS Terminal</title>
  <desc id="description">$description</desc>
  <defs>
    <clipPath id="window">
      <rect width="680" height="$height" rx="13"/>
    </clipPath>
  </defs>

  <g clip-path="url(#window)">
    <rect width="680" height="$height" fill="#101a25"/>
    <rect width="680" height="32" fill="#29323d"/>
    <path stroke="#394957" d="M0 32.5h680"/>
    <circle cx="18" cy="16" r="5.5" fill="#ff5f57"/>
    <circle cx="36" cy="16" r="5.5" fill="#febc2e"/>
    <circle cx="54" cy="16" r="5.5" fill="#28c840"/>
    <text x="340" y="20.5" text-anchor="middle" fill="#e6eef5" font-family="system-ui, sans-serif" font-size="13" font-weight="600">Ansel · zsh</text>

    <g font-family="SFMono-Regular, Menlo, Consolas, monospace">
      <text x="27" y="62" font-size="19" fill="#b8c9d6" xml:space="preserve"><tspan fill="#67e8be">ansel</tspan> ~ % cat profile.txt</text>
      <text x="27" y="99" font-size="28" font-weight="700" fill="#f0f6fc">hi there</text>
      <g font-size="20">
        <text x="27" y="129" fill="#9eb1c2">name</text>
        <text x="89" y="129" fill="#e6eef5">Ansel</text>
        <text x="190" y="129" fill="#9eb1c2">github</text>
        <text x="277" y="129" fill="#67e8be">@ansel333</text>
      </g>

      <path d="M27 151h626 M348 202V$dividerEnd" fill="none" stroke="#304050"/>
      <text x="27" y="181" font-size="19" fill="#b8c9d6" xml:space="preserve"><tspan fill="#67e8be">ansel</tspan> ~ % github-stats --public</text>
      <g font-size="16">
        <text x="27" y="211" fill="#67e8be" font-weight="600">GitHub activity</text>
        <text x="370" y="211" fill="#67e8be" font-weight="600">Repository languages</text>
$($activityRows -join "`n")
$($languageRows -join "`n")
      </g>
      <text x="27" y="$footer" font-size="13" fill="#9eb1c2">GitHub Readme Stats · public data · updated weekly</text>
    </g>
  </g>
  <rect x=".5" y=".5" width="679" height="$borderHeight" rx="12.5" fill="none" stroke="#465667"/>
</svg>
"@

[IO.File]::WriteAllText((Join-Path $assetDir 'terminal.svg'), $svg + [char]10)
