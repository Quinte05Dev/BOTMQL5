input group "05. CONFIGURACION HORARIOS OPERATIVOS";
input group "Configuracion de NY:";

input bool input_operativa_newyork = true; // Permitir Operativa en NY
input string input_ny_hora = "10:10";      // Inicio horario NY (hora:minutos)
int input_ny_desde_hora;                   // Inicio horario NY (hora)
int input_ny_desde_minuto;                 // Inicio horario NY (minuto)
input string hasta_ny_hora = "15:10";      // Fin horario NY (hora:minutos)
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

// Handlers para los archivos hh, hl, ll, lh
int fileHandleHH = INVALID_HANDLE;
string csvFilePath="PatronesHHLLCSV.csv"; // Ruta del archivo CSV

string relativePath = "\\MQL5\\Files";
string region;

// Variables globales
string highLabels[];
string lowLabels[];

#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0
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
    InitializeCSVFileHH(csvFilePath, fileHandleHH); //hh, hl, ll, lh
  
    //Inicializar arrays hh, hl, ll, lh
    ArrayResize(highLabels, 0);
    ArrayResize(lowLabels, 0);

      

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
    Print("On de init");
    // Cerrar el archivo al finalizar
    if (fileHandleNuevaYork != INVALID_HANDLE)
    {
        FileClose(fileHandleNuevaYork);
        Print("Archivo CSV cerrado correctamente.");
    }

     // Cerrar el archivo si está abierto
     if(fileHandleHH != INVALID_HANDLE)
     {
         FileClose(fileHandleHH);
         Print("Archivo CSV cerrado correctamente.");
     }

    // Llamar a la función para encontrar el valor mayor y menor
    FindMaxMinValues(region);

   // Borrar todos los objetos creados
    DeleteAllLabels();
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
            
            if (fileHandleNuevaYork != INVALID_HANDLE)
            {
                FileClose(fileHandleNuevaYork);
                Print("Archivo CSV cerrado correctamente.");
            }
        
             // Cerrar el archivo si está abierto
             if(fileHandleHH != INVALID_HANDLE)
             {
                 FileClose(fileHandleHH);
                 Print("Archivo CSV cerrado correctamente.");
             }

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
        Print("Rectángulo dibujado y correctamente para el día: ", TimeToString(startTime, TIME_DATE));
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

bool InitializeCSVFile(string filePath, int &fileHandle)
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
            return false;
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
            return false;
        }
        // Mover el puntero al final del archivo
        FileSeek(fileHandle, 0, SEEK_END);
    }

    return true;
}



