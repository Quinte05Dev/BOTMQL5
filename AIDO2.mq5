input group "05. CONFIGURACION HORARIOS OPERATIVOS";
input group "Configuracion de NY:";

input bool input_operativa_newyork = true; // Permitir Operativa en NY
input string input_ny_hora = "10:10";      // Inicio horario NY (hora:minutos)
int input_ny_desde_hora;                   // Inicio horario NY (hora)
int input_ny_desde_minuto;                 // Inicio horario NY (minuto)
input string hasta_ny_hora = "12:10";      // Fin horario NY (hora:minutos)
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
int input_asia_hasta_minuto;             // Fin horario Asia (minuto)

int ajuste_tiempo; // Ajuste de tiempo

input group "Configuracion operativas:";
input group "-------------------";
input bool input_activar_operativa_newyork = true; // Trabajar Operativa en NY
input bool input_activar_operativa_londres = false; // Trabajar Operativa en Londres
input bool input_activar_operativa_asia = false; // Trabajar Operativa en Asia
input int ajuste_horario = 2; // Ajuste horario

bool sesion_asia_iniciada = true;
bool sesion_asia_finalizada = false;

bool sesion_ny_iniciada = true;
bool sesion_ny_finalizada = false;

bool sesion_londres_iniciada = true;
bool sesion_londres_finalizada = false;

bool isTrueNY = false;
bool isTrueLondres = false;
bool isTrueAsia = false;

// Comprobar si la hora actual está dentro de alguna de las sesiones operativas habilitadas
bool global_operar_asia;
bool global_operar_londres;
bool global_operar_ny;

datetime hora_actual_servidor;
datetime hora_inicio_newY;
datetime hora_fin_newY;
datetime hora_inicio_londres;
datetime hora_fin_londres;
datetime hora_inicio_asia;
datetime hora_fin_asia;
datetime serverTime;
int hora_nya;   // Variable para almacenar la hora
int minuto_nya; // Variable para almacenar los minutos

// Handlers para los archivos
int fileHandleAsia = INVALID_HANDLE;
int fileHandleLondres = INVALID_HANDLE;
int fileHandleNuevaYork = INVALID_HANDLE; // Variable global para el manejador del archivo

// Rutas de archivos CSV para cada sesión
string filePathAsia = "operaciones_asia.csv";
string filePathLondres = "operaciones_londres.csv";
string filePathNuevaYork = "operaciones_nueva_york.csv";

string relativePath = "\\MQL5\\Files";
string region;

// Variables globales
string highLabels[];
string lowLabels[];

// Variables globales para almacenar los valores máximos y mínimos
double g_maxValueOfDay_NY = -DBL_MAX;
double g_minValueOfDay_NY = DBL_MAX;
bool g_valuesInitialized_NY = false;
bool g_rupturaDetectada_NY = false;

double g_maxValueOfDay_Londres = -DBL_MAX;
double g_minValueOfDay_Londres = DBL_MAX;
bool g_valuesInitialized_Londres = false;
bool g_rupturaDetectada_Londres = false;

