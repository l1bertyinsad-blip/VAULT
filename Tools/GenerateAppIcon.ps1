Add-Type -AssemblyName System.Drawing

$output = Join-Path $PSScriptRoot "..\VAULT\Resources\Assets.xcassets\AppIcon.appiconset\AppIcon-1024.png"
$bitmap = [System.Drawing.Bitmap]::new(1024, 1024)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.Clear([System.Drawing.Color]::FromArgb(30, 14, 55))

function RoundedPath([float]$x, [float]$y, [float]$w, [float]$h, [float]$r) {
    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $d = $r * 2
    $path.AddArc($x, $y, $d, $d, 180, 90)
    $path.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $path.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $path.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $path.CloseFigure()
    return $path
}

$blue = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(38, 126, 245))
$yellow = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(250, 183, 25))
$pink = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(243, 35, 132))
$purple = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(131, 55, 238))
$white = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)

$graphics.FillPath($blue, (RoundedPath 260 180 504 250 54))
$graphics.FillPath($yellow, (RoundedPath 225 225 574 250 54))
$graphics.FillPath($pink, (RoundedPath 190 270 644 250 54))
$graphics.FillPath($purple, (RoundedPath 135 330 754 500 70))

$bookmark = [System.Drawing.Drawing2D.GraphicsPath]::new()
$bookmark.AddLine(416, 490, 608, 490)
$bookmark.AddLine(608, 700, 512, 638)
$bookmark.AddLine(416, 700, 416, 490)
$bookmark.CloseFigure()
$graphics.FillPath($white, $bookmark)

$bitmap.Save($output, [System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$bitmap.Dispose()
