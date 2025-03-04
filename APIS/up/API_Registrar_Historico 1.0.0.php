<?php
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

$wp_config_path = '/home/bfunded/public_html/bts/Dashboard/dbweb-config.php';
if (!file_exists($wp_config_path)) {
    die(json_encode(['success' => false, 'error' => 'Configuración de BD no encontrada']));
}
require_once($wp_config_path);

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASSWORD);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Recibir JSON
    $jsonContent = file_get_contents('php://input');
    if (!$jsonContent) {
        throw new Exception('No se recibió el JSON.');
    }

    // Decodificar JSON
    $data = json_decode($jsonContent, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        throw new Exception('Error al decodificar JSON: ' . json_last_error_msg());
    }

    // 🔹 **Validar que `cuenta_id` y `operaciones` sean correctos**
    if (!isset($data['cuenta_id']) || !is_numeric($data['cuenta_id'])) {
        throw new Exception('El campo "cuenta_id" es obligatorio y debe ser numérico.');
    }

    if (!isset($data['operaciones']) || !is_array($data['operaciones'])) {
        throw new Exception('El campo "operaciones" es obligatorio y debe ser un array.');
    }

    $operacionesInsertadas = 0;

    foreach ($data['operaciones'] as $operacion) {
        // Validar campos requeridos
        $required_fields = ['tipo', 'volumen', 'precio_entrada', 'precio_salida', 'ganancia', 'activo', 'fecha_apertura', 'fecha_cierre', 'ticket'];
        foreach ($required_fields as $field) {
            if (!isset($operacion[$field])) {
                throw new Exception("Falta el campo obligatorio: $field en una operación.");
            }
        }

        // Validar tipo de operación
        if (!in_array($operacion['tipo'], ['compra', 'venta','DEAL_TYPE_BUY','DEAL_TYPE_SELL'])) {
            throw new Exception('El campo "tipo" debe ser "compra" o "venta", "DEAL_TYPE_BUY", "DEAL_TYPE_SELL".');
        }

        // Validar valores numéricos
        $numeric_fields = ['volumen', 'precio_entrada', 'precio_salida', 'ganancia', 'comision', 'swap'];
        foreach ($numeric_fields as $field) {
            if (isset($operacion[$field]) && !is_numeric($operacion[$field])) {
                throw new Exception("El campo $field debe ser numérico.");
            }
        }

        // Validar formato de fecha
        $fecha_apertura = date('Y-m-d H:i:s', strtotime($operacion['fecha_apertura']));
        $fecha_cierre = date('Y-m-d H:i:s', strtotime($operacion['fecha_cierre']));
        if (!$fecha_apertura || !$fecha_cierre) {
            throw new Exception('Formato de fecha inválido.');
        }

        // 🔹 **Paso 1: Buscar el ID del activo en `wp8e_activos`**
        $queryActivo = "SELECT id FROM wp8e_activos WHERE simbolo = :simbolo LIMIT 1";
        $stmt = $pdo->prepare($queryActivo);
        $stmt->execute([':simbolo' => $operacion['activo']]);
        $idActivo = $stmt->fetchColumn();

        // 🔹 **Si el activo no existe, lo creamos en `wp8e_activos`**
        if (!$idActivo) {
            $queryInsertActivo = "INSERT INTO wp8e_activos (simbolo) VALUES (:simbolo)";
            $stmt = $pdo->prepare($queryInsertActivo);
            $stmt->execute([':simbolo' => $operacion['activo']]);
            $idActivo = $pdo->lastInsertId(); // Obtenemos el ID del nuevo activo creado
        }

        // 🔹 **Paso 2: Asignar setfile_id con el valor fijo `1`**
        $setfileId = 1;

        // 🔹 **Paso 3: Verificar si la operación ya existe en `wp8e_operaciones`**
        $queryCheckOperacion = "SELECT COUNT(*) FROM wp8e_operaciones 
                                WHERE cuenta_id = :cuenta_id 
                                AND ticket = :ticket";
        $stmt = $pdo->prepare($queryCheckOperacion);
        $stmt->execute([
            ':cuenta_id' => $data['cuenta_id'],
            ':ticket' => $operacion['ticket']
        ]);

        if ($stmt->fetchColumn()) {
            continue; // Si ya existe, pasamos a la siguiente operación
        }

        // 🔹 **Paso 4: Insertar la operación en `wp8e_operaciones`**
        $queryInsertOperacion = "INSERT INTO wp8e_operaciones 
            (cuenta_id, activo_id, setfile_id, tipo, volumen, precio_entrada, precio_salida, ganancia, fecha_apertura, fecha_cierre, 
            ticket, comision, swap, orden_id, posicion_id, comentario) 
            VALUES 
            (:cuenta_id, :activo_id, :setfile_id, :tipo, :volumen, :precio_entrada, :precio_salida, :ganancia, :fecha_apertura, :fecha_cierre, 
            :ticket, :comision, :swap, :orden_id, :posicion_id, :comentario)";

        $stmt = $pdo->prepare($queryInsertOperacion);
        $stmt->execute([
            ':cuenta_id' => $data['cuenta_id'],
            ':activo_id' => $idActivo,
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
            ':posicion_id' => $operacion['posicion_id'] ?? null,
            ':comentario' => $operacion['comentario'] ?? null
        ]);

        $operacionesInsertadas++;
    }

    echo json_encode(['success' => true, 'operaciones_insertadas' => $operacionesInsertadas]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