double g_maxValueOfDay_Asia = -DBL_MAX;
double g_minValueOfDay_Asia = DBL_MAX;
bool g_valuesInitialized_Asia = false;
bool g_rupturaDetectada_Asia = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Mensaje de éxito
    Print("EA inicializado correctamente.");
    ajuste_tiempo = GetNewYorkTime();
    EventSetTimer(1);

    // Inicializar archivos CSV para cada sesión
    if(input_operativa_newyork) 
        InitializeCSVFile(filePathNuevaYork, fileHandleNuevaYork);
    
    if(input_operativa_londres)
        InitializeCSVFile(filePathLondres, fileHandleLondres);
    
    if(input_operativa_asia)
        InitializeCSVFile(filePathAsia, fileHandleAsia);

    // Inicializar arrays
    ArrayResize(highLabels, 0);
    ArrayResize(lowLabels, 0);   

    return (INIT_SUCCEEDED); // Devolver 0 para indicar éxito
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Cerrar todos los archivos abiertos
    if (fileHandleNuevaYork != INVALID_HANDLE)
    {
        FileClose(fileHandleNuevaYork);
    }
    
    if (fileHandleLondres != INVALID_HANDLE)
    {
        FileClose(fileHandleLondres);
    }
    
    if (fileHandleAsia != INVALID_HANDLE)
    {
        FileClose(fileHandleAsia);
    }

    // Liberar la memoria de los arrays
    ArrayFree(highLabels);
    ArrayFree(lowLabels);
    Print("EA detenido. Razón: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Verificar si está en horario de alguna de las sesiones
    if (isTrueNY && input_operativa_newyork)
    {
        ProcesarTick(fileHandleNuevaYork);
    }
    else if (isTrueLondres && input_operativa_londres)
    {
        ProcesarTick(fileHandleLondres);
    }
    else if (isTrueAsia && input_operativa_asia)
    {
        ProcesarTick(fileHandleAsia);
    }
    else
    {
        // Detectar ruptura con el precio actual según la sesión previa
        double precioActual = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        
        if(!g_rupturaDetectada_NY && g_valuesInitialized_NY)
        {
            DetectarRuptura(precioActual, g_maxValueOfDay_NY, g_minValueOfDay_NY, g_rupturaDetectada_NY, "Nueva York");
        }
        
        if(!g_rupturaDetectada_Londres && g_valuesInitialized_Londres)
        {
            DetectarRuptura(precioActual, g_maxValueOfDay_Londres, g_minValueOfDay_Londres, g_rupturaDetectada_Londres, "Londres");
        }
        
        if(!g_rupturaDetectada_Asia && g_valuesInitialized_Asia)
        {
            DetectarRuptura(precioActual, g_maxValueOfDay_Asia, g_minValueOfDay_Asia, g_rupturaDetectada_Asia, "Asia");
        }
    }
}

// Función para procesar ticks y escribir en archivo correspondiente
void ProcesarTick(int fileHandle)
{
    //  Obtener la fecha y hora actual
    string fecha = TimeToString(serverTime, TIME_DATE);
    string hora = TimeToString(serverTime, TIME_SECONDS);

    // Obtener el símbolo (activo) y el valor del tick
    string activo = Symbol();
    double valor = SymbolInfoDouble(activo, SYMBOL_BID); // Usamos el precio BID

    // Escribir los datos en el archivo CSV
    if (fileHandle != INVALID_HANDLE)
    {
        string line = StringFormat("%s,%s,%s,%.5f", fecha, hora, activo, valor);
        FileWrite(fileHandle, line);
    }
    else
    {
        Print("Error: El archivo no está abierto.");
    }
}

// Nueva función para detectar ruptura de máximos o mínimos
void DetectarRuptura(double precioActual, double maxValue, double minValue, bool &rupturaDetectada, string nombreRegion) {
    if (!rupturaDetectada) {
        // Detectar ruptura hacia arriba
        if (precioActual > maxValue) {
            Print("¡RUPTURA ALCISTA en ", nombreRegion, "! El precio actual ", precioActual, " ha superado el máximo previo de ", maxValue);
            rupturaDetectada = true; // Marcamos que ya se detectó una ruptura
            // Aquí puedes agregar código para realizar acciones específicas en caso de ruptura alcista
        }
        
        // Detectar ruptura hacia abajo
        if (precioActual < minValue) {
            Print("¡RUPTURA BAJISTA en ", nombreRegion, "! El precio actual ", precioActual, " ha caído por debajo del mínimo previo de ", minValue);
            rupturaDetectada = true; // Marcamos que ya se detectó una ruptura
            // Aquí puedes agregar código para realizar acciones específicas en caso de ruptura bajista
        }
    }
}

//+------------------------------------------------------------------+
//| Inicializar archivo CSV                                          |
//+------------------------------------------------------------------+
void InitializeCSVFile(string filePath, int &fileHandle)
{
    // Cerrar el archivo si ya está abierto
    if (fileHandle != INVALID_HANDLE)
    {
        FileClose(fileHandle);
    }
    
    // Abrir o crear el archivo en modo escritura
    fileHandle = FileOpen(filePath, FILE_WRITE | FILE_CSV | FILE_ANSI);
    
    if (fileHandle != INVALID_HANDLE)
    {
        // Escribir encabezados del CSV
        FileWrite(fileHandle, "Fecha", "Hora", "Activo", "Valor");
        Print("Archivo CSV inicializado: ", filePath);
    }
    else
    {
        Print("Error al abrir/crear el archivo ", filePath, ". Código de error: ", GetLastError());
    }
}

