//+------------------------------------------------------------------+
//|                       Trading Note                       |
//|              Copyright 2025 | EA | The Trading Api      |
//|                                               |
//+------------------------------------------------------------------+

#include <Jason.mqh>
int segGuardarHistorico = 0;
long numero_cuenta = AccountInfoInteger(ACCOUNT_LOGIN); // Obtener el número de cuenta
input string license_key = "LICENCIA-TEST-001";  // Api Key
string api_key="p8Lz9R2q-TyX3v5Bp-47Nd8Jm-QwG6ANFsP0d";

// Variables locales 
string  id_usuario = "", id_licencia = "", message = "", idCuenta= "", idActivo = "", idSetfile = "";

//Subir historico cada N tiempo;
int contAux=0;
int tiempoExtra=0;
int id_setfile=1;
double porcentajeAdicionalTiempo=0.25;
datetime proximaEjecucion = 0; // Almacena la próxima ejecución en timestamp UNIX
datetime tiempoActual = TimeCurrent(); // Obtener tiempo actual en segundos

datetime ultimaFechaGlobal = 0; // Utilizada en el historico
int ultimaTicketGlobal=0; // Utilizada en el ticket
bool OperacionCerrada=false;

// Estructuras          
struct Operacion {
    ulong ticket;
    string simbolo;
    ENUM_DEAL_TYPE tipo;
    ENUM_DEAL_ENTRY entrada;
    double volumen;
    double precio_entrada;
    double precio_salida;
    double comision;
    double swap;
    double beneficio;
    datetime fecha_apertura;
    datetime fecha_cierre;
    ulong orden_id;
    ulong posicion_id;
    string comentario;
    ulong magic_number;
    double tp;
    double sl;
};
Operacion operaciones[];

int OnInit() {

    Print("🔹 Inicializando el Trading Note...");
    // 1- Ejecutar la validación de la licencia
    bool licencia_valida = ValidarLicencia(license_key, id_usuario, id_licencia, message);
    if (licencia_valida){
        ValidarParametros();
        int tiempo_extra = MathRand() % int(segGuardarHistorico) ; // tiempo adicional aleatorio (300 a 600 segundos) MathRand() % 301 + 300
        tiempoExtra = tiempo_extra * porcentajeAdicionalTiempo;    
        segGuardarHistorico=segGuardarHistorico + tiempoExtra;        
        proximaEjecucion = TimeCurrent() + segGuardarHistorico; // Programar primera ejecución   
    
        EventSetTimer(1); // Ejecutar OnTimer() cada 1 segundo   
        return INIT_SUCCEEDED;    
    }else{
        Print("Condiciones iniciales no cumplidas. Deteniendo EA.");
        return INIT_FAILED;
        ExpertRemove();       
    }   
}

void OnTick() {
}

void OnTimer()
{
    datetime newTimpoActual = TimeCurrent(); // Obtener Hora actual

    if (tiempoActual >= newTimpoActual){
        tiempoActual = tiempoActual+1;
    }
    else{
        tiempoActual = newTimpoActual;
    }
    
    // Verificar si ya es momento de ejecutar la función    
    if (tiempoActual >= proximaEjecucion)
    {          
        //Print("⏳ Ejecutando Registro de Histórico...");
        RegistrarHitorico();            

        // Programar la siguiente ejecución sumando segGuardarHistorico
        proximaEjecucion = tiempoActual + segGuardarHistorico;
        //Print("⏳ Próxima ejecución programada en ", segGuardarHistorico, " segundos.. a las: ", proximaEjecucion);

    }
}

