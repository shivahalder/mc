<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$url = "http://217.216.40.184:8805/server/Server%201/players";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 10);
$html = curl_exec($ch);
curl_close($ch);

$players = [];
if ($html) {
    preg_match_all('/<tr[^>]*>.*?<td[^>]*>([^<]+)<\/td>.*?<td[^>]*>([^<]+)<\/td>.*?<td[^>]*>([^<]+)<\/td>/s', $html, $rows);
    if (isset($rows[1])) {
        for ($i = 0; $i < count($rows[1]); $i++) {
            $name = trim($rows[1][$i]);
            $playtime = trim($rows[3][$i]);
            if ($name && !preg_match('/^(Name|Rank|Player)/i', $name)) {
                $players[] = ['name' => $name, 'time' => $playtime];
            }
        }
    }
}

echo json_encode($players);
?>
