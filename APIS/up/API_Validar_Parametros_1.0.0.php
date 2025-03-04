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

// Obtener el ID desde la solicitud GET
$id = isset($_GET['id']) ? intval($_GET['id']) : null;

if (!$id) {
    handleError("Parámetro 'id' faltante o inválido");
}

// Consultar la tabla wp8e_parametros
$sql = "SELECT id, segundos FROM wp8e_parametros WHERE id = ?";
$stmt = $conn->prepare($sql);
if ($stmt === false) {
    handleError("Error en la consulta SQL: " . $conn->error);
}
$stmt->bind_param("i", $id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $row = $result->fetch_assoc();
    
    // Respuesta exitosa
    echo json_encode([
        'success' => true,
        'id' => $row['id'],
        'segundos' => $row['segundos'],
        'message' => "Parámetros obtenidos correctamente"
    ]);
} else {
    // No se encontró el registro con el ID especificado
    echo json_encode([
        'success' => false,
        'message' => "No se encontró ningún registro con el ID especificado"
    ]);
}

$stmt->close();
$conn->close();
?>