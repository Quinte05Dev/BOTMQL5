input group "05. CONFIGURACION HORARIOS OPERATIVOS";
input group "Configuracion de NY:";

input bool input_operativa_newyork = true; // Permitir Operativa en NY
input string input_ny_hora = "10:10";      // Inicio horario NY (hora:minutos)
int input_ny_desde_hora;                   // Inicio horario NY (hora)
int input_ny_desde_minuto;                 // Inicio horario NY (minuto)
input string hasta_ny_hora = "10:10";      // Fin horario NY (hora:minutos)
int input_ny_hasta_hora = 12;              // Fin horario NY (hora)
int input_ny_hasta_minuto = 30;            // Fin horario NY (minuto)

input group "Configuracion de Londres:";
input bool input_operativa_londres = false; // Permitir Operativa en Londres
input string input_londres_hora = "00:10";  // Inicio horario Londres (hora:minutos)
int input_londres_desde_hora;               // Inicio horario Londres (hora)
int input_londres_desde_minuto;             // Inicio horario Londres (minuto)
input string hasta_londres_hora = "10:10";  // Fin horario Londres (hora:minutos)
int input_londres_hasta_hora;               // Fin horario Londres (hora)
int input_londres_hasta_minuto;             // Fin horario Londres (minuto)

input group "Configuracion de Asia:";
input bool input_operativa_asia = false; // Permitir Operativa en Asia
input string input_asia_hora = "00:10";  // Inicio horario Asia (hora:minutos)
int input_asia_desde_hora;               // Inicio horario Asia (hora)
int input_asia_desde_minuto;             // Inicio horario Asia (minuto)
input string hasta_asia_hora = "10:10";  // Fin horario Asia (hora:minutos)
int input_asia_hasta_hora;               // Fin horario Asia (hora)
int input_asia_hasta_minuto;

int ajuste_tiempo; // Fin horario Asia (minuto)

input group "Configuracion operativas:";
input group "-------------------";
input bool input_activar_operativa_newyork = true; // Trabajar Operativa en NY
input int ajuste_horario = 2;
// Ajuste horario

bool sesion_asia_iniciada = true;
bool sesion_asia_finalizada = false;

bool sesion_ny_iniciada = true;
bool sesion_ny_finalizada = false;

bool sesion_londres_iniciada = true;
bool sesion_londres_finalizada = false;

bool isTrueNY = false;

// Comprobar si la hora actual está dentro de alguna de las sesiones operativas habilitadas
bool global_operar_asia;
bool global_operar_londres;
bool global_operar_ny;

datetime hora_actual_servidor;
datetime hora_inicio_newY;
datetime hora_fin_newY;
datetime serverTime;
int hora_nya;   // Variable para almacenar la hora
int minuto_nya; // Variable para almacenar los minutos

// Handlers para los archivos
int fileHandleAsia = INVALID_HANDLE;
int fileHandleLondres = INVALID_HANDLE;
int fileHandleNuevaYork = INVALID_HANDLE; // Variable global para el manejador del archivo
// string filePathNuevaYork  = "D:\\csv\\ticks_data.csv"; // Ruta relativa (se guarda en MQL5/Files)

// Rutas de archivos CSV para cada sesión
string filePathAsia = "operaciones_asia.csv";
string filePathLondres = "operaciones_londres.csv";
string filePathNuevaYork = "operaciones_nueva_york.csv";

// string filePathNuevaYork  = "C:\\Users\\matiu\\AppData\\Roaming\\MetaQuotes\\Terminal\\Common\\Files\\ticks_data.csv";
// string filePathNuevaYork  = TerminalInfoString(TERMINAL_DATA_PATH) + "\\MQL5\\Files\\ticks_data.csv";

