//+------------------------------------------------------------------+
//|                         MovimientoFuerteBTC1.2.3.mq5             |
//|                        Andrés Quintero                           |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

input int balance_inicial = 10000;
input string tipo_cuenta = "FONDEO";   // Tipo de cuenta: FONDEO o REAL
input double drawdown = 10;            // Drawdown en porcentaje
input double net_profit = 10;          // Net Profit en porcentaje
input string nombre_setfile = "EUR01"; // Nombre del setfile
input double take_profit = 50;         // Take Profit en pips
input double stop_loss = 30;           // Stop Loss en pips
// input bool es_demo = false;         // ¿Es una cuenta demo?
input string empresa_fondeo = "FTMO"; // Empresa de fondeo
string licencia = "BFUNDEDDK-LICENCIA-PRUEBA";
string licencia_id = "";

//+------------------------------------------------------------------+
//| Parámetros de entrada abrir operación                                 |
//+------------------------------------------------------------------+
// Parámetros de entrada
input double RiesgoPorOperacion = 1.0; // Riesgo por operación en porcentaje
input double StopLossEnPips = 20.0;    // Stop Loss en pips

// Variables globales
datetime UltimaOperacion = 0; // Hora de la última operación
int MagicNumber = 123456;     // Número mágico para identificar operaciones
ulong TicketOperacion = 0;    // Ticket de la operación abierta
CTrade Trade;                 // Objeto de trading

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // enviarPostCas(); // Prueba de conexión a Google
    // verificarLicencia();
    Print("Iniciando EA - Riesgo por operación: ", RiesgoPorOperacion, "%, Stop Loss: ", StopLossEnPips, " pips");
    EventSetTimer(1);
    // guardarOperacionServicio();
    return (INIT_SUCCEEDED);
}

void OnTimer()
{
    // Verificar si ha pasado 1 minuto desde la última operación
    datetime TiempoActual = TimeCurrent();

    // Si no hay operación abierta y ha pasado el tiempo necesario (60 segundos = 1 minuto)
    if (TicketOperacion == 0 && (TiempoActual - UltimaOperacion) >= 60)
    {
        AbrirOperacion();
        UltimaOperacion = TiempoActual;
    }

    // Verificar si hay que cerrar alguna operación
    VerificarCierreOperaciones();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Lógica de trading aquí (si la licencia es válida)
}

bool EsCuentaDemo()
{
    int trade_mode = (int)AccountInfoInteger(ACCOUNT_TRADE_MODE); // Obtener el modo de la cuenta
    return (trade_mode == ACCOUNT_TRADE_MODE_DEMO);               // Devuelve true si es demo, false si es real
}