//Cálculo de HH, HL, LL, LH
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const datetime &time[], const double &open[],
                const double &high[], const double &low[], const double &close[], const long &tick_volume[],
                const long &volume[], const int &spread[]) {
    // Definir la fecha de inicio para crear etiquetas
    datetime start_date = D'2025.03.07 00:01';  // Modifica esta fecha según tu necesidad

    // Definir rango horario (formato 24 horas)
    // int hora_inicio = 8;  // 8 AM
    // int hora_fin = 16;    // 4 PM

    // Verificar que haya suficientes barras
    if (rates_total < 2) return (0);

    //Print("OnCalculate: rates_total=", rates_total, ", prev_calculated=", prev_calculated);

    // Determinar desde dónde recalcular
    int start;

    // Si es la primera vez que se calcula, procesar todas las barras desde la segunda
    if (prev_calculated == 0) {
        DeleteAllLabels();
        start = 1;  // Empezar desde la segunda barra
        //Print("Primera ejecución, analizando todas las velas desde la segunda barra");
    } else {
        // Solo calcular las nuevas barras, comenzando desde la última calculada previamente
        start = prev_calculated - 1;
        if (start < 1) start = 1;
        //Print("Recálculo, comenzando desde la barra: ", start);
    }

    // Recorrer las barras
    for (int i = start; i < rates_total; i++) {
        // Verificar si la barra es posterior a la fecha especificada
        if (time[i] < start_date) continue;

        // Verificar si la barra está dentro del rango horario deseado
        MqlDateTime bar_time;
        TimeToStruct(time[i], bar_time);

        // Comprobar si la hora está dentro del rango especificado
        if (bar_time.hour < int(input_ny_hora) || bar_time.hour >= int(hasta_ny_hora)) continue;

        string labelHigh = "High_" + IntegerToString(i);
        string labelLow = "Low_" + IntegerToString(i);

        // Eliminar etiquetas anteriores para esta barra (si existen)
        if (ObjectFind(0, labelHigh) >= 0) ObjectDelete(0, labelHigh);
        if (ObjectFind(0, labelLow) >= 0) ObjectDelete(0, labelLow);

        // Analizar patrones de altos (HH, HL)
        if (high[i] > high[i - 1]) {
            // Alto mayor que el anterior = HH (Higher High)
            CreateLabel(labelHigh, time[i], high[i], "HH", clrGreen);
           // Print("Barra ", i, ": HH creado en ", TimeToString(time[i]), " a precio ", high[i]);

            // Guardar referencia
            AddToArray(highLabels, labelHigh);

            // Guardar en CSV
            SavePatternToCSV(time[i], "HH", high[i]);

        } else {
            // Alto menor o igual que el anterior = HL (Higher Low)
            CreateLabel(labelHigh, time[i], high[i], "HL", clrRed);
           // Print("Barra ", i, ": HL creado en ", TimeToString(time[i]), " a precio ", high[i]);

            // Guardar referencia
            AddToArray(highLabels, labelHigh);
        }

        // Analizar patrones de bajos (LL, LH)
        if (low[i] < low[i - 1]) {
            // Bajo menor que el anterior = LL (Lower Low)
            CreateLabel(labelLow, time[i], low[i], "LL", clrRed);
            //Print("Barra ", i, ": LL creado en ", TimeToString(time[i]), " a precio ", low[i]);

            // Guardar referencia
            AddToArray(lowLabels, labelLow);
        } else {
            // Bajo mayor o igual que el anterior = LH (Lower High)
            CreateLabel(labelLow, time[i], low[i], "LH", clrGreen);
           // Print("Barra ", i, ": LH creado en ", TimeToString(time[i]), " a precio ", low[i]);

            // Guardar referencia
            AddToArray(lowLabels, labelLow);
        }
    }

    // Forzar actualización del gráfico
    ChartRedraw(0);

    //Print("Total de etiquetas activas: High=", ArraySize(highLabels), ", Low=", ArraySize(lowLabels));

    return (rates_total);
}

//+------------------------------------------------------------------+
//| Añadir un elemento a un array                                    |
//+------------------------------------------------------------------+
void AddToArray(string &arr[], string value)
{
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

//------------------------------------------------------------------+
//| // Función para inicializar un archivo CSV
//+------------------------------------------------------------------+

bool InitializeCSVFileHH(string csvFilePath2, int &fileHandleHH)
{
    // Verificar si el archivo existe
    if (!FileIsExist(csvFilePath2))
    {
        // Crear el archivo y escribir el encabezado
        fileHandleHH = FileOpen(csvFilePath2, FILE_WRITE | FILE_CSV | FILE_ANSI, ",");
        if (fileHandleHH != INVALID_HANDLE)
        {
            FileWrite(fileHandleHH, "Fecha", "Hora", "Patron", "Valor");
        }
        else
        {
            Print("Error al crear el archivo CSV en la ruta: ", csvFilePath2);
            Print("Código de error: ", GetLastError());
            return false;
        }
    }
    else
    {
        // Abrir el archivo existente en modo append
        fileHandleHH = FileOpen(csvFilePath2, FILE_READ | FILE_WRITE | FILE_CSV | FILE_ANSI, ",");
        if (fileHandleHH == INVALID_HANDLE)
        {
            Print("Error al abrir el archivo CSV en la ruta: ", csvFilePath2);
            Print("Código de error: ", GetLastError());
            return false;
        }
        // Mover el puntero al final del archivo
        FileSeek(fileHandleHH, 0, SEEK_END);
    }

    return true;
}

// Función para guardar un patrón en el archivo CSV
void SavePatternToCSV(datetime time, string patternType, double price)
{
    // Verificar que el archivo esté abierto
    if(fileHandleHH != INVALID_HANDLE)
    {
        // Extraer fecha y hora
        MqlDateTime dt;
        TimeToStruct(time, dt);
        
        string fecha = StringFormat("%04d.%02d.%02d", dt.year, dt.mon, dt.day);
        string hora = StringFormat("%02d:%02d:%02d", dt.hour, dt.min, dt.sec);
        
        // Obtener el símbolo actual
        string activo = Symbol();
        
        // Escribir la línea en el CSV
        FileWrite(fileHandleHH, fecha, hora, activo, patternType, DoubleToString(price, Digits()));
        
        // Forzar escritura en disco
        FileFlush(fileHandleHH);
    }
    else
    {
        Print("Error: Archivo CSV no abierto al intentar guardar un patrón.");
    }
}