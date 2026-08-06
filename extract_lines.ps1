$lines = Get-Content 'lib/features/admin/products/screens/add_product_screen.dart'
$start = [int]$args[0]
$end = [int]$args[1]
$out = @()
for ($i = $start; $i -le $end -and $i -le $lines.Length; $i++) {
    $out += '{0}: {1}' -f $i, $lines[$i-1]
}
$out | Set-Content -Path 'extract_out.txt'