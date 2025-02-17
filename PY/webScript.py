from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import pandas as pd
from bs4 import BeautifulSoup

# Configurar Selenium (asegúrate de tener el driver correspondiente, como ChromeDriver)
driver = webdriver.Chrome()  # O usa otro navegador como Firefox

try:
    # URL de la página a scrapear
    url = "https://www.forexfactory.com/calendar?month=feb.2025"

    # Abrir la página
    driver.get(url)

    # Esperar a que la tabla de calendario esté presente en la página
    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.CLASS_NAME, "calendar__table"))
    )

    # Obtener el contenido de la página
    page_source = driver.page_source

    # Parsear el contenido HTML con BeautifulSoup
    soup = BeautifulSoup(page_source, 'html.parser')

    # Encontrar la tabla de noticias
    table = soup.find('table', class_='calendar__table')

    if table is None:
        raise ValueError("No se encontró la tabla de calendario.")

    # Inicializar una lista para almacenar los datos
    data = []

    # Variables para almacenar la fecha actual
    current_date = None

    # Iterar sobre las filas de la tabla
    for row in table.find_all('tr', class_='calendar__row'):
        # Verificar si es una fila de fecha (day-breaker)
        if 'calendar__row--day-breaker' in row.get('class', []):
            # Extraer la fecha de la fila de día
            date_cell = row.find('td', class_='calendar__cell')
            if date_cell:
                current_date = date_cell.get_text(strip=True)
            continue  # Saltar esta fila, ya que solo contiene la fecha

        # Obtener las celdas de la fila
        cells = row.find_all('td')

        # Verificar si la fila contiene suficientes celdas para ser un evento
        if len(cells) >= 8:  # Asegurarse de que haya al menos 8 celdas
            # Extraer los datos de cada celda
            time = cells[0].get_text(strip=True) if cells[0].get_text(strip=True) else ""
            currency = cells[2].get_text(strip=True) if cells[2].get_text(strip=True) else ""
            
            # Manejar el impacto de manera segura
            impact_span = cells[3].find('span')
            impact = impact_span['title'] if impact_span and 'title' in impact_span.attrs else "No Impact"
            
            detail = cells[4].get_text(strip=True) if cells[4].get_text(strip=True) else ""
            actual = cells[6].get_text(strip=True) if cells[6].get_text(strip=True) else ""
            forecast = cells[7].get_text(strip=True) if cells[7].get_text(strip=True) else ""
            previous = cells[8].get_text(strip=True) if cells[8].get_text(strip=True) else ""
            
            # Agregar los datos a la lista, incluyendo la fecha actual
            data.append([current_date, time, currency, impact, detail, actual, forecast, previous])
        else:
            print("Fila ignorada: no tiene suficientes celdas")

    # Crear un DataFrame con los datos
    df = pd.DataFrame(data, columns=['Date', 'Hora', 'Currency', 'Impact', 'Detail', 'Actual', 'Forecast', 'Previous'])

    # Guardar el DataFrame en un archivo CSV
    df.to_csv('noticias.csv', index=False)

    print("Datos guardados en noticias.csv")

except Exception as e:
    print(f"Ocurrió un error: {e}")

finally:
    # Cerrar el navegador
    driver.quit()