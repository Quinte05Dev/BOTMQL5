<?php
header('Content-Type: application/json; charset=utf-8');

// Importar configuración de la base de datos
$wp_config_path = '/home/bfunded/public_html/bts/Dashboard/dbweb-config.php';
if (!file_exists($wp_config_path)) {
    die(json_encode(['success' => false, 'error' => 'Configuración de BD no encontrada']));
}
require_once($wp_config_path);

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASSWORD);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Recibir JSON de la solicitud
    $jsonContent = file_get_contents('php://input');
    if (!$jsonContent) {
        throw new Exception('No se recibió el JSON.');
    }

    // Decodificar JSON
    $data = json_decode($jsonContent, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        throw new Exception('Error al decodificar JSON: ' . json_last_error_msg());
    }

    // Validar los datos requeridos en la tabla operaciones
    $required_fields = ['setfile_id', 'tipo', 'volumen', 'precio_entrada', 'precio_salida', 'ganancia', 'pips', 'fecha_apertura', 'fecha_cierre'];
    foreach ($required_fields as $field) {
        if (!isset($data[$field])) {
            throw new Exception("Falta el campo obligatorio: $field");
        }
    }

    // Validar que el tipo sea "compra" o "venta"
    if (!in_array($data['tipo'], ['compra', 'venta'])) {
        throw new Exception('El campo "tipo" debe ser "compra" o "venta".');
    }

    // Validar valores numéricos
    if (!is_numeric($data['volumen']) || !is_numeric($data['precio_entrada']) || !is_numeric($data['precio_salida']) || 
        !is_numeric($data['ganancia']) || !is_numeric($data['pips'])) {
        throw new Exception('Los valores de volumen, precio_entrada, precio_salida, ganancia y pips deben ser numéricos.');
    }

    // Validar formato de fecha
    $fecha_apertura = date('Y-m-d H:i:s', strtotime($data['fecha_apertura']));
    $fecha_cierre = date('Y-m-d H:i:s', strtotime($data['fecha_cierre']));
    if (!$fecha_apertura || !$fecha_cierre) {
        throw new Exception('Formato de fecha inválido.');
    }

    // Verificar si la operación ya existe en la BD
    $queryCheck = "SELECT COUNT(*) FROM wp8e_operaciones WHERE setfile_id = :setfile_id 
                    AND tipo = :tipo 
                    AND fecha_apertura = :fecha_apertura 
                    AND fecha_cierre = :fecha_cierre";
    $stmt = $pdo->prepare($queryCheck);
    $stmt->execute([
        ':setfile_id' => $data['setfile_id'],
        ':tipo' => $data['tipo'],
        ':fecha_apertura' => $fecha_apertura,
        ':fecha_cierre' => $fecha_cierre
    ]);
    $existe = $stmt->fetchColumn();

    if (!$existe) {
        // Insertar nueva operación
        $queryInsert = "INSERT INTO wp8e_operaciones (setfile_id, tipo, volumen, precio_entrada, precio_salida, ganancia, pips, fecha_apertura, fecha_cierre) 
                        VALUES (:setfile_id, :tipo, :volumen, :precio_entrada, :precio_salida, :ganancia, :pips, :fecha_apertura, :fecha_cierre)";
        $stmt = $pdo->prepare($queryInsert);
        $stmt->execute([
            ':setfile_id' => $data['setfile_id'],
            ':tipo' => $data['tipo'],
            ':volumen' => $data['volumen'],
            ':precio_entrada' => $data['precio_entrada'],
            ':precio_salida' => $data['precio_salida'],
            ':ganancia' => $data['ganancia'],
            ':pips' => $data['pips'],
            ':fecha_apertura' => $fecha_apertura,
            ':fecha_cierre' => $fecha_cierre
        ]);

        echo json_encode(['success' => true, 'mensaje' => 'Operación guardada correctamente.']);
    } else {
        echo json_encode(['success' => false, 'mensaje' => 'La operación ya existe en la base de datos.']);
    }

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
