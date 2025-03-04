<?php
header('Content-Type: application/json; charset=utf-8');

$wp_config_path = '/home/bfunded/public_html/bts/Dashboard/dbweb-config.php';
if (!file_exists($wp_config_path)) {
    die(json_encode(['success' => false, 'error' => 'Configuración de BD no encontrada']));
}
require_once($wp_config_path);

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASSWORD);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $jsonContent = file_get_contents('php://input');
    if (!$jsonContent) {
        throw new Exception('No se recibió el JSON.');
    }

    $data = json_decode($jsonContent, true);
    if (!isset($data['licencia_id'], $data['cuenta'], $data['activos'], $data['setfiles'])) {
        throw new Exception('Datos faltantes.');
    }

    // Validar la licencia
    $stmt = $pdo->prepare("SELECT id_registro FROM wp8e_usuarios_licencias WHERE id_registro = :licencia_id");
    $stmt->execute([':licencia_id' => $data['licencia_id']]);
    $licencia = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$licencia) {
        throw new Exception('ID de licencia inválido.');
    }

    function obtenerOCrearCuenta($pdo, $licencia_id, $cuenta) {
        $stmt = $pdo->prepare("SELECT id FROM wp8e_cuentas WHERE broker = :broker AND numero = :numero");
        $stmt->execute([
            ':broker' => $cuenta['broker'],
            ':numero' => $cuenta['numero']
        ]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($row) {
            return $row['id'];
        } else {
            $stmt = $pdo->prepare("INSERT INTO wp8e_cuentas (licencia_id, broker, tipo_cuenta, numero, es_demo, empresa_fondeo, balance, drawdown, net_profit, estado) 
                                   VALUES (:licencia_id, :broker, :tipo_cuenta, :numero, :es_demo, :empresa_fondeo, :balance, :drawdown, :net_profit, :estado)");
            $stmt->execute([
                ':licencia_id' => $licencia_id,
                ':broker' => $cuenta['broker'],
                ':tipo_cuenta' => $cuenta['tipo_cuenta'],
                ':numero' => $cuenta['numero'],
                ':es_demo' => $cuenta['es_demo'],
                ':empresa_fondeo' => $cuenta['empresa_fondeo'],
                ':balance' => $cuenta['balance'],
                ':drawdown' => $cuenta['drawdown'],
                ':net_profit' => $cuenta['net_profit'],
                ':estado' => $cuenta['estado']
            ]);
            return $pdo->lastInsertId();
        }
    }

    function obtenerOCrearActivo($pdo, $activo) {
        $stmt = $pdo->prepare("SELECT id FROM wp8e_activos WHERE simbolo = :simbolo");
        $stmt->execute([
            ':simbolo' => $activo['simbolo']
        ]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($row) {
            return $row['id'];
        } else {
            $stmt = $pdo->prepare("INSERT INTO wp8e_activos (simbolo) VALUES (:simbolo)");
            $stmt->execute([
                ':simbolo' => $activo['simbolo']
            ]);
            return $pdo->lastInsertId();
        }
    }

    function obtenerOCrearSetfile($pdo, $activo_id, $setfile) {
        $stmt = $pdo->prepare("SELECT id FROM wp8e_setfiles WHERE activo_id = :activo_id AND nombre_setfile = :nombre_setfile AND parametros_json = :parametros_json AND version_bot = :version_bot");
        $stmt->execute([
            ':activo_id' => $activo_id,
            ':nombre_setfile' => $setfile['nombre_setfile'],
            ':parametros_json' => json_encode($setfile['parametros_json']),
            ':version_bot' => $setfile['version_bot']
        ]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($row) {
            return $row['id'];
        } else {
            $stmt = $pdo->prepare("INSERT INTO wp8e_setfiles (activo_id, nombre_setfile, parametros_json, fecha_creacion, version_bot) 
                                   VALUES (:activo_id, :nombre_setfile, :parametros_json, NOW(), :version_bot)");
            $stmt->execute([
                ':activo_id' => $activo_id,
                ':nombre_setfile' => $setfile['nombre_setfile'],
                ':parametros_json' => json_encode($setfile['parametros_json']),
                ':version_bot' => $setfile['version_bot']
            ]);
            return $pdo->lastInsertId();
        }
    }

    // Paso 1: Obtener o crear la cuenta
    $idCuenta = obtenerOCrearCuenta($pdo, $data['licencia_id'], $data['cuenta']);

    // Paso 2: Obtener o crear el activo
    $idActivo = obtenerOCrearActivo($pdo, $data['activos']);

    // Paso 3: Obtener o crear el setfile, ahora solo relacionado con `activo_id`
    $idSetfile = obtenerOCrearSetfile($pdo, $idActivo, $data['setfiles']);

    echo json_encode(['success' => true, 'idCuenta' => $idCuenta, 'idActivo' => $idActivo, 'idSetfile' => $idSetfile]);

} catch (Exception $e) {
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
