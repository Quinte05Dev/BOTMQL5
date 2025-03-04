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

    // 🔹 Parámetros de paginación 🔹
    $page = isset($_GET['page']) ? intval($_GET['page']) : 1;
    $limit = isset($_GET['limit']) ? intval($_GET['limit']) : 10;
    $offset = ($page - 1) * $limit;

    // 🔹 Verificar si se usa el nuevo endpoint `clientes_vista` 🔹
    $vista = isset($_GET['vista']) ? $_GET['vista'] : null;

    if ($vista === "clientes_vista") {
        // Obtener total de clientes para calcular páginas
        $totalQuery = "SELECT COUNT(*) AS total FROM wp8e_users";
        $totalStmt = $pdo->query($totalQuery);
        $totalClientes = $totalStmt->fetch(PDO::FETCH_ASSOC)['total'];
        $totalPaginas = ceil($totalClientes / $limit);

        // Obtener listado de clientes con paginación
        $query = "SELECT id, display_name FROM wp8e_users LIMIT :limit OFFSET :offset";
        $stmt = $pdo->prepare($query);
        $stmt->bindParam(':limit', $limit, PDO::PARAM_INT);
        $stmt->bindParam(':offset', $offset, PDO::PARAM_INT);
        $stmt->execute();
        $clientes = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Recorrer cada cliente para obtener cantidad_cuentas, rentabilidad y ganancia
        foreach ($clientes as &$cliente) {
            $id_usuario = $cliente['id'];

            // 🔹 Obtener cantidad de cuentas del usuario 🔹
            $api_cuentas_url = "https://bfunded.co/bts/Dashboard/down/API_Cuentas_1.2.0.php?id_usuario=" . urlencode($id_usuario);
            $response_cuentas = file_get_contents($api_cuentas_url);
            $data_cuentas = json_decode($response_cuentas, true);
            $cliente['cantidad_cuentas'] = $data_cuentas['cantidad_cuentas'] ?? 0;

            // 🔹 Obtener rentabilidad y ganancia del usuario 🔹
            $api_operaciones_url = "https://bfunded.co/bts/Dashboard/down/API_Operaciones_1.3.0.php?id_usuario=" . urlencode($id_usuario);
            $response_operaciones = file_get_contents($api_operaciones_url);
            $data_operaciones = json_decode($response_operaciones, true);
            $cliente['rentabilidad_ultimo_mes'] = isset($data_operaciones['rentabilidad_ultimo_mes']) ? number_format($data_operaciones['rentabilidad_ultimo_mes'], 2, '.', '') : "0.00";
            $cliente['ganancia_ultimo_mes'] = isset($data_operaciones['ganancia_ultimo_mes']) ? number_format($data_operaciones['ganancia_ultimo_mes'], 2, '.', '') : "0.00";
        }

        // 🔹 Responder con JSON paginado 🔹
        echo json_encode([
            'success' => true,
            'total_clientes' => $totalClientes,
            'total_paginas' => $totalPaginas,
            'pagina_actual' => $page,
            'limite' => $limit,
            'data' => $clientes
        ]);
    } else {
        // 🔹 Endpoint original: Obtener todos los clientes (sin paginación) 🔹
        $query = "SELECT id, display_name, user_registered, user_email FROM wp8e_users";
        $stmt = $pdo->query($query);
        $clientes = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // 🔹 Respuesta en JSON 🔹
        echo json_encode(['success' => true, 'data' => $clientes]);
    }

} catch (Exception $e) {
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