//+------------------------------------------------------------------+
//| Función para abrir una operación                                  |
//+------------------------------------------------------------------+
void AbrirOperacion()
{
    int filling_mode = (int)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
    Print("Modos de llenado permitidos: ", filling_mode);

    double Lote = CalcularLote(RiesgoPorOperacion, StopLossEnPips);
    Print("Lote:", Lote);
    // Obtener precio actual
    MqlTick ultimo_tick;
    SymbolInfoTick(_Symbol, ultimo_tick);
    double PrecioApertura = ultimo_tick.ask;

    // Calcular Stop Loss
    double PuntosPorPip = 10 * _Point; // Convertir pips a puntos
    double StopLossPrice = PrecioApertura - StopLossEnPips * PuntosPorPip;

    // Preparar la estructura para la solicitud de trading
    MqlTradeRequest solicitud = {};
    MqlTradeResult resultado = {};

    // Configurar los parámetros de la solicitud
    solicitud.action = TRADE_ACTION_DEAL;       // Ejecutar una operación inmediatamente
    solicitud.symbol = _Symbol;                 // Símbolo actual
    solicitud.volume = Lote;                    // Volumen calculado
    solicitud.type = ORDER_TYPE_BUY;            // Orden de compra
    solicitud.price = PrecioApertura;           // Precio actual
    solicitud.sl = StopLossPrice;               // Stop Loss
    solicitud.tp = 0;                           // Sin Take Profit
    solicitud.deviation = 30;                   // Desviación permitida en puntos
    solicitud.magic = MagicNumber;              // Número mágico
    solicitud.comment = "Auto-Op";              // Comentario
    solicitud.type_filling = ORDER_FILLING_FOK; // Tipo de ejecución

    // Enviar la orden
    if (OrderSend(solicitud, resultado))
    {
        if (resultado.retcode == TRADE_RETCODE_DONE)
        {
            TicketOperacion = resultado.order;
            Print("Operación abierta con éxito. Ticket: ", TicketOperacion,
                  ", Lote: ", Lote,
                  ", SL: ", StopLossPrice);
        }
        else
        {
            Print("Error al abrir operación: ", resultado.retcode, " - ", GetErrorDescription(resultado.retcode));
        }
    }
    else
    {
        Print("Error al enviar la orden: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Calcular el tamaño del lote basado en el riesgo                  |
//+------------------------------------------------------------------+
double CalcularLote(double riesgo, double stopLossPips)
{
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

    // Calcular valor de 1 pip
    double PuntosPorPip = 10 * _Point;
    double pipValue = tickValue * PuntosPorPip / tickSize;

    // Calcular cantidad a arriesgar
    double riesgoMonto = balance * riesgo / 100;

    // Calcular tamaño del lote
    double lote = NormalizeDouble(riesgoMonto / (stopLossPips * pipValue), 2);

    // Verificar límites del broker
    double lotMin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double lotMax = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

    // Ajustar el lote según los límites
    lote = MathMax(lotMin, lote);
    lote = MathMin(lotMax, lote);
    lote = NormalizeDouble(lote / lotStep, 0) * lotStep;

    return lote;
}

//+------------------------------------------------------------------+
//| Verificar si hay que cerrar operaciones                          |
//+------------------------------------------------------------------+
void VerificarCierreOperaciones()
{
    // Si no hay operación abierta, salir
    if (TicketOperacion == 0)
        return;

    // Verificar si la operación aún existe
    if (!PositionSelectByTicket(TicketOperacion))
    {
        // La posición ya no existe (posiblemente cerrada por SL)
        TicketOperacion = 0;
        return;
    }

    // Obtener el tiempo de apertura de la posición
    datetime tiempoApertura = (datetime)PositionGetInteger(POSITION_TIME);

    // Si han pasado 30 segundos desde la apertura
    if (TimeCurrent() - tiempoApertura >= 30)
    {
        // Preparar la solicitud para cerrar la posición
        MqlTradeRequest solicitud = {};
        MqlTradeResult resultado = {};

        // Obtener información de la posición
        double volumen = PositionGetDouble(POSITION_VOLUME);
        ulong ticket = PositionGetInteger(POSITION_TICKET);
        string simbolo = PositionGetString(POSITION_SYMBOL);

        // Configurar los parámetros para cerrar
        solicitud.action = TRADE_ACTION_DEAL;
        solicitud.position = ticket;
        solicitud.symbol = simbolo;
        solicitud.volume = volumen;
        solicitud.type = ORDER_TYPE_SELL; // Para cerrar una posición de compra
        solicitud.price = SymbolInfoDouble(simbolo, SYMBOL_BID);
        solicitud.deviation = 30;
        solicitud.magic = MagicNumber;
        solicitud.comment = "Cierre-Auto";
        solicitud.type_filling = ORDER_FILLING_FOK;

        // Enviar la orden para cerrar
        if (OrderSend(solicitud, resultado))
        {
            if (resultado.retcode == TRADE_RETCODE_DONE)
            {
                Print("Operación cerrada por tiempo. Ticket: ", ticket);
                TicketOperacion = 0;
            }
            else
            {
                Print("Error al cerrar operación: ", resultado.retcode, " - ", GetErrorDescription(resultado.retcode));
            }
        }
        else
        {
            Print("Error al enviar la orden de cierre: ", GetLastError());
        }
    }
}

//+------------------------------------------------------------------+
//| Obtener descripción del error                                    |
//+------------------------------------------------------------------+
string GetErrorDescription(int error_code)
{
    string error_string;

    switch (error_code)
    {
    case TRADE_RETCODE_REJECT:
        error_string = "Solicitud rechazada";
        break;
    case TRADE_RETCODE_CANCEL:
        error_string = "Solicitud cancelada por el trader";
        break;
    case TRADE_RETCODE_PLACED:
        error_string = "Orden colocada";
        break;
    case TRADE_RETCODE_DONE:
        error_string = "Solicitud completada";
        break;
    case TRADE_RETCODE_DONE_PARTIAL:
        error_string = "Solicitud completada parcialmente";
        break;
    case TRADE_RETCODE_ERROR:
        error_string = "Error de procesamiento de solicitud";
        break;
    case TRADE_RETCODE_TIMEOUT:
        error_string = "Solicitud cancelada por timeout";
        break;
    case TRADE_RETCODE_INVALID:
        error_string = "Solicitud inválida";
        break;
    case TRADE_RETCODE_INVALID_VOLUME:
        error_string = "Volumen inválido en la solicitud";
        break;
    case TRADE_RETCODE_INVALID_PRICE:
        error_string = "Precio inválido en la solicitud";
        break;
    case TRADE_RETCODE_INVALID_STOPS:
        error_string = "Stops inválidos en la solicitud";
        break;
    case TRADE_RETCODE_TRADE_DISABLED:
        error_string = "Trading deshabilitado";
        break;
    case TRADE_RETCODE_MARKET_CLOSED:
        error_string = "Mercado cerrado";
        break;
    case TRADE_RETCODE_NO_MONEY:
        error_string = "No hay suficiente dinero";
        break;
    case TRADE_RETCODE_PRICE_CHANGED:
        error_string = "Precio cambiado";
        break;
    case TRADE_RETCODE_PRICE_OFF:
        error_string = "Cotizaciones no disponibles";
        break;
    case TRADE_RETCODE_INVALID_EXPIRATION:
        error_string = "Fecha de expiración inválida";
        break;
    case TRADE_RETCODE_ORDER_CHANGED:
        error_string = "Estado de la orden cambiado";
        break;
    case TRADE_RETCODE_TOO_MANY_REQUESTS:
        error_string = "Demasiadas solicitudes";
        break;
    case TRADE_RETCODE_NO_CHANGES:
        error_string = "Sin cambios en la solicitud";
        break;
    case TRADE_RETCODE_SERVER_DISABLES_AT:
        error_string = "Autotrading deshabilitado por servidor";
        break;
    case TRADE_RETCODE_CLIENT_DISABLES_AT:
        error_string = "Autotrading deshabilitado por cliente";
        break;
    case TRADE_RETCODE_LOCKED:
        error_string = "Solicitud bloqueada para procesamiento";
        break;
    case TRADE_RETCODE_FROZEN:
        error_string = "Orden o posición congelada";
        break;
    case TRADE_RETCODE_INVALID_FILL:
        error_string = "Tipo de llenado de orden inválido";
        break;
    case TRADE_RETCODE_CONNECTION:
        error_string = "Sin conexión con el servidor de trading";
        break;
    case TRADE_RETCODE_ONLY_REAL:
        error_string = "Operación permitida solo en cuentas reales";
        break;
    case TRADE_RETCODE_LIMIT_ORDERS:
        error_string = "Límite de órdenes pendientes alcanzado";
        break;
    case TRADE_RETCODE_LIMIT_VOLUME:
        error_string = "Límite de volumen de órdenes y posiciones alcanzado";
        break;
    case TRADE_RETCODE_INVALID_ORDER:
        error_string = "Tipo de orden incorrecta o prohibida";
        break;
    case TRADE_RETCODE_POSITION_CLOSED:
        error_string = "Posición con el POSITION_IDENTIFIER especificado ya está cerrada";
        break;
    default:
        error_string = "Error desconocido";
    }

    return error_string;
}

// Prueba inicial de conexión a Google para confirmar la conectividad de WebRequest

void enviarPostCas()
{
    string endpoint = "https://bfunded.co/bts/Dashboard/up/API_Registrar_CAS 1.0.0.php"; // Reemplaza con tu URL de endpoint
    string cookie = NULL, headers;
    char post[], result[];
    int timeout = 5000;

    // Obtener las variables del código
    string simbolo = Symbol();
    string fecha_creacion = TimeToString(TimeCurrent(), TIME_DATE);
    string version_bot = "1.0";
    string broker = AccountInfoString(ACCOUNT_COMPANY); // Obtener el nombre del broker
    bool es_demo = EsCuentaDemo();                      // Determinar si la cuenta es demo
    string estado = "ACTIVA";
    string cuenta_id = "1";
    long numero_cuenta = AccountInfoInteger(ACCOUNT_LOGIN); // Obtener el número de cuenta

    Print(licencia_id, " ", tipo_cuenta, " ", balance_inicial, " ", simbolo, " ", fecha_creacion, " ", version_bot, " ", broker, " ", es_demo, numero_cuenta);

    string json_body = "{\n"
                       "  \"licencia_id\": " +
                       licencia_id + ",\n"
                                     "  \"cuenta\": {\n"
                                     "  \"broker\": \"" +
                       broker + "\",\n" // Usar el nombre del broker obtenido por código
                                " \"numero\": " +
                       IntegerToString(numero_cuenta) + ",\n" // cuenta_id como entero (sin comillas)
                                                        "      \"tipo_cuenta\": \"" +
                       tipo_cuenta + "\",\n"
                                     "      \"balance\": " +
                       IntegerToString(balance_inicial) + ",\n" // cuenta_id como entero (sin comillas)
                                                          "      \"es_demo\": " +
                       (es_demo ? "true" : "false") + ",\n"
                                                      "      \"empresa_fondeo\": \"" +
                       empresa_fondeo + "\",\n"
                                        "      \"drawdown\": \"" +
                       DoubleToString(drawdown, 2) + "\",\n"
                                                     "      \"net_profit\": \"" +
                       DoubleToString(net_profit, 2) + "\",\n"
                                                       "      \"fecha_creacion\": \"" +
                       fecha_creacion + "\",\n"
                                        "      \"estado\": \"" +
                       estado + "\"\n" // Estado
                                "  },\n"
                                "  \"activos\": {\n"
                                "      \"cuenta_id\": \"" +
                       cuenta_id + "\",\n" // Estado
                                   "      \"simbolo\": \"" +
                       simbolo + "\"\n"
                                 "  },\n"
                                 "  \"setfiles\": {\n"
                                 "      \"par_id\": \"1\",\n"
                                 "      \"nombre_setfile\": \"" +
                       nombre_setfile + "\",\n"
                                        "      \"parametros_json\": {\n"
                                        "      \"take_profit\": " +
                       DoubleToString(take_profit, 2) + ",\n"
                                                        "      \"stop_loss\": " +
                       DoubleToString(stop_loss, 2) + ",\n"
                                                      "      \"tipo_cuenta\": \"" +
                       tipo_cuenta + "\",\n"
                                     "      \"drawdown\": \"" +
                       DoubleToString(drawdown, 2) + "\",\n"
                                                     "      \"net_profit\": \"" +
                       DoubleToString(net_profit, 2) + "\"\n"
                                                       "      },\n"
                                                       "      \"fecha_creacion\": \"" +
                       fecha_creacion + "\",\n"
                                        "      \"version_bot\": \"" +
                       version_bot + "\"\n"
                                     "  }\n"
                                     "}";

    // Convertir el cuerpo JSON a un array de caracteres
    StringToCharArray(json_body, post, 0, StringLen(json_body));

    // Configurar los encabezados para indicar que el contenido es JSON
    headers = "Content-Type: application/json\r\n";

    ResetLastError();
    int res = WebRequest("POST", endpoint, cookie, NULL, timeout, post, ArraySize(post), result, headers);

    if (res == 200)
    {
        Print("Solicitud POST exitosa.");

        // Convertir la respuesta (array de caracteres) a una cadena
        string response = CharArrayToString(result, 0, ArraySize(result));
        Print("Respuesta del servidor: ", response);
    }
    else
    {
        int error_code = GetLastError();
        Print("Error en WebRequest. Código HTTP: ", res, " Código de error MQL5: ", error_code);
    }
}

void verificarLicencia()
{
    // Detecta si el bot se está ejecutando en el probador de estrategias
    bool es_modo_test = MQLInfoInteger(MQL_TESTER);

    // Si estamos en modo de prueba, omitir la verificación de licencia
    if (es_modo_test)
    {
    }

    // Código de verificación de licencia en ejecución normal
    string cookie = NULL, headers;
    char post[], result[];
    int timeout = 5000;

    string url = "https://bfunded.co/bts/Dashboard/up/API_Validar_Licencia 2.1.0.php"; // URL del servidor de verificación de licencia con ID

    // Obtener el identificador único de la instancia de MetaTrader
    // long instance_id = AccountInfoInteger(ACCOUNT_LOGIN); // ID único de la cuenta de MetaTrader
    long instance_id = 10024; // ID único de la cuenta de MetaTrader

    // Construir la URL con parámetros
    string url_con_parametros = url + "?licensekey=" + licencia + "&metatraderid=" + IntegerToString(instance_id);

    ResetLastError();
    int res = WebRequest("GET", url_con_parametros, cookie, NULL, timeout, post, 0, result, headers);

    if (res == 200)
    {

        string response = CharArrayToString(result);
        Print(response);
        // Analizar el JSON (usando manipulación de cadenas)
        int idStart = StringFind(response, "\"id_registro\":") + StringLen("\"id_registro\":");
        int idEnd = StringFind(response, ",", idStart);
        licencia_id = StringSubstr(response, idStart, idEnd - idStart);

        // int nameStart = StringFind(response, "\"display_name\":\"") + StringLen("\"display_name\":\"");
        // int nameEnd = StringFind(response, "\"", nameStart);
        // string displayName = StringSubstr(response, nameStart, nameEnd - nameStart);

        // Extraer el valor de "success"
        int successStart = StringFind(response, "\"success\":") + StringLen("\"success\":");
        int successEnd = StringFind(response, ",", successStart);
        string successStr = StringSubstr(response, successStart, successEnd - successStart);

        // Convertir el valor a booleano
        // bool success = (successStr == "true");

        // Mostrar el valor
        if (successStr == "true")
        {
            enviarPostCas();
        }
    }
    else
    {
        int error_code = GetLastError();
        Print("  -->  Error en WebRequest a AWS. Código HTTP: ", res, " Código de error MQL5: ", error_code);
    }
}

void guardarOperacionServicio()
{
    // URL del endpoint
    string endpoint = "https://bfunded.co/bts/Dashboard/up/API_Guardar_Operacion 1.1.0.php";

    // Configurar variables para la solicitud
    string cookie = NULL, headers;
    char post[], result[];
    int timeout = 5000;

    // Cuerpo JSON quemado
    string json_body = "{\n"
                       "    \"setfile_id\": 1,\n"
                       "    \"tipo\": \"compra\",\n"
                       "    \"volumen\": 1.5,\n"
                       "    \"precio_entrada\": 1.23456,\n"
                       "    \"precio_salida\": 1.23789,\n"
                       "    \"ganancia\": 50.75,\n"
                       "    \"simbolo\": \"EURUSD\",\n"
                       "    \"fecha_apertura\": \"2025-02-11 12:24:13\",\n"
                       "    \"fecha_cierre\": \"2025-02- 14:30:45\",\n"
                       "    \"ticket\": 64995521,\n"
                       "    \"comision\": -4.52,\n"
                       "    \"swap\": 6.56,\n"
                       "    \"orden_id\": 67516232,\n"
                       "    \"posicion_id\": 67190785,\n"
                       "    \"comentario\": \"[sl 1.04807]\"\n"
                       "}";

    // Convertir el cuerpo JSON a un array de caracteres
    StringToCharArray(json_body, post, 0, StringLen(json_body));

    // Configurar los encabezados para indicar que el contenido es JSON
    headers = "Content-Type: application/json\r\n";

    // Realizar la solicitud HTTP POST
    ResetLastError();
    int res = WebRequest("POST", endpoint, cookie, NULL, timeout, post, ArraySize(post), result, headers);

    // Verificar el resultado de la solicitud
    if (res == 200)
    {
        Print("Solicitud POST exitosa.");

        // Convertir la respuesta (array de caracteres) a una cadena
        string response = CharArrayToString(result, 0, ArraySize(result));
        Print("Respuesta del servidor: ", response);
    }
    else
    {
        int error_code = GetLastError();
        Print("Error en WebRequest. Código HTTP: ", res, " Código de error MQL5: ", error_code);
    }
}