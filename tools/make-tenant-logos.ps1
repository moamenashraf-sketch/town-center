# Crops whitespace around the tenant logos supplied by the client and writes assets/tenants/*.png
Add-Type -AssemblyName System.Drawing
$src = $args[0]; $out = Join-Path $PSScriptRoot '..\assets\tenants'
$map = [ordered]@{ 'aster'='3'; 'tamimi'='4'; 'pizza-hut'='5'; 'happy-fitness'='6'; 'funquest'='15' }
foreach ($k in $map.Keys) {
  $bmp = New-Object Drawing.Bitmap (Join-Path $src ($map[$k] + '.png'))
  $w=$bmp.Width; $h=$bmp.Height
  $x0=0;$y0=0;$x1=$w-1;$y1=$h-1
  $minx=$w;$miny=$h;$maxx=0;$maxy=0
  $m = if ($k -eq 'tamimi') { 30 } else { 0 }
  for ($y=$m;$y -lt $h-$m;$y++){ for($x=$m;$x -lt $w-$m;$x++){
    $c=$bmp.GetPixel($x,$y)
    if ($c.A -gt 40 -and ($c.R -lt 235 -or $c.G -lt 235 -or $c.B -lt 235)) { if($x -lt $minx){$minx=$x}; if($x -gt $maxx){$maxx=$x}; if($y -lt $miny){$miny=$y}; if($y -gt $maxy){$maxy=$y} } } }
  $pad=6; $minx=[Math]::Max(0,$minx-$pad);$miny=[Math]::Max(0,$miny-$pad);$maxx=[Math]::Min($w-1,$maxx+$pad);$maxy=[Math]::Min($h-1,$maxy+$pad)
  $rect = New-Object Drawing.Rectangle $minx,$miny,($maxx-$minx+1),($maxy-$miny+1)
  $crop = $bmp.Clone($rect, $bmp.PixelFormat)
  $crop.Save((Join-Path $out ($k + '.png')), [Drawing.Imaging.ImageFormat]::Png)
  "{0}: {1}x{2} -> {3}x{4}" -f $k,$w,$h,$rect.Width,$rect.Height
  $crop.Dispose(); $bmp.Dispose()
}