bool ValidarParametros()
{
    string endpoint = "https://tradingnote.co/app/api/API_Parametros_1.0.0.php?id=1&api_key=" + api_key;  
    string cookie = "";
    string headers; // No es un array
    uchar result[]; // ⚠️ Debe ser un array de tipo uchar
    uchar data[];   // ⚠️ Para GET, debe estar vacío
    int timeout = 5000;
    
    ResetLastError();
    
    // ✅ Versión corregida de WebRequest para GET
    int res = WebRequest("GET", endpoint, cookie, timeout, data, result, headers);
    
    if (res == 200)
    {
        // Convertir la respuesta (array de bytes) a una cadena
        string response;
        int size = ArraySize(result);
        if (size > 0)
        {
            response = CharArrayToString(result);
            //Print("✅ Respuesta de API_Validar_Parametros: ", response);
        }
        else
        {
            Print("⚠️ Respuesta vacía de la API.");
            return false;
        }
        
        // Deserializar JSON
        CJAVal json;
        if (!json.Deserialize(response))
        {
            Print("❌ Error al analizar la respuesta JSON.");
            return false;
        }

        // Verificar si la consulta fue exitosa
        bool consulta_valida = json["success"].ToBool();

        if (consulta_valida) {
            // Extraer el valor de segundos desde el objeto "data"
            segGuardarHistorico = (int)json["data"]["segundos"].ToInt();          
            Print("✅ Parámetros validados");

            return true;
        } else {
            Print("⚠️ La API devolvió 'success: false'. Mensaje: ", json["message"].ToStr());
            return false;
        }
    }
    else
    {
        int error_code = GetLastError();
        Print("❌ Error en WebRequest. Código HTTP: ", res, " Código de error MQL5: ", error_code);
        return false;
    }    
    return false;
}

bool ValidarLicencia(string license_key, string &id_usuario, string &id_licencia, string &message)
{
    string cookie = NULL, headers;
    char post[], result[];
    int timeout = 5000;

    // URL del servidor de verificación de licencia
    string url = "https://tradingnote.co/app/api/API_Licencias_1.1.0.php";

    // Construir la URL con parámetros
    string url_con_parametros = url + "?licencia=" + license_key + "&api_key=" + api_key+ "&cuenta=" + numero_cuenta;

    ResetLastError();
    int res = WebRequest("GET", url_con_parametros, cookie, NULL, timeout, post, 0, result, headers);

    if (res == 200)
    {
        string response = CharArrayToString(result);
        //Print("🔹 Respuesta de la API: ", response);

        // Analizar la respuesta JSON usando CJAVal
        CJAVal json;
        if (!json.Deserialize(response))
        {
            Print("❌ Error al analizar la respuesta JSON.");
            return false;
        }
       
        // Extraer el campo "success"
        bool licencia_valida = json["success"].ToBool();

        if (licencia_valida)
        {
            // Extraer valores correctamente
            idCuenta  = json["id_cuenta"].ToStr();
            id_licencia = json["id_licencia"].ToStr();      
            message = json["message"].ToStr();

            // Si "message" está vacío, asignar mensaje predeterminado
            if (message == "" || message == "null")
                message = "Licencia válida";

            // Imprimir datos extraídos correctamente
            Print("✅ Licencia válida ");
            //Print("📌 ID de usuario: ", id_usuario);
            //Print("🔑 ID de licencia: ", id_licencia);
            //Print("ℹ️ Mensaje: ", message);
            
            return true;
        }
        else
        {
            // Extraer mensaje de error si la licencia no es válida
            message = json["message"].ToStr();
            if (message == "" || message == "null")
                message = "Licencia inválida";

            Print("❌ Error: ", message);
            return false;
        }
    }
    else
    {
        int error_code = GetLastError();
        Print("❌ Error en WebRequest. Código HTTP: ", res, " Código de error MQL5: ", error_code);
        return false;
    }
}

bool RegistrarHitorico(){    
    ObtenerOperaciones(operaciones, idCuenta);
    //ImprimirOperacione();
    return true;
}

