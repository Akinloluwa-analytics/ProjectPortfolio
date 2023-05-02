select *
from ProjectPortfolio..CovidDeaths
order by 3,4

--select *
--from ProjectPortfolio..CovidVaccinations
--order by 3,4

--selecting data to be used
select location, date, total_cases, new_cases, total_deaths, population
from ProjectPortfolio..CovidDeaths
order by 1,2

--Looking at the total cases vs total deaths
select location, date, total_cases, total_deaths, (total_deaths/total_cases)* 100 as DeathPercentage
from ProjectPortfolio..CovidDeaths
order by 1,2

alter table ProjectPortfolio..CovidDeaths
alter column total_cases float;

alter table ProjectPortfolio..CovidDeaths
alter column total_deaths float;

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from CovidDeaths
where location like '%Nigeria%'
order by 1,2

--Total cases vs population
--percentage of population that has covid
select location, date, population, total_cases, round(((total_cases/population)*100), 2) as DeathPercentage
from CovidDeaths
where location like '%states%'
order by 1,2


--Countries with high infection rate compared to population
select location, population, max(total_cases) as HighestInfectionCount, max(round(((total_cases/population)*100), 2)) as PercentagePopulationInfected
from CovidDeaths
group by location, population
order by PercentagePopulationInfected desc 

--Showing the countries with the highest death count per population
select location, max(Total_deaths) as TotalDeathCount
from CovidDeaths
where continent is not null
group by location
order by TotalDeathCount desc


--DETAILS BY CONTINENTS
select location, max(Total_deaths) as TotalDeathCount
from CovidDeaths
where continent is null
group by location
order by TotalDeathCount desc


--SELECT location, MAX(Total_deaths)
--FROM CovidDeaths
--WHERE continent IS NULL
--group by location


--showing continents with the highest death counts per population
select location, population, max (Total_deaths) as TotalDeathCount, round(((max(Total_deaths))/population)*100,2) as DeathCountPerPopulation
from CovidDeaths
group by location, population
order by DeathCountPerPopulation desc

select continent, max(convert(int, total_deaths)) as TotalDeathCount
from ProjectPortfolio..CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc




--GLOBAL NUMBERS

select date, sum(cast(new_cases as float)) as total_cases, sum(cast(new_deaths as float)) as total_deaths, round(sum(cast(new_deaths as float))/sum(cast(new_cases as float))*100,2) as DeathPercentage
from CovidDeaths
where continent is not null
group by date

--total population versus vaccination
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 1,2,3


--total population versus cummulative vaccination
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(convert(float, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 1,2,3

--To divide the RollingPeopleVAccinated by the population, to get % of people vaccinated
---we can't use RollingPeopleVAccinated/population, as it will give error, we have to use CTE or temp table
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(convert(float, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated--, RollingPeopleVaccinated/dea.population
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 1,2,3


-- using cte
with PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(convert(float, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
select * , round((RollingPeopleVaccinated/Population)*100,2) from
PopvsVac

--using temp table - error
drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
Continent nvarchar (255),
Location nvarchar (255),
Date date,
Population float,
New_vaccination float,
RollingPeopleVaccinated float
)

insert into #PercentPopulationVaccinated
select convert (varchar (50), dea.continent), convert(varchar(50), dea.location), convert (date, dea.date), convert (float, dea.population), convert (float, vac.new_vaccinations), sum(convert(float, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

select *, (RollingPeopleVaccinated/Population)*100
from #PercentPopulationVaccinated




--creating view to store data for later visualization
create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(convert(float, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated--, RollingPeopleVaccinated/dea.population
from CovidDeaths dea
join CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

