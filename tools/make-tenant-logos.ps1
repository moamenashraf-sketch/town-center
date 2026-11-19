# Crops the tenant logos supplied by the client and writes assets/tenants/*.png
# Usage: make-tenant-logos.ps1 <folder with the client's numbered PNGs>
Add-Type -AssemblyName System.Drawing
$src = $args[0]; $out = Join-Path $PSScriptRoot '..\assets\tenants'
# name = file number, crop mode: white (trim near-white), alpha (trim transparent), none (keep as is), margin = ignore frame px
$map = [ordered]@{
  'aster'=@('3','white',0); 'tamimi'=@('4','white',30); 'pizza-hut'=@('5','white',0); 'happy-fitness'=@('6','white',0); 'funquest'=@('15','white',0)
  'shebbak'=@('7','white',0); 'virgin-mobile'=@('8','alpha',0); 'whoa-tea'=@('9','white',0); 'minis'=@('10','alpha',0)
  '5ive'=@('11','none',0); 'lash-lines'=@('12','alpha',0); 'yello-spa'=@('13','none',0); 'in2'=@('14','alpha',0)
}
foreach ($k in $map.Keys) {
  $f = $map[$k][0]; $mode = $map[$k][1]; $m = $map[$k][2]
  $bmp = New-Object Drawing.Bitmap (Join-Path $src ($f + '.png'))
  $w=$bmp.Width; $h=$bmp.Height
  if ($mode -eq 'none') { $rect = New-Object Drawing.Rectangle 0,0,$w,$h }
  else {
    $minx=$w;$miny=$h;$maxx=0;$maxy=0
    for ($y=$m;$y -lt $h-$m;$y++){ for($x=$m;$x -lt $w-$m;$x++){
      $c=$bmp.GetPixel($x,$y)
      $ink = if ($mode -eq 'alpha') { $c.A -gt 40 } else { $c.A -gt 40 -and ($c.R -lt 235 -or $c.G -lt 235 -or $c.B -lt 235) }
      if ($ink) { if($x -lt $minx){$minx=$x}; if($x -gt $maxx){$maxx=$x}; if($y -lt $miny){$miny=$y}; if($y -gt $maxy){$maxy=$y} } } }
    $pad=6; $minx=[Math]::Max(0,$minx-$pad);$miny=[Math]::Max(0,$miny-$pad);$maxx=[Math]::Min($w-1,$maxx+$pad);$maxy=[Math]::Min($h-1,$maxy+$pad)
    $rect = New-Object Drawing.Rectangle $minx,$miny,($maxx-$minx+1),($maxy-$miny+1)
  }
  $crop = $bmp.Clone($rect, $bmp.PixelFormat)
  $crop.Save((Join-Path $out ($k + '.png')), [Drawing.Imaging.ImageFormat]::Png)
  "{0}: {1}x{2} -> {3}x{4}" -f $k,$w,$h,$rect.Width,$rect.Height
  $crop.Dispose(); $bmp.Dispose()
}