void ObtenerOperaciones(Operacion &listaOperaciones[], int idCuenta) {
    // Cargar la última fecha de operación guardada previamente
    datetime ultimaFechaGuardada = CargarUltimaFechaGuardadaGlobal(idCuenta); 

    if (!HistorySelect(ultimaFechaGuardada, TimeCurrent())) {
        //Print("❌ Error al seleccionar historial de operaciones.");
        return;
    }

    int totalOperaciones = HistoryDealsTotal(); 
    // bool existeTicket = HistoryDealGetInteger(ultimaTicketGlobal);

    if (totalOperaciones == 0) {
       // Print("⚠️ No hay operaciones cerradas en la cuenta.");
        return;
    }

    int contador = 0;
    for (int i = 0; i < totalOperaciones; i++) {
        ulong ticket = HistoryDealGetTicket(i);
        ENUM_DEAL_ENTRY entrada = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket, DEAL_ENTRY);

        // Solo almacenar operaciones cerradas (DEAL_ENTRY_OUT)
        if (entrada == DEAL_ENTRY_OUT) {
            datetime fechaCierre = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
           
            // Solo procesar operaciones posteriores a la última fecha guardada
            if (fechaCierre > ultimaFechaGuardada) {
                ArrayResize(listaOperaciones, contador + 1);

                listaOperaciones[contador].ticket = HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
                listaOperaciones[contador].simbolo = HistoryDealGetString(ticket, DEAL_SYMBOL);
                listaOperaciones[contador].entrada = entrada;
                listaOperaciones[contador].volumen = HistoryDealGetDouble(ticket, DEAL_VOLUME);
                listaOperaciones[contador].precio_salida = HistoryDealGetDouble(ticket, DEAL_PRICE);
                listaOperaciones[contador].comision = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
                listaOperaciones[contador].swap = HistoryDealGetDouble(ticket, DEAL_SWAP);
                listaOperaciones[contador].beneficio = HistoryDealGetDouble(ticket, DEAL_PROFIT);
                listaOperaciones[contador].fecha_cierre = fechaCierre;
                listaOperaciones[contador].orden_id = HistoryDealGetInteger(ticket, DEAL_ORDER);
                listaOperaciones[contador].comentario = HistoryDealGetString(ticket, DEAL_COMMENT);
                listaOperaciones[contador].magic_number = HistoryDealGetInteger(ticket, DEAL_MAGIC);
                listaOperaciones[contador].tp = HistoryDealGetDouble(ticket, DEAL_TP);
                listaOperaciones[contador].sl = HistoryDealGetDouble(ticket, DEAL_SL);

                // Buscar la operación de entrada correspondiente
                ulong posicion_id = listaOperaciones[contador].ticket;
                for (int j = 0; j < totalOperaciones; j++) {
                    ulong ticket_entrada = HistoryDealGetTicket(j);
                    ulong pos_id_entrada = HistoryDealGetInteger(ticket_entrada, DEAL_POSITION_ID);

                    if (pos_id_entrada == posicion_id &&
                        HistoryDealGetInteger(ticket_entrada, DEAL_ENTRY) == DEAL_ENTRY_IN) {
                        listaOperaciones[contador].precio_entrada = HistoryDealGetDouble(ticket_entrada, DEAL_PRICE);
                        listaOperaciones[contador].fecha_apertura = (datetime)HistoryDealGetInteger(ticket_entrada, DEAL_TIME);
                        listaOperaciones[contador].tipo = (ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket_entrada, DEAL_TYPE);
                        break;
                    }
                }
                contador++;
                OperacionCerrada=true;
            }
        }
    }

    // Verificar si hay operaciones nuevas en el array
    int totalOperacionesGuardadas = ArraySize(listaOperaciones);
    //Print("total Operaciones historico: ", totalOperacionesGuardadas);

    //Metodo 2     
    // Enviar el historial al endpoint
    if (totalOperacionesGuardadas > 0 && OperacionCerrada) {
        if (!enviarPostHistorico(listaOperaciones, idCuenta)) {
            //Print("❌ Error al enviar operaciones a la API.");
        } else {
            // Guardar la fecha de la última operación para la próxima vez
            if (totalOperacionesGuardadas > 0) {               
                GuardarUltimaFechaGlobal(listaOperaciones[totalOperacionesGuardadas - 1].fecha_cierre, totalOperacionesGuardadas - 1);
                totalOperacionesGuardadas=0;
            }
        }
    }
}

// Método 1: Usando variable global pierde el valor al reiniciar
datetime CargarUltimaFechaGuardadaGlobal(int idCuenta) {
    // Si es 0, significa primera ejecución o reinicio
    return ultimaFechaGlobal;
}

void GuardarUltimaFechaGlobal(datetime ultimaFecha, int ultimoTicket) {
    ultimaFechaGlobal = ultimaFecha+1;
    ultimaTicketGlobal = ultimoTicket;
    OperacionCerrada = false;
}

