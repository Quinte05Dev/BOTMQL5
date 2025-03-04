<?php
ini_set('display_errors', 0);
ini_set('display_startup_errors', 0);
error_reporting(E_ALL);

function handleError($message) {
    error_log($message);
    echo json_encode(['success' => false, 'error' => $message]);
    exit;
}

$wp_config_path = '/home/bfunded/public_html/bts/dashboard/dbweb-config.php';
if (!file_exists($wp_config_path)) {
    handleError("Error de configuración: wp-config.php no encontrado");
}
require_once($wp_config_path);

$conn = new mysqli(DB_HOST, DB_USER, DB_PASSWORD, DB_NAME);
if ($conn->connect_error) {
    handleError("Error de conexión a la base de datos: " . $conn->connect_error);
}

$metatrader_id = isset($_GET['metatraderid']) ? $conn->real_escape_string($_GET['metatraderid']) : null;
$license_key = isset($_GET['licensekey']) ? $conn->real_escape_string($_GET['licensekey']) : null;

if (!$metatrader_id || !$license_key) {
    handleError("Parámetros faltantes o inválidos");
}

$sql = "SELECT id_registro, metatrader_id, user_id FROM wp8e_usuarios_licencias WHERE licencia = ?";
$stmt = $conn->prepare($sql);
if ($stmt === false) {
    handleError("Error en la consulta SQL: " . $conn->error);
}
$stmt->bind_param("s", $license_key);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $row = $result->fetch_assoc();
    if ($row['metatrader_id'] == $metatrader_id) {
        $user_id = $row['user_id'];
        $sql_user = "SELECT display_name FROM wp8e_users WHERE ID = ?";
        $stmt_user = $conn->prepare($sql_user);
        if ($stmt_user === false) {
            handleError("Error en la consulta de usuario: " . $conn->error);
        }
        $stmt_user->bind_param("i", $user_id);
        $stmt_user->execute();
        $result_user = $stmt_user->get_result();
        $display_name = ($result_user->num_rows > 0) ? $result_user->fetch_assoc()['display_name'] : "Desconocido";
        echo json_encode(['success' => true, 'display_name' => $display_name]);
    } else {
        echo json_encode(['success' => false, 'error' => 'ID de MetaTrader no coincide']);
    }
} else {
    echo json_encode(['success' => false, 'error' => 'Licencia no válida']);
}

$stmt->close();
$conn->close();
?>
