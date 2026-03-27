-- Data Cleaning

-- Steps:
-- 1. Remove Duplicates
-- 2. Standarized the Data (make sure spelling is correct, and the format is consistent)
-- 3. Remove NULL Values or Blank Values
-- 4. Remove Any Columns (unless you are working with large dataset, have to be caredul)

select *
from CovidProject..['CovidDeaths(CovidDeaths)$']
Where continent is not null
order by 3,4

--select *
--from CovidProject..['CovidVaccinations(CovidVaccinat$']
--order by 3,4

-- Select Data that we are going to be using and we explore the data (step 1)

select Location, date, total_cases, new_cases, total_deaths, population
from CovidProject..['CovidDeaths(CovidDeaths)$']
Where continent is not null
order by 1,2;

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from CovidProject..['CovidDeaths(CovidDeaths)$']
where location like '%states%'
order by 1,2;

-- Looking at Total Cases vs Total Population
-- Shows what percenatge of population got covid

select Location, date, population,total_cases, (total_cases/population)*100 as PercentPopulationInfected
from CovidProject..['CovidDeaths(CovidDeaths)$']
where location like '%states%'
and continent is not null
order by 1,2;


-- Looking at Countries with Highest Infection Rate compared to Population

select Location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
from CovidProject..['CovidDeaths(CovidDeaths)$']
--where location like '%states%'
group by Location, population
order by PercentPopulationInfected desc;


-- Showing Countries with Highest Death Count per Population

select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
from CovidProject..['CovidDeaths(CovidDeaths)$']
--where location like '%states%'
Where continent is not null
group by Location
order by TotalDeathCount desc;


-- LETS BRREAK THINGS DOWN BY CONTINENT

select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
from CovidProject..['CovidDeaths(CovidDeaths)$']
--where location like '%states%'
Where continent is not null
group by continent
order by TotalDeathCount desc;


-- Showing the continents with the highest death count per population

select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
from CovidProject..['CovidDeaths(CovidDeaths)$']
--where location like '%states%'
Where continent is not null
group by continent
order by TotalDeathCount desc;

-- GLOBAL NUMBERS (stopped at 50:22)

select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
from CovidProject..['CovidDeaths(CovidDeaths)$']
--where location like '%states%'
where continent is not null
--group by date
order by 1,2;

-- Looking at Total Population vs Vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Convert(int, vac.new_vaccinations)) Over (Partition by dea.Location order by dea.location, 
dea.date) as RollingPeopleVaccinated
, (RollingPeopleVaccinated/population) * 100
from CovidProject..['CovidDeaths(CovidDeaths)$'] dea
Join CovidProject..['CovidVaccinations(CovidVaccinat$'] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- Use Cte

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Convert(int, vac.new_vaccinations)) Over (Partition by dea.Location order by dea.location, 
dea.date) as RollingPeopleVaccinated
-- , (RollingPeopleVaccinated/population) * 100
from CovidProject..['CovidDeaths(CovidDeaths)$'] dea
Join CovidProject..['CovidVaccinations(CovidVaccinat$'] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *, (RollingPeopleVaccinated/Population) *100
from PopvsVac

-- Temp Table

Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)


Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Convert(int, vac.new_vaccinations)) Over (Partition by dea.Location order by dea.location, 
dea.date) as m
-- , (RollingPeopleVaccinated/population) * 100
from CovidProject..['CovidDeaths(CovidDeaths)$'] dea
Join CovidProject..['CovidVaccinations(CovidVaccinat$'] vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null
--order by 2,3

select *, (RollingPeopleVaccinated/Population) *100
from #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(Convert(int, vac.new_vaccinations)) Over (Partition by dea.Location order by dea.location, 
dea.date) as m
-- , (RollingPeopleVaccinated/population) * 100
from CovidProject..['CovidDeaths(CovidDeaths)$'] dea
Join CovidProject..['CovidVaccinations(CovidVaccinat$'] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select *
from PercentPopulationVaccinated