string relativePath = "\\MQL5\\Files";
string region;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Mensaje de éxito
    Print("EA inicializado correctamente.");
    ajuste_tiempo = GetNewYorkTime();
    EventSetTimer(1);

    // se crea el archivo
    InitializeCSVFile(filePathNuevaYork, fileHandleNuevaYork);

    // Crear el archivo CSV y escribir el encabezado (solo si no existe)
    /*
    if (!FileIsExist(filePathNuevaYork))
    {
        fileHandleNuevaYork = FileOpen(filePathNuevaYork, FILE_WRITE | FILE_CSV | FILE_ANSI, ",");
        if (fileHandleNuevaYork != INVALID_HANDLE)
        {
            FileWrite(fileHandleNuevaYork, "Fecha", "Hora", "Activo", "Valor");
        }
        else
        {
            Print("Error al crear el archivo CSV en la ruta: ", filePathNuevaYork);
            Print("Código de error: ", GetLastError());
            return (INIT_FAILED);
        }
    }
    else
    {
        // Abrir el archivo existente en modo append
        fileHandleNuevaYork = FileOpen(filePathNuevaYork, FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI, ",");
        if (fileHandleNuevaYork == INVALID_HANDLE)
        {
            Print("Error al abrir el archivo CSV en la ruta: ", filePathNuevaYork);
            Print("Código de error: ", GetLastError());
            return (INIT_FAILED);
        }
        // Mover el puntero al final del archivo
        FileSeek(fileHandleNuevaYork, 0, SEEK_END);
    }*/

    return (INIT_SUCCEEDED); // Devolver 0 para indicar éxito
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Cerrar el archivo al finalizar
    if (fileHandleNuevaYork != INVALID_HANDLE)
    {
        FileClose(fileHandleNuevaYork);
    }

    // Llamar a la función para encontrar el valor mayor y menor
    FindMaxMinValues(region);
    Print("EA detenido. Razón: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Verificar si la hora actual está dentro del horario configurado
    if (isTrueNY)
    {
        // Print("Hora NY: ", hora_actual_servidor);

        //  Obtener la fecha y hora actual
        string fecha = TimeToString(serverTime, TIME_DATE);
        string hora = TimeToString(serverTime, TIME_SECONDS);

        // Obtener el símbolo (activo) y el valor del tick
        string activo = Symbol();
        double valor = SymbolInfoDouble(activo, SYMBOL_BID); // Usamos el precio BID

        // Escribir los datos en el archivo CSV
        if (fileHandleNuevaYork != INVALID_HANDLE)
        {
            string line = StringFormat("%s,%s,%s,%.5f", fecha, hora, activo, valor);
            // Print("valor: ", line);
            FileWrite(fileHandleNuevaYork, line);
        }
        else
        {
            Print("Error: El archivo no está abierto.");
        }
    }
}

//+------------------------------------------------------------------+
//| Modificación             |
//+------------------------------------------------------------------+

void OnTimer()
{
    if (input_activar_operativa_newyork)
    {
        // Hora New York
        serverTime = TimeCurrent();
        hora_actual_servidor = serverTime + ajuste_tiempo;
    }
    else
    {
        // Servidor
        hora_actual_servidor = TimeCurrent();
        // hora_actual_servidor = D'2025.02.04 10:20:05';
        // Print(hora_actual_servidor);
    }

    ComprobarSesionOperativa();
}

// Función para separar la hora y los minutos
bool SepararHoraMinuto(const string &time_str, int &hora, int &minuto)
{
    // Encontrar la posición del separador ":"
    int separator_index = StringFind(time_str, ":", 0);

    if (separator_index == -1) // Si no se encuentra el separador ":"
    {
        Print("Formato de hora incorrecto. Debe ser 'HH:MM'.");
        return false; // Retornar falso si el formato es incorrecto
    }

    // Extraer la parte de la hora (antes del ":")
    string str_hora = StringSubstr(time_str, 0, separator_index);
    hora = (int)StringToInteger(str_hora); // Convertir a entero

    // Extraer la parte de los minutos (después del ":")
    string str_minuto = StringSubstr(time_str, separator_index + 1);
    minuto = (int)StringToInteger(str_minuto); // Convertir a entero

    // Validar que la hora y los minutos estén dentro de rangos válidos
    if (hora < 0 || hora > 23 || minuto < 0 || minuto > 59)
    {
        Print("Hora o minuto fuera de rango. Hora debe estar entre 0 y 23, y minutos entre 0 y 59.");
        return false; // Retornar falso si la hora o los minutos están fuera de rango
    }
    return true; // Retornar verdadero si todo está correcto
}

