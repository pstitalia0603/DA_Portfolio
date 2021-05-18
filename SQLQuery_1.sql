--REFERENCE: https://towardsdatascience.com/an-ultimate-guide-to-azure-data-studio-6bc2b53db93


--SELECT * FROM LinuxDB..[owid-covid-deaths] order BY 3,4


--SELECT * FROM LinuxDB..[covid-vaccs] order BY 3,4

--Select the data that we are going to be using
SELECT Location,date,total_cases, new_cases,total_deaths,population
FROM LinuxDB..[owid-covid-deaths]
ORDER BY 1,2

-- looking at the total cases vs total deaths, percentage
--shows likelihood of dying if you contract covid in your country
SELECT Location,date,total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM LinuxDB..[owid-covid-deaths]
WHERE location like '%states%'
ORDER BY 1,2

--looking at total cases vs population
--shows what percentage of population has gotten covid
SELECT Location,date, population,total_cases, (total_cases/population)*100 AS PopulationPercentage
FROM LinuxDB..[owid-covid-deaths]
--WHERE location like '%states%'
ORDER BY 1,2

--how to change column datatype
--ALTER TABLE LinuxDB..[owid-covid-deaths] ALTER COLUMN total_cases BIGINT;

--what countries have highest infection rates compared to population
SELECT Location,population,MAX(total_cases) AS HighestInfectionCount,MAX((total_cases/population))*100 AS PercentPopInfected
FROM LinuxDB..[owid-covid-deaths]
--WHERE location like '%states%'
GROUP By Location,population
ORDER BY PercentPopInfected Desc


-- how many people died by country, highest death count per population
SELECT Location, MAX(cast(Total_deaths as int)) AS TotalDeathCount
FROM LinuxDB..[owid-covid-deaths]
--WHERE location like '%states%'
WHERE continent is not null 
GROUP By Location
ORDER BY TotalDeathCount Desc

--BREAK DOWN BY CONTINENT
SELECT Continent, MAX(cast(Total_deaths as int)) AS TotalDeathCount
FROM LinuxDB..[owid-covid-deaths]
--WHERE location like '%states%'
WHERE continent is not null 
GROUP By continent
ORDER BY TotalDeathCount Desc

--correct continent counts
--showing continents with highest death count per population
SELECT Location, MAX(cast(Total_deaths as int)) AS TotalDeathCount
FROM LinuxDB..[owid-covid-deaths]
--WHERE location like '%states%'
WHERE continent is null 
GROUP By Location
ORDER BY TotalDeathCount Desc

-- global numbers across world, by date
SELECT date,SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int))as totalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM LinuxDB..[owid-covid-deaths] 
--WHERE location like '%states%' and 
WHERE continent is not null
GROUP By date
ORDER BY 1,2

-- global numbers across world, as of 5/15/21
SELECT SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int))as totalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM LinuxDB..[owid-covid-deaths] 
--WHERE location like '%states%' and 
WHERE continent is not null
--GROUP By date
ORDER BY 1,2

--COVID VACCINATIONS

--looking at total population vs vaccinations per day
-- running sum of vaccinations (AS RUNNINGSUMVACC)
SELECT dea.continent,dea.[location],dea.[date],dea.population, vac.new_vaccinations,
SUM(Convert(int,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,dea.date) as RUNNINGSUMVACC,
FROM LinuxDB..[owid-covid-deaths] dea
JOIN LinuxDB..[covid-vaccs] vac
    ON dea.location=vac.location
    AND dea.date = vac.date
WHERE dea.continent is not null
order BY 2,3

-- USE CTE
With PopvsVac (Continent,location,date,population,new_vaccinations,RUNNINGSUMVACC)
as 
(
SELECT dea.continent,dea.[location],dea.[date],dea.population, vac.new_vaccinations,
SUM(Convert(int,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,dea.date) as RUNNINGSUMVACC
--, (RUNNINGSUMVACC/population)*100
FROM LinuxDB..[owid-covid-deaths] dea
JOIN LinuxDB..[covid-vaccs] vac
    ON dea.location=vac.location
    AND dea.date = vac.date
WHERE dea.continent is not null
--order BY 2,3
)
SElect *, (RUNNINGSUMVACC/population)*100 as percentageVACC from PopvsVac


--with temp table
DROP Table if exists #PercentPopulationVaccinated 
CREATE Table #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    location NVARCHAR(255),
    date datetime,
    population numeric,
    new_vaccinations numeric,
    RUNNINGSUMVACC numeric
)
INSERT into #PercentPopulationVaccinated
SELECT dea.continent,dea.[location],dea.[date],dea.population, vac.new_vaccinations,
SUM(Convert(int,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,dea.date) as RUNNINGSUMVACC
--, (RUNNINGSUMVACC/population)*100
FROM LinuxDB..[owid-covid-deaths] dea
JOIN LinuxDB..[covid-vaccs] vac
    ON dea.location=vac.location
    AND dea.date = vac.date
WHERE dea.continent is not null
--order BY 2,3

Select *, (RUNNINGSUMVACC/population)*100 
as percentageVACC 
from #PercentPopulationVaccinated


--create a view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated as
    SELECT dea.continent,dea.[location],dea.[date],dea.population, vac.new_vaccinations,
    SUM(Convert(int,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,dea.date) as RUNNINGSUMVACC
    FROM LinuxDB..[owid-covid-deaths] dea
JOIN LinuxDB..[covid-vaccs] vac
    ON dea.location=vac.location
    AND dea.date = vac.date
WHERE dea.continent is not null
--order BY 2,3


select * from PercentPopulationVaccinated