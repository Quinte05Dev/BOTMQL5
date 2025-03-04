<?php
header('Content-Type: application/json; charset=utf-8');
// Permitir solicitudes desde cualquier origen
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// 🔹 Habilitar visualización de errores para depuración 🔹
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// 🔹 Importar configuración de la base de datos 🔹
$wp_config_path = '/home/bfunded/public_html/bts/Dashboard/dbweb-config.php';
if (!file_exists($wp_config_path)) {
    die(json_encode(['success' => false, 'error' => 'Configuración de BD no encontrada']));
}
require_once($wp_config_path);

try {
    // Conectar a la base de datos usando PDO
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASSWORD);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // 🔹 Verificar si se pasó un ID de usuario por GET 🔹
    $id_usuario = $_GET['id_usuario'] ?? null;
    
    // 🔹 Endpoint de cuentas (para obtener portafolio_general) 🔹
    $api_cuentas_url = "https://bfunded.co/bts/Dashboard/down/API_Cuentas_1.1.0.php";
    if ($id_usuario) {
        $api_cuentas_url .= "?id_usuario=" . urlencode($id_usuario);
    }

    // 🔹 Obtener portafolio_general de la API de cuentas 🔹
    $response = file_get_contents($api_cuentas_url);
    $cuentas_data = json_decode($response, true);

    // Si la API respondió correctamente, obtenemos portafolio_general
    $portafolio_general = isset($cuentas_data['portafolio_general']) ? floatval($cuentas_data['portafolio_general']) : 0.00;

    // 🔹 Consultar operaciones en la BD 🔹
    if ($id_usuario) {
        $query = "SELECT o.id, o.setfile_id, o.tipo, o.volumen, o.precio_entrada, 
                         o.precio_salida, o.ganancia, o.pips, o.fecha_apertura, o.fecha_cierre
                  FROM wp8e_operaciones o
                  INNER JOIN wp8e_setfiles sf ON o.setfile_id = sf.id
                  INNER JOIN wp8e_activos a ON sf.par_id = a.id
                  INNER JOIN wp8e_cuentas c ON a.cuenta_id = c.id
                  INNER JOIN wp8e_usuarios_licencias l ON c.licencia_id = l.id_registro
                  WHERE l.id_usuario = :id_usuario";
        $stmt = $pdo->prepare($query);
        $stmt->execute([':id_usuario' => $id_usuario]);
    } else {
        $query = "SELECT o.id, o.setfile_id, o.tipo, o.volumen, o.precio_entrada, 
                         o.precio_salida, o.ganancia, o.pips, o.fecha_apertura, o.fecha_cierre
                  FROM wp8e_operaciones o";
        $stmt = $pdo->query($query);
    }

    $operaciones = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // 🔹 Calcular ganancia total y asegurar que sea float 🔹
    $ganancia_total = isset($operaciones) ? array_sum(array_column($operaciones, 'ganancia')) : 0.00;
    $ganancia_total = floatval($ganancia_total);

    // 🔹 Calcular rentabilidad_general 🔹
    $rentabilidad_general = ($portafolio_general > 0) ? ($ganancia_total / $portafolio_general) * 100 : 0.00;
    $rentabilidad_general = floatval($rentabilidad_general);

    // 🔹 Formatear valores correctamente 🔹
    $ganancia_total = number_format($ganancia_total, 2, '.', '');
    $portafolio_general = number_format($portafolio_general, 2, '.', '');
    $rentabilidad_general = number_format($rentabilidad_general, 2, '.', '');

    // 🔹 Respuesta en JSON 🔹
    echo json_encode([
        'success' => true,
        'ganancia_total' => $ganancia_total,
        'portafolio_general' => $portafolio_general,
        'rentabilidad_general' => $rentabilidad_general,
        'operaciones' => $operaciones
    ]);

} catch (Exception $e) {
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