//+------------------------------------------------------------------+
//| Timer event handler                                              |
//+------------------------------------------------------------------+
void OnTimer()
{
    if (input_activar_operativa_newyork || input_activar_operativa_londres || input_activar_operativa_asia)
    {
        // Hora ajustada según la configuración
        serverTime = TimeCurrent();
        hora_actual_servidor = serverTime + ajuste_tiempo;
    }
    else
    {
        // Servidor sin ajuste
        hora_actual_servidor = TimeCurrent();
    }

    ComprobarSesionOperativa();
    // Solicitar un recálculo del indicador
    ChartRedraw();
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

//+------------------------------------------------------------------+
//| Función para obtener el tiempo de Nueva York                     |
//+------------------------------------------------------------------+
int GetNewYorkTime()
{
    // Implementar la lógica para obtener el ajuste horario para Nueva York
    return ajuste_horario * 3600; // Convertir horas a segundos
}

// #1 - Función para comprobar si la hora actual está dentro de una sesión operativa
bool ComprobarSesionOperativa()
{
    // Separar y validar todas las horas configuradas
    SepararHoraMinuto(input_ny_hora, input_ny_desde_hora, input_ny_desde_minuto);
    SepararHoraMinuto(hasta_ny_hora, input_ny_hasta_hora, input_ny_hasta_minuto);
    
    SepararHoraMinuto(input_londres_hora, input_londres_desde_hora, input_londres_desde_minuto);
    SepararHoraMinuto(hasta_londres_hora, input_londres_hasta_hora, input_londres_hasta_minuto);
    
    SepararHoraMinuto(input_asia_hora, input_asia_desde_hora, input_asia_desde_minuto);
    SepararHoraMinuto(hasta_asia_hora, input_asia_hasta_hora, input_asia_hasta_minuto);

    MqlDateTime fecha_hora;
    TimeToStruct(hora_actual_servidor, fecha_hora);

    // Obtener la hora y minutos actuales
    int hora_actual = fecha_hora.hour;
    int minuto_actual = fecha_hora.min;
    int dia_semana = fecha_hora.day_of_week;

    // Definir los rangos de tiempo para cada sesión
    bool sesion_asia = (dia_semana >= 0 && dia_semana <= 6) &&
                       ((hora_actual > input_asia_desde_hora ||
                         (hora_actual == input_asia_desde_hora && minuto_actual >= input_asia_desde_minuto)) &&
                        (hora_actual < input_asia_hasta_hora ||
                         (hora_actual == input_asia_hasta_hora && minuto_actual < input_asia_hasta_minuto)));

    bool sesion_londres = (dia_semana >= 0 && dia_semana <= 6) &&
                          ((hora_actual > input_londres_desde_hora ||
                            (hora_actual == input_londres_desde_hora && minuto_actual >= input_londres_desde_minuto)) &&
                           (hora_actual < input_londres_hasta_hora ||
                            (hora_actual == input_londres_hasta_hora && minuto_actual < input_londres_hasta_minuto)));

    bool sesion_ny = (dia_semana >= 0 && dia_semana <= 6) &&
                     ((hora_actual > input_ny_desde_hora ||
                       (hora_actual == input_ny_desde_hora && minuto_actual >= input_ny_desde_minuto)) &&
                      (hora_actual < input_ny_hasta_hora ||
                       (hora_actual == input_ny_hasta_hora && minuto_actual < input_ny_hasta_minuto)));

    // ----- Gestión de sesión Asia -----
    if (!sesion_asia_iniciada && sesion_asia && input_operativa_asia)
    {
        Print("----------| Sesion de Asia Iniciada |----------");
        isTrueAsia = true;
        hora_inicio_asia = serverTime;
        sesion_asia_iniciada = true;
        sesion_asia_finalizada = false;
        
        // Inicializar el archivo CSV para Asia
        InitializeCSVFile(filePathAsia, fileHandleAsia);
    }

    if (!sesion_asia_finalizada && !sesion_asia && input_operativa_asia)
    {
        Print("----------| Sesion de Asia Finalizada |----------");
        isTrueAsia = false;
        hora_fin_asia = serverTime;
        sesion_asia_finalizada = true;
        sesion_asia_iniciada = false;
        
        // Cerrar el archivo si está abierto
        if (fileHandleAsia != INVALID_HANDLE)
        {
            FileClose(fileHandleAsia);
            fileHandleAsia = INVALID_HANDLE;
        }
        
        // Procesar datos de Asia
        region = "Asia";
        FindMaxMinValues(filePathAsia, g_maxValueOfDay_Asia, g_minValueOfDay_Asia, g_valuesInitialized_Asia);
        g_rupturaDetectada_Asia = false;
    }

    // ----- Gestión de sesión Londres -----
    if (!sesion_londres_iniciada && sesion_londres && input_operativa_londres)
    {
        Print("----------| Sesion de Londres Iniciada |----------",hora_actual_servidor);
        isTrueLondres = true;
        hora_inicio_londres = serverTime;
        sesion_londres_iniciada = true;
        sesion_londres_finalizada = false;
        
        // Inicializar el archivo CSV para Londres
        InitializeCSVFile(filePathLondres, fileHandleLondres);
    }

    if (!sesion_londres_finalizada && !sesion_londres && input_operativa_londres)
    {
        Print("----------| Sesion de Londres Finalizada |----------",hora_actual_servidor);
        isTrueLondres = false;
        hora_fin_londres = serverTime;
        sesion_londres_finalizada = true;
        sesion_londres_iniciada = false;
        
        // Cerrar el archivo si está abierto
        if (fileHandleLondres != INVALID_HANDLE)
        {
            FileClose(fileHandleLondres);
            fileHandleLondres = INVALID_HANDLE;
        }
        
        // Procesar datos de Londres
        region = "Londres";
        FindMaxMinValues(filePathLondres, g_maxValueOfDay_Londres, g_minValueOfDay_Londres, g_valuesInitialized_Londres);
        g_rupturaDetectada_Londres = false;
    }

    // ----- Gestión de sesión Nueva York -----
    if (!sesion_ny_iniciada && sesion_ny && input_operativa_newyork)
    {
        Print("----------| Sesion de Nueva York Iniciada |----------", hora_actual_servidor);
        isTrueNY = true;
        hora_inicio_newY = serverTime;
        sesion_ny_iniciada = true;
        sesion_ny_finalizada = false;
        
        // Inicializar el archivo CSV para NY
        InitializeCSVFile(filePathNuevaYork, fileHandleNuevaYork);
    }

    if (!sesion_ny_finalizada && !sesion_ny && input_operativa_newyork)
    {
        Print("----------| Sesion de NY Finalizada |----------", hora_actual_servidor);
        isTrueNY = false;
        hora_fin_newY = serverTime;
        sesion_ny_finalizada = true;
        sesion_ny_iniciada = false;
        
        // Cerrar el archivo si está abierto
        if (fileHandleNuevaYork != INVALID_HANDLE)
        {
            FileClose(fileHandleNuevaYork);
            fileHandleNuevaYork = INVALID_HANDLE;
        }
        
        // Procesar datos de NY
        region = "NY";
        FindMaxMinValues(filePathNuevaYork, g_maxValueOfDay_NY, g_minValueOfDay_NY, g_valuesInitialized_NY);
        g_rupturaDetectada_NY = false;
    }

    return (isTrueNY || isTrueLondres || isTrueAsia);
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
void FindMaxMinValues(string filePath, double &maxValueOfDay, double &minValueOfDay, bool &valuesInitialized)
{
    // Determinar la región basándose en el nombre del archivo
    string regionName = "";
    if(StringFind(filePath, "NY") >= 0 || StringFind(filePath, "Nueva") >= 0)
        regionName = "NY";
    else if(StringFind(filePath, "Londres") >= 0)
        regionName = "Londres";
    else if(StringFind(filePath, "Asia") >= 0)
        regionName = "Asia";
    else
        regionName = region; // Usar la variable global region si no puede determinarse

    // Abrir como archivo de texto normal
    int fileHandle = FileOpen(filePath, FILE_READ | FILE_TXT | FILE_ANSI);
    if (fileHandle != INVALID_HANDLE)
    {
        // Saltar la primera línea (encabezado)
        FileReadString(fileHandle);

        // Variables para almacenar los datos por día
        datetime currentDay = 0;
        datetime firstTimeOfDay = 0;
        datetime lastTimeOfDay = 0;
        maxValueOfDay = -DBL_MAX;
        minValueOfDay = DBL_MAX;

        // Leer el archivo línea por línea
        while (!FileIsEnding(fileHandle))
        {
            // Leer una línea completa
            string line = FileReadString(fileHandle);
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
                        // Dibujar el rectángulo para el día anterior, pasando la región
                        DibujarRectangulo(firstTimeOfDay, lastTimeOfDay, maxValueOfDay, minValueOfDay, regionName);
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
            Print("Valor minimo: ", minValueOfDay);
            Print("Valor maximo: ", maxValueOfDay);
            DibujarRectangulo(firstTimeOfDay, lastTimeOfDay, maxValueOfDay, minValueOfDay, regionName);
            valuesInitialized = true;
        }

        FileClose(fileHandle);
    }
    else
    {
        Print("Error al abrir el archivo ", filePath, ". Código de error: ", GetLastError());
    }
}


//+------------------------------------------------------------------+
//| Función para dibujar un rectángulo en el gráfico                 |
//+------------------------------------------------------------------+
void DibujarRectangulo(datetime startTime, datetime endTime, double maxValue, double minValue, string region)
{
    string rectName = "MaxMinRect_" + region + "_" + TimeToString(startTime, TIME_DATE); // Nombre único del objeto
    color colorRectangulo;
    
    // Asignar color según la región
    if(region == "NY" || region == "Nueva York")
        colorRectangulo = clrDodgerBlue;      // Azul para Nueva York
    else if(region == "Londres")
        colorRectangulo = clrMagenta;         // Magenta para Londres
    else if(region == "Asia")
        colorRectangulo = clrGold;            // Dorado para Asia
    else
        colorRectangulo = clrRed;             // Rojo por defecto
    
    // Crear el rectángulo
    if (ObjectCreate(0, rectName, OBJ_RECTANGLE, 0, startTime, maxValue, endTime, minValue))
    {
        // Configurar las propiedades del rectángulo
        ObjectSetInteger(0, rectName, OBJPROP_COLOR, colorRectangulo); // Color según región
        ObjectSetInteger(0, rectName, OBJPROP_WIDTH, 2);               // Grosor de la línea
        ObjectSetInteger(0, rectName, OBJPROP_STYLE, STYLE_SOLID);     // Estilo de la línea
        ObjectSetInteger(0, rectName, OBJPROP_BACK, true);             // Dibujar en el fondo
        Print("Rectángulo dibujado correctamente para la sesión de ", region, " el día: ", TimeToString(startTime, TIME_DATE));
    }
    else
    {
        Print("Error al dibujar el rectángulo. Código de error: ", GetLastError());
    }
}
//+------------------------------------------------------------------+
//| Añadir un elemento a un array                                    |
//+------------------------------------------------------------------+
void AddToArray(string &arr[], string value)
{
   // Verificar si el valor ya existe en el array
   for(int i = 0; i < ArraySize(arr); i++)
   {
      if(arr[i] == value)
         return; // Ya existe, no hacer nada
   }
   
   // Si no existe, agregarlo
   int size = ArraySize(arr);
   ArrayResize(arr, size + 1);
   arr[size] = value;
}
//+------------------------------------------------------------------+
//| Eliminar todas las etiquetas                                     |
//+------------------------------------------------------------------+
void DeleteAllLabels() {
    for (int i = 0; i < ArraySize(highLabels); i++)
        if (ObjectFind(0, highLabels[i]) >= 0) ObjectDelete(0, highLabels[i]);

    for (int i = 0; i < ArraySize(lowLabels); i++)
        if (ObjectFind(0, lowLabels[i]) >= 0) ObjectDelete(0, lowLabels[i]);

    ArrayResize(highLabels, 0);
    ArrayResize(lowLabels, 0);

    Print("Todas las etiquetas eliminadas");
}

//+------------------------------------------------------------------+
//| Función para crear una etiqueta de texto                         |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Función para crear una etiqueta de texto                         |
//+------------------------------------------------------------------+
void CreateLabel(string name, datetime time, double price, string text, color clr)
{
   if(!ObjectCreate(0, name, OBJ_TEXT, 0, time, price))
   {
      int error = GetLastError();
      Print("Error al crear objeto ", name, ": ", error);
      return;
   }
   
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_UPPER);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 100); // Mostrar encima de otros objetos
}