bool enviarPostHistorico(Operacion &listaOperaciones[], int idCuenta) {
    string endpoint = "https://tradingnote.co/app/api/API_Operaciones_1.3.0.php";
    string cookie = NULL, headers;
    char post[], result[];
    int timeout = 5000;

    // Construcción del JSON con las operaciones del historial
    string json_body = "{\n"
                        "  \"id_cuenta\": " + IntegerToString(idCuenta) + ",\n"
                        "  \"id_setfile\": " + IntegerToString(id_setfile) + ",\n"
                        "  \"operaciones\": [\n";

    for (int i = 0; i < ArraySize(listaOperaciones); i++) {
        // Formato de fechas con "-" en lugar de "."
        string fecha_apertura = TimeToString(operaciones[i].fecha_apertura, TIME_SECONDS | TIME_DATE);
        string fecha_cierre = TimeToString(operaciones[i].fecha_cierre, TIME_SECONDS | TIME_DATE);
        string nfecha_apertura = StringReplace((fecha_apertura), ".", "-");
        string nfecha_cierre = StringReplace((fecha_cierre), ".", "-");      


        // Escapar comillas en el comentario
        string comentario = StringReplace(listaOperaciones[i].comentario, "\"", "\\\"");

        json_body += "    {\n"
                     "      \"tipo\": \"" + EnumToString(listaOperaciones[i].tipo) + "\",\n"
                     "      \"volumen\": " + DoubleToString(listaOperaciones[i].volumen, 2) + ",\n"
                     "      \"precio_entrada\": " + DoubleToString(listaOperaciones[i].precio_entrada, 5) + ",\n"
                     "      \"precio_salida\": " + DoubleToString(listaOperaciones[i].precio_salida, 5) + ",\n"
                     "      \"ganancia\": " + DoubleToString(listaOperaciones[i].beneficio, 2) + ",\n"
                     "      \"activo\": \"" + listaOperaciones[i].simbolo + "\",\n"
                     "      \"fecha_apertura\": \"" + fecha_apertura + "\",\n"
                     "      \"fecha_cierre\": \"" + fecha_cierre + "\",\n"
                     "      \"ticket\": " + IntegerToString(listaOperaciones[i].ticket) + ",\n"
                     "      \"comision\": " + DoubleToString(listaOperaciones[i].comision, 2) + ",\n"
                     "      \"swap\": " + DoubleToString(listaOperaciones[i].swap, 2) + ",\n"
                     "      \"orden_id\": " + IntegerToString(listaOperaciones[i].orden_id) + ",\n"
                     "      \"magic_number\": " + IntegerToString(listaOperaciones[i].magic_number) + ",\n"
                     "      \"comentario\": \"" + comentario + "\",\n"
                     "      \"tp\": " +  DoubleToString(listaOperaciones[i].tp, 5)  + ",\n"
                     "      \"sl\": " +  DoubleToString(listaOperaciones[i].sl, 5)  + "\n"
                     //"      \"comentario\": \"" + comentario + "\"\n"
                     "    }";

        if (i < ArraySize(listaOperaciones) - 1) json_body += ",";
        json_body += "\n";
    }

    json_body += "  ]\n""}";

    // Convertir el JSON a un array de caracteres
    StringToCharArray(json_body, post, 0, StringLen(json_body));

    // Configurar los encabezados para indicar que el contenido es JSON
    headers = "Content-Type: application/json\r\n";

    ResetLastError();
    int res = WebRequest("POST", endpoint, cookie, NULL, timeout, post, ArraySize(post), result, headers);

    if (res == 200) {
        string response = CharArrayToString(result, 0, ArraySize(result));
        CJAVal json;
        if (!json.Deserialize(response)) {
            //Print("❌ Error al analizar la respuesta JSON.");
            return false;
        }

        bool success = json["success"].ToBool();
        int operaciones_guardadas = json["operaciones_guardadas"].ToInt();
        int operaciones_existentes = json["operaciones_existentes"].ToInt();

        if (success) {
            PrintFormat("✅ API Histórico enviada correctamente. Operaciones insertadas: %d, Operaciones existentes: %d",
                 operaciones_guardadas, operaciones_existentes);
            return true;
        } else {
            //Print("⚠️ La API devolvió 'success: false'.");
            return false;
        }
    } else {
        int error_code = GetLastError();
       // Print("❌ Error en WebRequest. Código HTTP: ", res, " Código de error MQL5: ", error_code);
        //Print("🔍 JSON Enviado: ", json_body);  // Imprimir JSON para depuración
        return false;
    }
}

// Función para guardar el log en un archivo de texto
void GuardarLog(string response) {
    string filename = "json_" + TimeToString(TimeLocal(), TIME_DATE) + ".txt";
    int handle = FileOpen(filename, FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_COMMON);
    
    if(handle != INVALID_HANDLE) {
        FileWrite(handle, response);
        FileClose(handle);
    } else {
        Print("Error al abrir archivo: ", GetLastError());
    }
}
