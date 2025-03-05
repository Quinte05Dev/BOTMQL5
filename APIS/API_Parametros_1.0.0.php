<?php
header('Content-Type: application/json; charset=utf-8');

// Habilitar errores para depuración (desactivar en producción)
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Función para manejar errores y responder con JSON
function handleError($message) {
    echo json_encode([
        'success' => false,
        'message' => $message
    ]);
    exit;
}

// Cargar configuración de la base de datos
$wp_config_path = '/home/tradingnote/public_html/app/api/dbweb-config.php';
if (!file_exists($wp_config_path)) {
    handleError("Error de configuración: dbweb-config.php no encontrado");
}
require_once($wp_config_path);

try {
    // Conexión a la base de datos con PDO
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASSWORD);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // ✅ VALIDACIÓN DE API KEY
    if (!isset($_GET['api_key']) || empty($_GET['api_key'])) {
        handleError("API Key es requerida");
    }

    $api_key = trim($_GET['api_key']);

    // Verificar si la API Key existe en la tabla `apikey`
    $stmt = $pdo->prepare("SELECT id FROM tn1_api_keys WHERE api_key = ? LIMIT 1");
    $stmt->execute([$api_key]);
    $api_key_valid = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$api_key_valid) {
        handleError("API Key inválida o no autorizada");
    }

    // ✅ OBTENER ID (opcional)
    $id = isset($_GET['id']) ? intval($_GET['id']) : null;

    if ($id) {
        // Consultar un solo parámetro por ID
        $stmt = $pdo->prepare("SELECT id, segundos, nombre FROM tn1_parametros WHERE id = ?");
        $stmt->execute([$id]);
        $parametro = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($parametro) {
            echo json_encode([
                'success' => true,
                'data' => $parametro,
                'message' => "Parámetro obtenido correctamente"
            ]);
        } else {
            handleError("No se encontró ningún registro con el ID especificado");
        }
    } else {
        // Consultar todos los parámetros
        $stmt = $pdo->query("SELECT id, segundos, nombre FROM tn1_parametros ORDER BY id ASC");
        $parametros = $stmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode([
            'success' => true,
            'data' => $parametros,
            'message' => "Lista de parámetros obtenida correctamente"
        ]);
    }
} catch (PDOException $e) {
    handleError("Error en la base de datos: " . $e->getMessage());
}
?>
