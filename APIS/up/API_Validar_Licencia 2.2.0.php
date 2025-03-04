<?php
ini_set('display_errors', 0);
ini_set('display_startup_errors', 0);
error_reporting(E_ALL);

function handleError($message) {
    error_log($message);
    echo json_encode([
        'success' => false,
        'message' => $message
    ]);
    exit;
}

$wp_config_path = '/home/bfunded/public_html/bts/Dashboard/dbweb-config.php';
if (!file_exists($wp_config_path)) {
    handleError("Error de configuración: dbweb-config.php no encontrado");
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

$sql = "SELECT id_registro, metatrader_id, id_usuario FROM wp8e_usuarios_licencias WHERE licencia = ?";
$stmt = $conn->prepare($sql);
if ($stmt === false) {
    handleError("Error en la consulta SQL: " . $conn->error);
}
$stmt->bind_param("s", $license_key);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $row = $result->fetch_assoc();
    $id_usuario = $row['id_usuario'];
    $id_registro = $row['id_registro'];

    // Obtener el nombre de usuario
    $sql_user = "SELECT display_name FROM wp8e_users WHERE ID = ?";
    $stmt_user = $conn->prepare($sql_user);
    if ($stmt_user === false) {
        handleError("Error en la consulta de usuario: " . $conn->error);
    }
    $stmt_user->bind_param("i", $id_usuario);
    $stmt_user->execute();
    $result_user = $stmt_user->get_result();
    $display_name = ($result_user->num_rows > 0) ? $result_user->fetch_assoc()['display_name'] : "Desconocido";

    $message = "Licencia valida"; // Mensaje por defecto

    if ($row['metatrader_id'] == $metatrader_id) {
        // La licencia está en el mismo MetaTrader ID
        echo json_encode([
            'success' => true,
            'id_usuario' => $id_usuario,
            'id_licencia' => $id_registro,
            'display_name' => $display_name,
            'message' => $message
        ]);
    } else {
        // Se detecta un cambio de MetaTrader ID, actualizar la base de datos
        $update_sql = "UPDATE wp8e_usuarios_licencias SET metatrader_id = ? WHERE licencia = ?";
        $stmt_update = $conn->prepare($update_sql);
        if ($stmt_update === false) {
            handleError("Error en la actualización de MetaTrader ID: " . $conn->error);
        }
        $stmt_update->bind_param("ss", $metatrader_id, $license_key);
        if ($stmt_update->execute()) {
            $message .= ", La licencia ha sido trasladada a otra Cuenta de Trading";
        } else {
            handleError("Error al actualizar el MetaTrader ID");
        }

        echo json_encode([
            'success' => true,
            'id_usuario' => $id_usuario,
            'id_licencia' => $id_registro,
            'display_name' => $display_name,
            'message' => $message
        ]);
    }
} else {
    // Respuesta para licencia inválida
    echo json_encode([
        'success' => false,
        'message' => "Licencia invalida"
    ]);
}

$stmt->close();
$conn->close();
?>
