import json
import pandas as pd
from bs4 import BeautifulSoup
from datetime import datetime  # Importar datetime para manejo de horas

mes = 'html/2025/ene2025.html'
nombremes = 'json/ene2025'
nombremesc = 'csv/ene2025'

# Usando f-string para concatenar
nombrecsv = f"{nombremesc}.csv"
nombrejson = f"{nombremes}.json"  # Corregido para json

# Leer el archivo HTML
with open(mes, 'r', encoding='utf-8') as file:
    html = file.read()

# Parsear el contenido HTML con BeautifulSoup
soup = BeautifulSoup(html, 'html.parser')

# Encontrar la tabla de noticias
table = soup.find('table', class_='calendar__table')
if table is None:
    raise ValueError("No se encontró la tabla de calendario.")

# Inicializar una lista para almacenar los datos en formato JSON
json_data = []

# Variables para almacenar la fecha actual
current_date = None

# Inicializar una lista para almacenar los datos del CSV original
csv_data = []

# Función para convertir hora AM/PM a formato 24 horas
def convertir_hora_24(hora_am_pm):
    if hora_am_pm:
        try:
            # Convertir la hora AM/PM a formato de 24 horas
            hora_24 = datetime.strptime(hora_am_pm, "%I:%M%p").strftime("%H:%M")
            return hora_24
        except ValueError:
            # Si no se puede convertir, devolver la hora original
            return hora_am_pm
    return None

# Iterar sobre las filas de la tabla
for row in table.find_all('tr'):
    # Buscar la fecha en las filas de día
    if 'calendar__row--day-breaker' in row.get('class', []):
        date_cell = row.find('td', class_='calendar__cell')
        if date_cell:
            current_date = date_cell.get_text(strip=True)
            #print(f"Fecha encontrada: {current_date}")  # Depuración

    # Extraer datos de las filas de eventos
    if 'calendar__row' in row.get('class', []) and 'calendar__row--day-breaker' not in row.get('class', []):
        time = row.find('td', class_='calendar__time')
        time = time.get_text(strip=True) if time else None

        # Convertir la hora a formato 24 horas
        time_24 = convertir_hora_24(time)

        currency = row.find('td', class_='calendar__currency')
        currency = currency.get_text(strip=True) if currency else None

        impact = row.find('td', class_='calendar__impact')
        if impact:
            # Verificar el ícono de impacto y asignar el texto correspondiente
            impact_icon = impact.find('span', class_=True)  # Encuentra cualquier ícono
            if impact_icon:
                if 'icon--ff-impact-yel' in impact_icon.get('class', []):
                    impact = "Low"
                elif 'icon--ff-impact-gra' in impact_icon.get('class', []):
                    impact = "Non"
                elif 'icon--ff-impact-ora' in impact_icon.get('class', []):
                    impact = "Medium"
                elif 'icon--ff-impact-red' in impact_icon.get('class', []):
                    impact = "High"
                else:
                    impact = impact.get_text(strip=True)  # Valor por defecto si no coincide
            else:
                impact = impact.get_text(strip=True)
        else:
            impact = None

        event = row.find('td', class_='calendar__event')
        event = event.get_text(strip=True) if event else None

        detail = row.find('td', class_='calendar__detail')
        detail = detail.get_text(strip=True) if detail else None

        actual = row.find('td', class_='calendar__actual')
        actual = actual.get_text(strip=True) if actual else None

        forecast = row.find('td', class_='calendar__forecast')
        forecast = forecast.get_text(strip=True) if forecast else None

        previous = row.find('td', class_='calendar__previous')
        previous = previous.get_text(strip=True) if previous else None

        # Verificar si todos los campos (excepto la fecha) están vacíos
        if all(val is None or val == '' for val in [time_24, currency, impact, event, detail, actual, forecast, previous]):
            continue  # Omitir esta fila

        # Formatear la fecha y hora para el JSON
        #print(current_date,time_24)
        if current_date and time_24:
            #fecha_original=current_date+time_24
            # Convertimos la fecha original en un objeto datetime usando el formato adecuado
            #fecha_convertida = datetime.strptime(fecha_original, "%a%b %d %H:%M")

            # Convertimos la fecha al formato deseado "YYYY-MM-DD HH:MM:SS"
            #fecha_completa = fecha_convertida.strftime("%Y-%m-%d %H:%M:%S")
            
            # Diccionario para mapear nombres de meses abreviados a números
            meses = {
                "Jan": 1, "Feb": 2, "Mar": 3, "Apr": 4,
                "May": 5, "Jun": 6, "Jul": 7, "Aug": 8,
                "Sep": 9, "Oct": 10, "Nov": 11, "Dec": 12
            }

            # Extraer el mes y el día
            mes_abreviado = current_date[3:6]  # Extrae "Mar"
            dia = int(current_date[7:])        # Extrae "30"

            # Obtener el número del mes
            mes = meses.get(mes_abreviado)

            # Asignar el año (en este caso, 2025)
            año = 2025

            # Crear un objeto datetime
            fecha = datetime(year=año, month=mes, day=dia)

            # Formatear al formato deseado
            fecha_completa = fecha.strftime("%Y-%m-%d")

       
            print(time_24)
            # Si la hora es "All Day", reemplazar por "00:00:00"
            if time_24 in["All Day","Day 1","Day 2","Day 3","Day 4","Day 5","Day 6","Day 7","Tentative",
                          "Dec Data","Mar Data","Apr Data","Jan Data","17th June","24th June","Nov Data",
                          "Nov 3rd","May Data","June Data","July Data","June Data"]  :
                time_24 = "00:00:00"
            else:
                # Si la hora tiene formato "HH:MM", completar a "HH:MM:00"
                if len(time_24.split(":")) == 2:  # Verificar si solo tiene horas y minutos
                    time_24 += ":00"  # Agregar segundos

            # Concatenar fecha y hora
            fecha_time_24 = f"{fecha_completa} {time_24}"

            # Convertir a un objeto datetime para validar
            fecha_hora = datetime.strptime(fecha_time_24, "%Y-%m-%d %H:%M:%S")

            # Formatear al formato deseado (opcional, solo para asegurar el formato)
            fecha_completa = fecha_hora.strftime("%Y-%m-%d %H:%M:%S")

            print(fecha_completa)
       
            #fecha_completa = f"2025-{current_date.split()[1]} {time_24}"  # Ajusta el año según sea necesario
            #print(fecha_completa)

            
        else:
            fecha_completa

        # Crear el diccionario con la estructura deseada para JSON
        evento_dict = {
            "titulo": event,
            "activo": currency,
            "fecha": fecha_completa,
            "impacto": impact,
            "pronostico": forecast,
            "anterior": previous,
            "actual":actual
        }

        # Añadir el diccionario a la lista JSON
        json_data.append(evento_dict)

        # Añadir los datos a la lista del CSV original
        csv_data.append([fecha_completa, time_24, currency, impact, event, detail, actual, forecast, previous])

# Guardar los datos en un archivo JSON
with open(nombrejson, 'w', encoding='utf-8') as json_file:
    json.dump(json_data, json_file, ensure_ascii=False, indent=4)

print(f"Datos guardados en {nombrejson}")

# Crear un DataFrame con los datos del CSV original
df = pd.DataFrame(csv_data, columns=[
    'Date', 'Time', 'Currency', 'Impact', 'Event', 'Detail', 'Actual', 'Forecast', 'Previous'
])

# Guardar el DataFrame en un archivo CSV
df.to_csv(nombrecsv, index=False)

print(f"Datos guardados en {nombrecsv}")