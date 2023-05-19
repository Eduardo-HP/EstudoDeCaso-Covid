# Dados Importados via linha de comando

# Estudo de caso Covid-19 - Mortes e Vacinação

# Total de registros
SELECT COUNT(*) FROM c19.covid_mortes;
SELECT COUNT(*) FROM c19.covid_vacinacao;

# Alterando data para o formato adequado
SET SQL_SAFE_UPDATES = 0;

UPDATE c19.covid_mortes 
SET date = str_to_date(date,'%d/%m/%y');

UPDATE c19.covid_vacinacao 
SET date = str_to_date(date,'%d/%m/%y');

SET SQL_SAFE_UPDATES = 1;

# Média de mortos por país
# Análise univariada
SELECT location,
       AVG(total_deaths) AS MediaMortos
FROM c19.covid_mortes 
GROUP BY location
ORDER BY MediaMortos DESC;

# Proporção de mortes em relação ao total de casos no Brasil
# Análise multivariada
SELECT date,
		location,
        total_cases,
        total_deaths,
        (total_deaths / total_cases) * 100 AS PercentualMortes
FROM c19.covid_mortes
WHERE location = "Brazil"
ORDER BY 2,1;

# Proporção média entre o total de casos e a população de cada localidade
SELECT location,
        AVG((total_cases / population) * 100) AS PercentualPopulacao
FROM c19.covid_mortes
GROUP BY location
ORDER BY PercentualPopulacao DESC;

# Países com maior taxa de infecção em relação à população considerando o maior valor do total de casos
SELECT location,
		MAX(total_cases) AS MaiorContagemInfec,
        MAX((total_cases / population)) * 100 AS PercentualPopulacao
FROM c19.covid_mortes
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentualPopulacao DESC;

# Países com maior número de mortes
SELECT location,
		MAX(total_deaths * 1) AS MaiorContagemMortes
FROM c19.covid_mortes
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY MaiorContagemMortes DESC;

# Continentes com o maior número de mortes
SELECT continent,
		MAX(CAST(total_deaths AS UNSIGNED)) AS MaiorContagemMortes
FROM c19.covid_mortes
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY MaiorContagemMortes DESC;

# Percentual de mortes por dia
SELECT date,
		SUM(new_cases) AS total_cases,
        SUM(CAST(new_deaths AS UNSIGNED)) AS total_deaths,
        COALESCE((SUM(CAST(new_deaths AS UNSIGNED)) / SUM(new_cases)) * 100, 'NA') AS PorcentMortes
FROM c19.covid_mortes
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

# Número de novos vacinados e média móvel de novos vacinados ao longo do tempo por localidade
SELECT mortos.location,
       mortos.date,
       vacinados.new_vaccinations,
       AVG(CAST(vacinados.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY mortos.location ORDER BY mortos.date) as MediaMovelVacinados
FROM c19.covid_mortes mortos 
JOIN c19.covid_vacinacao vacinados
ON mortos.location = vacinados.location 
AND mortos.date = vacinados.date
ORDER BY 2,3;

# Número de novos vacinados e total de novos vacinados ao longo do tempo por continente
# Considerando apenas dados da América do Sul
SELECT mortos.continent,
		mortos.date,
        vacinados.new_vaccinations,
        SUM(CAST(vacinados.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY mortos.continent ORDER BY mortos.date) AS TotalVacinados
FROM c19.covid_mortes mortos
JOIN c19.covid_vacinacao vacinados
ON mortos.location = vacinados.location
AND mortos.date = vacinados.date
WHERE mortos.continent = 'South America'
ORDER BY 1,2;

# Número de novos vacinados e total de novos vacinados ao longo do tempo (por mês - data no formato January/2020) por continente
# Considerando apenas dados da América do Sul
SELECT mortos.continent,
       DATE_FORMAT(mortos.date, "%M/%Y") AS MES,
       vacinados.new_vaccinations,
       SUM(CAST(vacinados.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY mortos.continent ORDER BY DATE_FORMAT(mortos.date, "%M/%Y")) as TotalVacinados
FROM c19.covid_mortes mortos 
JOIN c19.covid_vacinacao vacinados
ON mortos.location = vacinados.location 
AND mortos.date = vacinados.date
WHERE mortos.continent = 'South America'
ORDER BY 1,2;

# Percentual da população com pelo menos 1 dose da vacina ao longo do tempo no Brasil
WITH PopvsVac (continent,location, date, population, new_vaccinations, TotalMovelVacinacao) AS
(
SELECT mortos.continent,
       mortos.location,
       mortos.date,
       mortos.population,
       vacinados.new_vaccinations,
       SUM(CAST(vacinados.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY mortos.location ORDER BY mortos.date) AS TotalMovelVacinacao
FROM c19.covid_mortes mortos 
JOIN c19.covid_vacinacao vacinados 
ON mortos.location = vacinados.location 
AND mortos.date = vacinados.date
WHERE mortos.location = 'Brazil'
)
SELECT *, (TotalMovelVacinacao / population) * 100 AS Percentual_1_Dose FROM PopvsVac;

# Durante o mês de Maio/2021 o percentual de vacinados com pelo menos uma dose aumentou ou diminuiu no Brasil?
WITH PopvsVac (continent, location, date, population, new_vaccinations, TotalMovelVacinacao) AS
(
SELECT mortos.continent,
       mortos.location,
       mortos.date,
       mortos.population,
       vacinados.new_vaccinations,
       SUM(CAST(vacinados.new_vaccinations AS UNSIGNED)) OVER (PARTITION BY mortos.location ORDER BY mortos.date) AS TotalMovelVacinacao
FROM c19.covid_mortes mortos 
JOIN c19.covid_vacinacao vacinados 
ON mortos.location = vacinados.location 
AND mortos.date = vacinados.date
WHERE mortos.location = 'Brazil'
)
SELECT *, (TotalMovelVacinacao / population) * 100 AS Percentual_1_Dose 
FROM PopvsVac
WHERE DATE_FORMAT(date, "%M/%Y") = 'May/2021'
AND location = 'Brazil';