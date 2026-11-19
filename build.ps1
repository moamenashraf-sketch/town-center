# Town Center ad pages: static page generator (PowerShell 5.1+, no dependencies).
# Reads categories.json + units.json + lp-src/*, writes lp/ (AR) and lp/en/ (EN), plus 404.html.
# Usage (from the repo root):   powershell -ExecutionPolicy Bypass -File build.ps1
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding $false

function Read-Text($p) { [IO.File]::ReadAllText($p, [Text.Encoding]::UTF8) }
function Write-Text($p, $s) {
  $dir = Split-Path $p -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
  [IO.File]::WriteAllText($p, $s, $utf8)
}
function Enc($s) { [Net.WebUtility]::HtmlEncode([string]$s) }
# Wrap Latin/number runs in AR text so digits and Latin words keep LTR order and the Latin font.
$latRx = New-Object Text.RegularExpressions.Regex "\+?[A-Za-z0-9][A-Za-z0-9,.+%/&'\-]*(?: [A-Za-z0-9][A-Za-z0-9,.+%/&'\-]*)*"
function Lat($encoded) { $latRx.Replace($encoded, '<span class="lat">$0</span>') }
function Txt($s, $lang) { $e = Enc $s; if ($lang -eq 'ar') { Lat $e } else { $e } }
function Up($n) { ('../' * $n) }

$cfg    = (Read-Text (Join-Path $root 'categories.json')) | ConvertFrom-Json
# foreach unrolls the array that Windows PowerShell 5.1 returns as a single object (also handles "[]")
$units  = @(foreach ($u in ((Read-Text (Join-Path $root 'units.json')) | ConvertFrom-Json)) { $u })
$tpl    = Read-Text (Join-Path $root 'lp-src\template.html')
$base   = $cfg.meta.baseUrl.TrimEnd('/')
$plainUi = @('brand','errRequired','errMobile','errConsent','errSubmit','callLabel','emailLabel','fSending')

if (-not $cfg.categories -or $cfg.categories.Count -lt 1) { throw 'categories.json has no categories' }
$masters = @($cfg.categories | Where-Object { $_.isMaster })
if ($masters.Count -ne 1) { throw 'Exactly one category must have isMaster = true' }

function Page-Path($lang, $slug, $isMaster) {
  # path from repo root, with trailing slash
  $p = 'lp/'
  if ($lang -eq 'en') { $p += 'en/' }
  if (-not $isMaster) { $p += "$slug/" }
  return $p
}

