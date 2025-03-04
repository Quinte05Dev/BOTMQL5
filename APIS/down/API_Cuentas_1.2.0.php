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

    // 🔹 Verificar que la conexión a la BD es válida 🔹
    if (!$pdo) {
        die(json_encode(['success' => false, 'error' => 'Fallo en la conexión a la BD']));
    }

    // 🔹 Verificar si se pasó un ID de usuario por GET 🔹
    $id_usuario = $_GET['id_usuario'] ?? null;

    if ($id_usuario) {
        // Endpoint: Obtener las cuentas de un usuario específico
        $query = "SELECT c.id, c.licencia_id, c.broker, c.tipo_cuenta, c.es_demo, 
                         c.empresa_fondeo, c.balance, c.drawdown, c.net_profit, 
                         c.fecha_creacion, c.estado
                  FROM wp8e_cuentas c
                  INNER JOIN wp8e_usuarios_licencias l ON c.licencia_id = l.id_registro
                  WHERE l.id_usuario = :id_usuario";
        $stmt = $pdo->prepare($query);
        $stmt->execute([':id_usuario' => $id_usuario]);
    } else {
        // Endpoint: Obtener el listado de todas las cuentas
        $query = "SELECT c.id, c.licencia_id, c.broker, c.tipo_cuenta, c.es_demo, 
                         c.empresa_fondeo, c.balance, c.drawdown, c.net_profit, 
                         c.fecha_creacion, c.estado
                  FROM wp8e_cuentas c";
        $stmt = $pdo->query($query);
    }

    $cuentas = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // 🔹 Calcular cantidad de cuentas 🔹
    $cantidad_cuentas = count($cuentas);

    // 🔹 Calcular el portafolio general 🔹
    $portafolio_general = array_sum(array_column($cuentas, 'balance'));

    // 🔹 Formatear valores correctamente 🔹
    $portafolio_general = number_format($portafolio_general, 2, '.', '');

    // 🔹 Respuesta en JSON 🔹
    echo json_encode([
        'success' => true,
        'cantidad_cuentas' => $cantidad_cuentas,
        'portafolio_general' => $portafolio_general,
        'cuentas' => $cuentas
    ]);

} catch (Exception $e) {
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
