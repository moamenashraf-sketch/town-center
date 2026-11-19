# Resizes the site photos for the ad pages: hero-<name>.jpg (<=1200 px wide) and og-<name>.jpg (1200x630 crop).
# Run once from the repo root:  powershell -File tools\make-images.ps1
Add-Type -AssemblyName System.Drawing
$root=(Get-Location).Path
$enc=[Drawing.Imaging.ImageCodecInfo]::GetImageEncoders()|?{$_.MimeType -eq 'image/jpeg'}
function Save-Jpg($bmp,$path,$q){ $ep=New-Object Drawing.Imaging.EncoderParameters(1); $ep.Param[0]=New-Object Drawing.Imaging.EncoderParameter([Drawing.Imaging.Encoder]::Quality,[long]$q); $bmp.Save($path,$enc,$ep) }
function Draw-Scaled($src,$w,$h,$cropToFill,$posY){
  $d=New-Object Drawing.Bitmap $w,$h; $g=[Drawing.Graphics]::FromImage($d); $g.InterpolationMode='HighQualityBicubic'; $g.SmoothingMode='HighQuality'; $g.PixelOffsetMode='HighQuality'
  if($cropToFill){ $r=[math]::Max($w/$src.Width,$h/$src.Height); $sw=$w/$r; $sh=$h/$r; $sx=($src.Width-$sw)/2; $sy=($src.Height-$sh)*$posY
    $g.DrawImage($src,(New-Object Drawing.Rectangle 0,0,$w,$h),[single]$sx,[single]$sy,[single]$sw,[single]$sh,[Drawing.GraphicsUnit]::Pixel) }
  else { $g.DrawImage($src,0,0,$w,$h) }
  $g.Dispose(); return $d }
$photos=@{ 'hero'='hero.jpg'; 'signage'='signage.jpg'; 'courtyard'='courtyard.jpg'; 'facade-glass'='facade-glass.jpg'; 'night-portrait'='night-portrait.jpg'; 'tower'='tower.jpg' }
$posY=@{ 'hero'=0.5; 'signage'=0.55; 'courtyard'=0.5; 'facade-glass'=0.55; 'night-portrait'=0.62; 'tower'=0.62 }
foreach($k in $photos.Keys){
  $src=[Drawing.Image]::FromFile((Join-Path $root "assets\$($photos[$k])"))
  # hero: fixed 4:3 crop at 1000x750 (mobile-friendly, small file)
  $h=Draw-Scaled $src 1000 750 $true $posY[$k]; Save-Jpg $h (Join-Path $root "assets\lp\hero-$k.jpg") 76; $h.Dispose()
  $o=Draw-Scaled $src 1200 630 $true $posY[$k]; Save-Jpg $o (Join-Path $root "assets\lp\og-$k.jpg") 80; $o.Dispose()
  $src.Dispose(); "$k ok"
}
