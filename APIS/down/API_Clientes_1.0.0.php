<?php
header('Content-Type: application/json; charset=utf-8');
// Permitir solicitudes desde cualquier origen
header('Access-Control-Allow-Origin: *');
// o específicamente desde tu dominio
// header('Access-Control-Allow-Origin: http://localhost:3000');

header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

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

    // 🔹 Consulta SQL para obtener todos los clientes 🔹
    $query = "SELECT id, display_name, user_registered, user_email  FROM wp8e_users";
    $stmt = $pdo->query($query);
    $clientes = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // 🔹 Respuesta en JSON 🔹
    echo json_encode(['success' => true, 'data' => $clientes]);

} catch (Exception $e) {
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
