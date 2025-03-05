<?php
header('Content-Type: application/json; charset=utf-8');

// ⚠️ Desactivar errores en producción (ajusta según sea necesario)
ini_set('display_errors', 0);
ini_set('display_startup_errors', 0);
error_reporting(0); // ⚠️ En producción usa 0, en desarrollo usa E_ALL

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

    // ✅ VALIDACIÓN DE LICENCIA
    if (!isset($_GET['licencia']) || empty($_GET['licencia'])) {
        handleError("Licencia es requerida");
    }

    $licencia = trim($_GET['licencia']); // Ahora está definida antes de usarse

    // 🔍 Buscar la licencia en la base de datos
    $stmt = $pdo->prepare("SELECT id, id_cuenta FROM tn1_licencias WHERE licencia = ? LIMIT 1");
    $stmt->execute([$licencia]);
    $licenciaData = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($licenciaData) {
        echo json_encode([
            'success' => true,
            'id_licencia' => $licenciaData['id'],
            'id_cuenta' => $licenciaData['id_cuenta'],
            'message' => "Licencia válida"
        ]);
    } else {
        handleError("Licencia inválida.");
    }
} catch (PDOException $e) {
    error_log("Error en la base de datos: " . $e->getMessage()); // Guarda el error en el log
    handleError("Error en la base de datos, intenta más tarde.");
}
?>