// #1 - Función para comprobar si la hora actual está dentro de una sesión operativa
bool ComprobarSesionOperativa()
{

    // Llamar a la función para separar y validar la hora y los minutos
    SepararHoraMinuto(input_ny_hora, input_ny_desde_hora, input_ny_desde_minuto);

    // Llamar a la función para separar y validar la hora y los minutos
    SepararHoraMinuto(input_londres_hora, input_londres_desde_hora, input_londres_desde_minuto);

    // Llamar a la función para separar y validar la hora y los minutos
    SepararHoraMinuto(input_asia_hora, input_asia_desde_hora, input_asia_desde_minuto);

    // Fin  para separar y validar la hora y los minutos
    SepararHoraMinuto(hasta_ny_hora, input_ny_hasta_hora, input_ny_hasta_minuto);

    // Fin  para separar y validar la hora y los minutos
    SepararHoraMinuto(hasta_londres_hora, input_londres_hasta_hora, input_londres_hasta_minuto);

    // Fin  para separar y validar la hora y los minutos
    SepararHoraMinuto(hasta_asia_hora, input_asia_hasta_hora, input_asia_hasta_minuto);

    // Print("Hora server: ", hora_actual_servidor);
    MqlDateTime fecha_hora_ny;

    // Obtener los componentes de la hora actual de Nueva York

    TimeToStruct(hora_actual_servidor, fecha_hora_ny);

    // Obtener la hora y minutos actuales en Nueva York
    int hora_ny = fecha_hora_ny.hour;
    int minuto_ny = fecha_hora_ny.min;
    int dia_semana_ny = fecha_hora_ny.day_of_week;

    // Print(hora_ny," : ",minuto_ny," DIA:",dia_semana_ny);

    // Definir los rangos de tiempo para cada sesión (ahora con horas y minutos)
    bool sesion_asia = (dia_semana_ny >= 0 && dia_semana_ny <= 6) &&
                       ((hora_ny > input_asia_desde_hora ||
                         (hora_ny == input_asia_desde_hora && minuto_ny >= input_asia_desde_minuto)) &&
                        (hora_ny < input_asia_hasta_hora ||
                         (hora_ny == input_asia_hasta_hora && minuto_ny < input_asia_hasta_minuto)));

    bool sesion_londres = (dia_semana_ny >= 0 && dia_semana_ny <= 6) &&
                          ((hora_ny > input_londres_desde_hora ||
                            (hora_ny == input_londres_desde_hora && minuto_ny >= input_londres_desde_minuto)) &&
                           (hora_ny < input_londres_hasta_hora ||
                            (hora_ny == input_londres_hasta_hora && minuto_ny < input_londres_hasta_minuto)));

    bool sesion_ny = (dia_semana_ny >= 0 && dia_semana_ny <= 6) &&
                     ((hora_ny > input_ny_desde_hora ||
                       (hora_ny == input_ny_desde_hora && minuto_ny >= input_ny_desde_minuto)) &&
                      (hora_ny < input_ny_hasta_hora ||
                       (hora_ny == input_ny_hasta_hora && minuto_ny < input_ny_hasta_minuto)));

    // Print("sesion_ny: ",sesion_londres);

    // Verificar si la sesión de Asia ha iniciado
    if (!sesion_asia_iniciada && sesion_asia)
    {

        if (input_operativa_asia)
        {
            Print("----------| Sesion de Asia Iniciada |----------");
        }
        sesion_asia_iniciada = true;
        sesion_asia_finalizada = false;
    }

    // Verificar si la sesión de Asia ha finalizado
    if (!sesion_asia_finalizada && !sesion_asia)
    {

        if (input_operativa_asia)
        {

            Print("----------| Sesion de Asia Finalizada |----------");
            region = "Asia";
        }

        // FindMaxMinValues(region);

        sesion_asia_finalizada = true;
        sesion_asia_iniciada = false;
    }

    // Verificar si la sesión de Londres ha iniciado
    if (!sesion_londres_iniciada && sesion_londres)
    {

        if (input_operativa_londres)
        {
            Print("----------| Sesion de Londres Iniciada |----------");
        }

        sesion_londres_finalizada = false;
        sesion_londres_iniciada = true;
    }

    // Verificar si la sesión de Londres ha finalizado
    if (!sesion_londres_finalizada && !sesion_londres)
    {
        if (input_operativa_londres)
        {

            Print("----------| Sesion de Londres Finalizada |----------");
            region = "Londres";
            // FindMaxMinValues(region);
        }

        sesion_londres_finalizada = true;
        sesion_londres_iniciada = false;
    }

    // Verificar si la sesión de Nueva York ha iniciado

    if (!sesion_ny_iniciada && sesion_ny)
    {
        if (input_operativa_newyork)
        {
            isTrueNY = true; // se habilita la escritura
            hora_inicio_newY = serverTime;
            Print("----------| Sesion de Nueva York Iniciada |----------", hora_actual_servidor);
        }
        sesion_ny_finalizada = false;
        sesion_ny_iniciada = true;
    }

    // Verificar si la sesión de Nueva York ha finalizado

    if (!sesion_ny_finalizada && !sesion_ny)
    {

        if (input_operativa_newyork)
        {
            // Llamar a la función para encontrar el valor mayor y menor
            /*
            if (fileHandleNuevaYork  != INVALID_HANDLE)
            {
                FileClose(fileHandleNuevaYork );
            }*/
            isTrueNY = false;
            Print("----------| Sesion de NY Finalizada |----------", hora_actual_servidor);
            hora_fin_newY = serverTime;
            string dataDirectory = TerminalInfoString(TERMINAL_DATA_PATH); // Obtiene el directorio de datos del terminal
            // Concatenamos el directorio de datos con la ruta relativa
            string fullPath = dataDirectory + "\\" + relativePath;

            Print("La ruta completa es: ", fullPath);
            region = "NY";
        }

        sesion_ny_finalizada = true;
        sesion_ny_iniciada = false;
    }
    return sesion_ny;
}

