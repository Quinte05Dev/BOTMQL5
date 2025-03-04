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

    // Validar que los campos requeridos estén presentes
    $required_fields = ['cuenta_id', 'setfile_id', 'tipo', 'volumen', 'precio_entrada', 'precio_salida', 'ganancia', 'fecha_apertura', 'fecha_cierre', 'ticket'];
    foreach ($required_fields as $field) {
        if (!isset($data[$field])) {
            throw new Exception("Falta el campo obligatorio: $field");
        }
    }

    // // Validar que el tipo sea "compra" o "venta"
    // if (!in_array($operacion['tipo'], ['compra', 'venta','DEAL_TYPE_BUY','DEAL_TYPE_SELL'])) {
    //     throw new Exception('El campo "tipo" debe ser "compra" o "venta", "DEAL_TYPE_BUY", "DEAL_TYPE_SELL".');
    // }

    // Validar valores numéricos
    $numeric_fields = ['volumen', 'precio_entrada', 'precio_salida', 'ganancia', 'comision', 'swap'];
    foreach ($numeric_fields as $field) {
        if (isset($data[$field]) && !is_numeric($data[$field])) {
            throw new Exception("El campo $field debe ser numérico.");
        }
    }

    // Validar formato de fecha
    $fecha_apertura = date('Y-m-d H:i:s', strtotime($data['fecha_apertura']));
    $fecha_cierre = date('Y-m-d H:i:s', strtotime($data['fecha_cierre']));
    if (!$fecha_apertura || !$fecha_cierre) {
        throw new Exception('Formato de fecha inválido.');
    }

    // **✅ Validar existencia de cuenta_id**
    $queryCheckCuenta = "SELECT COUNT(*) FROM wp8e_cuentas WHERE id = :cuenta_id";
    $stmt = $pdo->prepare($queryCheckCuenta);
    $stmt->execute([':cuenta_id' => $data['cuenta_id']]);
    if (!$stmt->fetchColumn()) {
        throw new Exception("La cuenta_id proporcionada ({$data['cuenta_id']}) no existe.");
    }

    // // **✅ Validar existencia de activo_id**
    // $queryCheckActivo = "SELECT COUNT(*) FROM wp8e_activos WHERE id = :activo_id";
    // $stmt = $pdo->prepare($queryCheckActivo);
    // $stmt->execute([':activo_id' => $data['activo_id']]);
    // if (!$stmt->fetchColumn()) {
    //     throw new Exception("El activo_id proporcionado ({$data['activo_id']}) no existe.");
    // }

    // **✅ Validar existencia de setfile_id**
    $queryCheckSetfile = "SELECT COUNT(*) FROM wp8e_setfiles WHERE id = :setfile_id";
    $stmt = $pdo->prepare($queryCheckSetfile);
    $stmt->execute([':setfile_id' => $data['setfile_id']]);
    if (!$stmt->fetchColumn()) {
        throw new Exception("El setfile_id proporcionado ({$data['setfile_id']}) no existe.");
    }

    
    // 🔹 **Paso 1: Buscar el ID del activo en `wp8e_activos`**
    $queryActivo = "SELECT id FROM wp8e_activos WHERE simbolo = :simbolo LIMIT 1";
    $stmt = $pdo->prepare($queryActivo);
    $stmt->execute([':simbolo' => $data['activo']]);
    $idActivo = $stmt->fetchColumn();

    // 🔹 **Si el activo no existe, lo creamos en `wp8e_activos`**
    if (!$idActivo) {
        $queryInsertActivo = "INSERT INTO wp8e_activos (simbolo) VALUES (:simbolo)";
        $stmt = $pdo->prepare($queryInsertActivo);
        $stmt->execute([':simbolo' => $data['activo']]);
        $idActivo = $pdo->lastInsertId(); // Obtenemos el ID del nuevo activo creado
    }

    // **✅ Validar si la operación ya existe**
    $queryCheckOperacion = "SELECT COUNT(*) FROM wp8e_operaciones 
                            WHERE cuenta_id = :cuenta_id  
                            AND ticket = :ticket";
    $stmt = $pdo->prepare($queryCheckOperacion);
    $stmt->execute([
        ':cuenta_id' => $data['cuenta_id'],
        ':ticket' => $data['ticket']
    ]);

    if ($stmt->fetchColumn()) {
        echo json_encode(['success' => false, 'mensaje' => 'La operación ya existe en la base de datos.']);
        exit;
    }

    // **✅ Insertar nueva operación**
    $queryInsert = "INSERT INTO wp8e_operaciones 
        (cuenta_id, activo_id, setfile_id, tipo, volumen, precio_entrada, precio_salida, ganancia, fecha_apertura, fecha_cierre, 
        ticket, comision, swap, orden_id, posicion_id, comentario) 
        VALUES 
        (:cuenta_id, :activo_id, :setfile_id, :tipo, :volumen, :precio_entrada, :precio_salida, :ganancia, :fecha_apertura, :fecha_cierre, 
        :ticket, :comision, :swap, :orden_id, :posicion_id, :comentario)";

    $stmt = $pdo->prepare($queryInsert);
    $stmt->execute([
        ':cuenta_id' => $data['cuenta_id'],
        ':activo_id' => $idActivo,
        ':setfile_id' => $data['setfile_id'],
        ':tipo' => $data['tipo'],
        ':volumen' => $data['volumen'],
        ':precio_entrada' => $data['precio_entrada'],
        ':precio_salida' => $data['precio_salida'],
        ':ganancia' => $data['ganancia'],
        ':fecha_apertura' => $fecha_apertura,
        ':fecha_cierre' => $fecha_cierre,
        ':ticket' => $data['ticket'],
        ':comision' => $data['comision'] ?? null,
        ':swap' => $data['swap'] ?? null,
        ':orden_id' => $data['orden_id'] ?? null,
        ':posicion_id' => $data['posicion_id'] ?? null,
        ':comentario' => $data['comentario'] ?? null
    ]);

    echo json_encode(['success' => true, 'mensaje' => 'Operación guardada correctamente.']);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
