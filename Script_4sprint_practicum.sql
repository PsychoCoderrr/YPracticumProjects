/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: 
 * Дата: 
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:


-- перед насписанием запроса отдельно проверили, сколько различных id 
--содержится в таблицах users и events, поняли, что в events уникальных 
--id меньше, следовательно, можем сделать вывод, что в events только те id, 
--которые совершали покупки, а в users вообще все id
SELECT
	COUNT(id) AS all_players,
	(SELECT COUNT(DISTINCT id) 
	FROM fantasy.events) AS paying_players,
	ROUND((SELECT COUNT(DISTINCT id) 
	FROM fantasy.events)::NUMERIC / COUNT(id), 2) AS share_of_paying_players
FROM fantasy.users;

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
-- Напишите ваш запрос здесь

WITH all_count AS 
(
	SELECT 
		race,
		COUNT(id) AS all_users_category
	FROM fantasy.users
	LEFT JOIN fantasy.race USING(race_id)
	GROUP BY race
),
paying_count AS
(
	SELECT
		r.race,
		COUNT(DISTINCT e.id) AS paying_users_category /*считаем именно по id из таблицы events, так же используем DISTINCT,
							 так как с одного id может совершаться несколько транзакций,
							 при подсчете id в таблице users DISTINCT нам не нужен, так как
							 там поле id является первичным ключом и соответственно не може повторяться*/
	FROM fantasy.events e
	LEFT JOIN fantasy.users u USING(id)
	LEFT JOIN fantasy.race r USING(race_id)
	GROUP BY race
)
SELECT 
	race,
	all_users_category,
	paying_users_category,
	ROUND(paying_users_category::NUMERIC / all_users_category, 2) AS share_of_paying_players
FROM all_count
JOIN paying_count USING(race);


-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
-- Напишите ваш запрос здесь


-- 2.2: Аномальные нулевые покупки:
-- Напишите ваш запрос здесь

-- 2.3: Сравнительный анализ активности платящих и неплатящих игроков:
-- Напишите ваш запрос здесь

-- 2.4: Популярные эпические предметы:
-- Напишите ваш запрос здесь

-- Часть 2. Решение ad hoc-задач
-- Задача 1. Зависимость активности игроков от расы персонажа:
-- Напишите ваш запрос здесь

-- Задача 2: Частота покупок
-- Напишите ваш запрос здесь