function Build-Page($lang, $cat) {
  $ui = $cfg.ui.$lang
  $path = Page-Path $lang $cat.slug $cat.isMaster
  $depth = ($path.TrimEnd('/').Split('/')).Count
  $rootRel = Up $depth
  $lpRel = $rootRel + 'lp/'
  $img = $cfg.images.($cat.image)
  if (-not $img) { throw "Category $($cat.slug): unknown image '$($cat.image)'" }

  $other = if ($lang -eq 'ar') { 'en' } else { 'ar' }
  $otherPath = Page-Path $other $cat.slug $cat.isMaster
  $langSwitch = ''
  if ($cfg.meta.showLangSwitch) {
    $langSwitch = '<a class="langsw" href="' + $rootRel + $otherPath + '" hreflang="' + $other + '" lang="' + $other + '">' + (Enc $ui.langSwitchLabel) + '</a>'
  }

  $bullets = @()
  foreach ($b in $cat.bullets) {
    if ($b -is [string]) { $o = $cfg.bulletLibrary.$b; if (-not $o) { throw "Unknown bullet key '$b' in $($cat.slug)" } } else { $o = $b }
    $bullets += '        <li><span>' + (Txt $o.$lang $lang) + '</span></li>'
  }

  $strip = @()
  foreach ($c in $cfg.categories) {
    if ($c.isMaster) { continue }
    if ($c.slug -eq $cat.slug) { $strip += '        <li class="is-current" aria-current="true">' + (Txt $c.label.$lang $lang) + '</li>' }
    else { $strip += '        <li><a href="' + $rootRel + (Page-Path $lang $c.slug $c.isMaster) + '">' + (Txt $c.label.$lang $lang) + '</a></li>' }
  }

  $tenants = @()
  foreach ($a in $cfg.anchors) { $tenants += '        <li><img src="' + $rootRel + 'assets/tenants/' + $a.logo + '.png" alt="' + (Enc $a.$lang) + '" loading="lazy" decoding="async"></li>' }

  $catOpts = @()
  $sel = if ($cat.formValue) { '' } else { ' selected' }
  $catOpts += '              <option value=""' + $sel + '>' + (Enc $ui.fCategoryPlaceholder) + '</option>'
  foreach ($c in $cfg.categories) {
    if ($c.isMaster) { continue }
    $s = if ($c.formValue -eq $cat.formValue -and $cat.formValue) { ' selected' } else { '' }
    $catOpts += '              <option value="' + (Enc $c.formValue) + '"' + $s + '>' + (Enc $c.label.$lang) + '</option>'
  }
  $catOpts += '              <option value="other">' + (Enc $ui.fOther) + '</option>'

  function Opts($list) { ($list | ForEach-Object { '              <option value="' + (Enc $_.v) + '">' + (Enc $_.$lang) + '</option>' }) -join "`n" }

  # Units section (hidden when there is nothing to show)
  $rows = @($units | Where-Object { $cfg.meta.publishTodoUnits -or -not $_.todo })
  $unitsHtml = ''
  if ($rows.Count -gt 0) {
    $tr = foreach ($u in $rows) {
      $badge = if ($u.todo) { '<span class="todo-badge">' + (Enc $ui.todoBadge) + '</span>' } else { '' }
      '            <tr><td>' + (Txt $u.unit $lang) + $badge + '</td><td>' + (Txt $u.zone $lang) + '</td><td>' + (Txt $u.area $lang) + '</td><td>' + (Txt $u.frontage $lang) + '</td><td>' + (Txt $u.handover $lang) + '</td></tr>'
    }
    $anyTodo = @($rows | Where-Object { $_.todo }).Count -gt 0
    $note = if ($anyTodo) { '      <p class="units-note">' + (Enc $ui.unitsNote) + '</p>' + "`n" } else { '' }
    $unitsHtml = "`n  <section class=`"units`">`n    <div class=`"wrap`">`n      <h2>" + (Enc $ui.unitsTitle) + "</h2>`n      <div class=`"tablewrap`">`n        <table>`n          <thead><tr><th scope=`"col`">" + (Enc $ui.colUnit) + '</th><th scope="col">' + (Enc $ui.colZone) + '</th><th scope="col">' + (Enc $ui.colArea) + '</th><th scope="col">' + (Enc $ui.colFrontage) + '</th><th scope="col">' + (Enc $ui.colHandover) + "</th></tr></thead>`n          <tbody>`n" + ($tr -join "`n") + "`n          </tbody>`n        </table>`n      </div>`n" + $note + "    </div>`n  </section>`n"
  }

  $renderTag = if ($img.render) { '<span class="tag-render">' + (Enc $ui.renderTag) + '</span>' } else { '' }
  $canon = $base + '/' + $path
  $tok = @{
    lang = $lang; dir = $(if ($lang -eq 'ar') { 'rtl' } else { 'ltr' }); slug = $cat.slug
    title = (Enc $cat.metaTitle.$lang); description = (Enc $cat.metaDescription.$lang)
    canonical = $canon
    url_ar = $base + '/' + (Page-Path 'ar' $cat.slug $cat.isMaster)
    url_en = $base + '/' + (Page-Path 'en' $cat.slug $cat.isMaster)
    og_image = "$base/assets/lp/og-$($img.file).jpg"
    og_locale = $(if ($lang -eq 'ar') { 'ar_SA' } else { 'en_US' })
    root = $rootRel; lproot = $lpRel
    lang_switch = $langSwitch
    headline = (Txt $cat.headline.$lang $lang); sub = (Txt $cat.sub.$lang $lang)
    hero_img = $rootRel + "assets/lp/hero-$($img.file).jpg"; hero_alt = (Enc $img.alt.$lang); render_tag = $renderTag
    bullets = ($bullets -join "`n"); strip = ($strip -join "`n"); tenants = ($tenants -join "`n")
    units_section = $unitsHtml
    category_options = ($catOpts -join "`n")
    branch_options = (Opts $cfg.options.branches); area_options = (Opts $cfg.options.area); opening_options = (Opts $cfg.options.opening)
    fact_residents = $cfg.facts.residents; fact_homes = $cfg.facts.homes; fact_commercialPct = $cfg.facts.commercialPct
  }
  foreach ($p in $ui.PSObject.Properties) {
    $tok['ui_' + $p.Name] = $(if ($plainUi -contains $p.Name) { Enc $p.Value } else { Txt $p.Value $lang })
  }

  $out = [regex]::Replace($tpl, '\{\{(\w+)\}\}', {
    param($m)
    $k = $m.Groups[1].Value
    if (-not $tok.ContainsKey($k)) { throw "Template token {{$k}} has no value (page $path)" }
    [string]$tok[$k]
  })
  $file = Join-Path $root ($path.Replace('/', '\') + 'index.html')
  Write-Text $file $out
  return $path
}

$built = @()
foreach ($lang in @('ar','en')) { foreach ($cat in $cfg.categories) { $built += (Build-Page $lang $cat) } }

# Shared assets for the pages
Copy-Item (Join-Path $root 'lp-src\lp.css') (Join-Path $root 'lp\lp.css') -Force
Copy-Item (Join-Path $root 'lp-src\lp.js')  (Join-Path $root 'lp\lp.js')  -Force

# 404.html: unknown /lp/... paths fall back to the master page (GitHub Pages serves this file for missing URLs)
$p404 = @'
<!DOCTYPE html>
<html lang="ar" dir="rtl"><head><meta charset="UTF-8" /><meta name="viewport" content="width=device-width, initial-scale=1" /><meta name="robots" content="noindex" /><title>Town Center</title>
<script>
(function(){var p=location.pathname,i=p.indexOf('/lp/');
 if(i>-1){var rest=p.slice(i+4),en=/^en(\/|$)/.test(rest);location.replace(p.slice(0,i)+(en?'/lp/en/':'/lp/')+location.search+location.hash);}})();
</script></head>
<body style="font-family:sans-serif;text-align:center;padding:3rem"><p><a href="./lp/">Town Center</a></p></body></html>
'@
Write-Text (Join-Path $root '404.html') $p404

"Built $($built.Count) pages:"
$built | ForEach-Object { '  ' + $_ }
