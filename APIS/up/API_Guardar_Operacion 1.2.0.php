<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

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

    // **🔹 Validar estructura del JSON**
    if (!isset($data['cuenta_id'], $data['setfile_id'], $data['activo_id'], $data['operaciones']) || !is_array($data['operaciones'])) {
        throw new Exception('El JSON debe incluir "cuenta_id", "setfile_id", "activo_id" y un array de "operaciones".');
    }

    $cuentaId = $data['cuenta_id'];
    $setfileId = $data['setfile_id'];
    $activoId = $data['activo_id'];
    $operacionesInsertadas = 0;
    $operacionesOmitidas = 0;

    // **🔹 Validar existencia de cuenta, setfile y activo en la base de datos**
    $queries = [
        'cuenta'  => "SELECT COUNT(*) FROM wp8e_cuentas WHERE id = :id",
        'setfile' => "SELECT COUNT(*) FROM wp8e_setfiles WHERE id = :id",
        'activo'  => "SELECT COUNT(*) FROM wp8e_activos WHERE id = :id"
    ];

    foreach ($queries as $key => $query) {
        $stmt = $pdo->prepare($query);
        $stmt->execute([':id' => $$key . 'Id']);
        if (!$stmt->fetchColumn()) {
            throw new Exception("El {$key}_id proporcionado ({$$key . 'Id'}) no existe.");
        }
    }

    foreach ($data['operaciones'] as $operacion) {
        // **🔹 Validar campos requeridos en cada operación**
        $required_fields = ['tipo', 'volumen', 'precio_entrada', 'precio_salida', 'ganancia', 'fecha_apertura', 'fecha_cierre', 'ticket'];
        foreach ($required_fields as $field) {
            if (!isset($operacion[$field])) {
                throw new Exception("Falta el campo obligatorio: $field en una operación.");
            }
        }

        // **🔹 Validar valores numéricos**
        $numeric_fields = ['volumen', 'precio_entrada', 'precio_salida', 'ganancia', 'comision', 'swap', 'orden_id', 'magic_number'];
        foreach ($numeric_fields as $field) {
            if (isset($operacion[$field]) && !is_numeric($operacion[$field])) {
                throw new Exception("El campo $field debe ser numérico.");
            }
        }

        // **🔹 Validar formato de fechas**
        $fecha_apertura = date('Y-m-d H:i:s', strtotime($operacion['fecha_apertura']));
        $fecha_cierre = date('Y-m-d H:i:s', strtotime($operacion['fecha_cierre']));
        if (!$fecha_apertura || !$fecha_cierre) {
            throw new Exception('Formato de fecha inválido.');
        }

        // **🔹 Verificar si la operación ya existe en `wp8e_operaciones`**
        $queryCheckOperacion = "SELECT COUNT(*) FROM wp8e_operaciones 
                                WHERE cuenta_id = :cuenta_id 
                                AND ticket = :ticket";
        $stmt = $pdo->prepare($queryCheckOperacion);
        $stmt->execute([
            ':cuenta_id' => $cuentaId,
            ':ticket' => $operacion['ticket']
        ]);

        if ($stmt->fetchColumn()) {
            $operacionesOmitidas++;
            continue; // Si ya existe, la omitimos
        }

        // **🔹 Insertar la operación en `wp8e_operaciones`**
        $queryInsertOperacion = "INSERT INTO wp8e_operaciones 
            (cuenta_id, activo_id, setfile_id, tipo, volumen, precio_entrada, precio_salida, ganancia, fecha_apertura, fecha_cierre, 
            ticket, comision, swap, orden_id, comentario, magic_number) 
            VALUES 
            (:cuenta_id, :activo_id, :setfile_id, :tipo, :volumen, :precio_entrada, :precio_salida, :ganancia, :fecha_apertura, :fecha_cierre, 
            :ticket, :comision, :swap, :orden_id, :comentario, :magic_number)";

        $stmt = $pdo->prepare($queryInsertOperacion);
        $stmt->execute([
            ':cuenta_id' => $cuentaId,
            ':activo_id' => $activoId,
            ':setfile_id' => $setfileId,
            ':tipo' => $operacion['tipo'],
            ':volumen' => $operacion['volumen'],
            ':precio_entrada' => $operacion['precio_entrada'],
            ':precio_salida' => $operacion['precio_salida'],
            ':ganancia' => $operacion['ganancia'],
            ':fecha_apertura' => $fecha_apertura,
            ':fecha_cierre' => $fecha_cierre,
            ':ticket' => $operacion['ticket'],
            ':comision' => $operacion['comision'] ?? null,
            ':swap' => $operacion['swap'] ?? null,
            ':orden_id' => $operacion['orden_id'] ?? null,
            ':comentario' => $operacion['comentario'] ?? null,
            ':magic_number' => $operacion['magic_number'] ?? null
        ]);

        $operacionesInsertadas++;
    }

    echo json_encode([
        'success' => true,
        'operaciones_insertadas' => $operacionesInsertadas,
        'operaciones_omitidas' => $operacionesOmitidas
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