datetime ConvertStringToTime(string dateStr, string timeStr)
{
    // Combinar fecha y hora en un solo string
    string dateTimeStr = dateStr + " " + timeStr;

    // Convertir la cadena a datetime
    return StringToTime(dateTimeStr);
}

//+------------------------------------------------------------------+
//| Función principal para encontrar la primera y última fecha       |
//+------------------------------------------------------------------+
void FindMaxMinValues(string &regions)
{
    // Abrir como archivo de texto normal
    fileHandleNuevaYork = FileOpen(filePathNuevaYork, FILE_READ | FILE_TXT | FILE_ANSI);
    if (fileHandleNuevaYork != INVALID_HANDLE)
    {
        // Saltar la primera línea (encabezado)
        FileReadString(fileHandleNuevaYork);

        // Variables para almacenar los datos por día
        datetime currentDay = 0;
        datetime firstTimeOfDay = 0;
        datetime lastTimeOfDay = 0;
        double maxValueOfDay = -DBL_MAX;
        double minValueOfDay = DBL_MAX;

        // Leer el archivo línea por línea
        while (!FileIsEnding(fileHandleNuevaYork))
        {
            // Leer una línea completa
            string line = FileReadString(fileHandleNuevaYork);
            StringTrimRight(line);
            StringTrimLeft(line);

            if (StringLen(line) == 0)
                continue;

            // Dividir la línea por comas
            string columns[];
            int numColumns = StringSplit(line, ',', columns);

            if (numColumns >= 4)
            {
                // Obtener la fecha y la hora de las columnas 0 y 1
                datetime currentTime = ConvertStringToTime(columns[0], columns[1]);

                // Obtener el día actual
                datetime day = StringToTime(columns[0]);

                // Si es un nuevo día, dibujar el rectángulo del día anterior y reiniciar las variables
                if (day != currentDay)
                {
                    if (currentDay != 0)
                    {
                        // Dibujar el rectángulo para el día anterior
                        DibujarRectangulo(firstTimeOfDay, lastTimeOfDay, maxValueOfDay, minValueOfDay);
                    }

                    // Reiniciar las variables para el nuevo día
                    currentDay = day;
                    firstTimeOfDay = currentTime;
                    lastTimeOfDay = currentTime;
                    maxValueOfDay = StringToDouble(columns[3]);
                    minValueOfDay = StringToDouble(columns[3]);
                }
                else
                {
                    // Actualizar lastTimeOfDay con la fecha actual
                    lastTimeOfDay = currentTime;

                    // Obtener el valor de la columna 3
                    double valor = StringToDouble(columns[3]);

                    // Actualizar valores máximo y mínimo del día
                    if (valor > maxValueOfDay)
                    {
                        maxValueOfDay = valor;
                    }
                    if (valor < minValueOfDay)
                    {
                        minValueOfDay = valor;
                    }
                }
            }
        }

        // Dibujar el rectángulo para el último día
        if (currentDay != 0)
        {
            DibujarRectangulo(firstTimeOfDay, lastTimeOfDay, maxValueOfDay, minValueOfDay);
        }

        FileClose(fileHandleNuevaYork);
    }
    else
    {
        Print("Error al abrir el archivo. Código de error: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Función para dibujar un rectángulo en el gráfico                 |
//+------------------------------------------------------------------+
void DibujarRectangulo(datetime startTime, datetime endTime, double maxValue, double minValue)
{
    string rectName = "MaxMinRect_" + TimeToString(startTime, TIME_DATE); // Nombre único del objeto

    // Crear el rectángulo
    if (ObjectCreate(0, rectName, OBJ_RECTANGLE, 0, startTime, maxValue, endTime, minValue))
    {
        // Configurar las propiedades del rectángulo
        ObjectSetInteger(0, rectName, OBJPROP_COLOR, clrRed);      // Color del rectángulo
        ObjectSetInteger(0, rectName, OBJPROP_WIDTH, 2);           // Grosor de la línea
        ObjectSetInteger(0, rectName, OBJPROP_STYLE, STYLE_SOLID); // Estilo de la línea
        ObjectSetInteger(0, rectName, OBJPROP_BACK, true);         // Dibujar en el fondo
        Print("Rectángulo dibujado correctamente para el día: ", TimeToString(startTime, TIME_DATE));
    }
    else
    {
        Print("Error al dibujar el rectángulo. Código de error: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Obtener la diferencia horaria entre el servidor y UTC   |
//+------------------------------------------------------------------+
int GetNewYorkTime()
{
    // datetime serverTime = StringToTime("2025.03.19 16:36:12.333");

    // Obtener la hora actual del servidor (broker)
    serverTime = TimeCurrent();
    // Obtener la diferencia horaria entre el servidor y UTC
    int serverOffset = ajuste_horario * 3600; // 7200; // Diferencia en segundos entre el servidor y UTC
    // Print(serverOffset);
    //  Convertir la hora del servidor a UTC
    datetime utcTime = serverTime - serverOffset; // Restar el desplazamiento

    // Determinar si Nueva York está en horario de verano (DST)
    bool isDST = IsNewYorkDST(utcTime);
    Print("Nueva York en DST: ", isDST);

    // Calcular el desplazamiento de Nueva York respecto a UTC
    int nyOffset = isDST ? -4 * 3600 : -5 * 3600; // -4 horas en verano, -5 horas en invierno
    // Print(nyOffset);
    //  Calcular la hora de Nueva York
    int nyTime = nyOffset - serverOffset;
    // Print(nyTime);
    return nyTime;
}

//------------------------------------------------------------------+
//| // Obtener el mes y el día del año  |está en DST=true o false
//+------------------------------------------------------------------+
bool IsNewYorkDST(datetime utcTime)
{
    // Obtener el mes y el día del año
    MqlDateTime mqlTime;
    TimeToStruct(utcTime, mqlTime);
    int month = mqlTime.mon;
    int day = mqlTime.day;
    int dayOfWeek = mqlTime.day_of_week; // 0 (domingo) a 6 (sábado)

    // Determinar si estamos en horario de verano (DST) en Nueva York
    if (month > 3 && month < 11)
    {
        return true; // Está en DST (abril a octubre)
    }
    else if (month == 3)
    {
        // Segundo domingo de marzo
        int secondSunday = (14 - dayOfWeek) % 7 + 7;
        if (day >= secondSunday)
        {
            return true;
        }
    }
    else if (month == 11)
    {
        // Primer domingo de noviembre
        int firstSunday = (7 - dayOfWeek) % 7 + 1;
        if (day < firstSunday)
        {
            return true;
        }
    }
    return false; // No está en DST
}
//////////////////

//------------------------------------------------------------------+
//| // Función para inicializar un archivo CSV
//+------------------------------------------------------------------+

int InitializeCSVFile(string filePath, int &fileHandle)
{
    // Verificar si el archivo existe
    if (!FileIsExist(filePath))
    {
        // Crear el archivo y escribir el encabezado
        fileHandle = FileOpen(filePath, FILE_WRITE | FILE_CSV | FILE_ANSI, ",");
        if (fileHandle != INVALID_HANDLE)
        {
            FileWrite(fileHandle, "Fecha", "Hora", "Activo", "Valor");
        }
        else
        {
            Print("Error al crear el archivo CSV en la ruta: ", filePath);
            Print("Código de error: ", GetLastError());
            return (INIT_FAILED);
        }
    }
    else
    {
        // Abrir el archivo existente en modo append
        fileHandle = FileOpen(filePath, FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI, ",");
        if (fileHandle == INVALID_HANDLE)
        {
            Print("Error al abrir el archivo CSV en la ruta: ", filePath);
            Print("Código de error: ", GetLastError());
            return (INIT_FAILED);
        }
        // Mover el puntero al final del archivo
        FileSeek(fileHandle, 0, SEEK_END);
    }

    return (INIT_SUCCEEDED);
}