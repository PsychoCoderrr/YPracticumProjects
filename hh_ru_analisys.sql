--Определите диапазон заработных плат в общем, а именно средние значения, минимумы и максимумы нижних и верхних порогов зарплаты.

--Выявите регионы и компании, в которых сосредоточено наибольшее количество вакансий.

--Проанализируйте, какие преобладают типы занятости, а также графики работы.

--Изучите распределение грейдов (Junior, Middle, Senior) среди аналитиков данных и системных аналитиков.

--Выявите основных работодателей, предлагаемые зарплаты и условия труда для аналитиков.

--Определите наиболее востребованные навыки (как жёсткие, так и мягкие) для различных грейдов и позиций.




/*SELECT MIN(salary_from) AS min_of_salary, -- запрос для вычисления диапазонов заработных плат
	MAX(salary_to) AS max_of_salary,
	ROUND(AVG(salary_from),2) AS avg_min,
	ROUND(AVG(salary_to), 2) AS avg_max
FROM public.parcing_table;*/

/*SELECT *
FROM public.parcing_table
LIMIT 10;*/

/*SELECT area, COUNT(id) --запрос для вычисления распределения по городам
FROM public.parcing_table
GROUP BY area
ORDER BY COUNT(id) DESC;*/

/*SELECT employer, COUNT(id)
FROM public.parcing_table
GROUP BY employer
ORDER BY COUNT(id) DESC;*/

/*SELECT schedule, --запрос для вычисления преобладающих графиков работы
	COUNT(id)
FROM public.parcing_table
GROUP BY schedule
ORDER BY COUNT(id) DESC;*/

/*SELECT employment, 
 	COUNT(id)
FROM public.parcing_table
GROUP BY employment
ORDER BY COUNT(id) DESC;*/

/*SELECT experience, -- запрос для вычисления распределения по грейдам
	COUNT(id),
	ROUND((COUNT(id)::NUMERIC * 100) / (
	SELECT COUNT(id)
	FROM public.parcing_table
	WHERE name LIKE '%Аналитик данных%' OR name LIKE '%Системный аналитик%'), 2) AS percentage_count /*вложенный запрос используется для поиска общенго кол-ва)*/
FROM public.parcing_table
WHERE name LIKE '%Аналитик данных%' OR name LIKE '%Системный аналитик%'
GROUP BY experience
ORDER BY COUNT(id) DESC;*/

/*SELECT employer, -- запрос для выявления основных работодателей
	COUNT(id),
	ROUND(AVG(salary_from), 2) AS avg_salary_from,
	ROUND(AVG(salary_to), 2) AS avg_salary_to,
	employment
FROM public.parcing_table
GROUP BY employer, employment
ORDER BY COUNT(id) DESC;*/

/*SELECT key_skills_1, -- запрос для выявления востребованных хард-скилов
	COUNT(id)
FROM public.parcing_table
GROUP BY key_skills_1
ORDER BY COUNT(id) DESC;*/

/*SELECT soft_skills_1, -- запрос для выявления востребованных софт-скилов
	COUNT(id)
FROM public.parcing_table
GROUP BY soft_skills_1
ORDER BY COUNT(id) DESC;*/
