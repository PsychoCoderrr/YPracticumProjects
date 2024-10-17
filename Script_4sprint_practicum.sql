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

SELECT 
	COUNT(id) AS all_player,
	(SELECT COUNT(id)
	FROM fantasy.users
	WHERE payer = 1) AS paying_players,
	ROUND((SELECT COUNT(id)
	FROM fantasy.users
	WHERE payer = 1)::NUMERIC / COUNT(id), 3) AS share_of_paying
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
		COUNT(id) AS paying_users_category 
	FROM fantasy.users u
	LEFT JOIN fantasy.race r USING(race_id)
	WHERE payer = 1
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

SELECT
	COUNT(amount) AS count_amount,
	SUM(amount) AS all_amount,
	MIN(amount) AS min_amount,
	MAX(amount) AS max_amount,
	ROUND(AVG(amount)::NUMERIC, 2) AS avg_amount,
	PERCENTILE_DISC(0.50) WITHIN GROUP (ORDER BY amount) AS median,
	ROUND(STDDEV(amount)::NUMERIC,2) AS standart_deviation
FROM fantasy.events;

-- 2.2: Аномальные нулевые покупки:
-- Напишите ваш запрос здесь
SELECT 
	(SELECT COUNT(amount) 
	FROM fantasy.events
	WHERE amount = 0 ) AS zero_count_amount,
	(SELECT COUNT(amount) 
	FROM fantasy.events
	WHERE amount = 0 )::NUMERIC / COUNT(amount) AS share_of_zero_amount
FROM fantasy.events;

-- 2.3: Сравнительный анализ активности платящих и неплатящих игроков:
-- Напишите ваш запрос здесь
WITH category_of_users AS
(
	SELECT 
		payer,
		COUNT(id) AS total_count_of_users
	FROM fantasy.users
	GROUP BY payer
),
count_of_paying_users AS 
(
	SELECT 
		payer,
		COUNT(transaction_id) AS count_of_paying_users,
		SUM(amount) AS total_sum
	FROM fantasy.events e 
	JOIN fantasy.users u USING(id) 
	GROUP BY payer
)
SELECT 
	payer,
	total_count_of_users,
	count_of_paying_users,
	total_sum,
	ROUND(total_sum::NUMERIC / count_of_paying_users, 2) AS avg_total_sum
FROM category_of_users
JOIN count_of_paying_users USING(payer);
	

-- 2.4: Популярные эпические предметы:

SELECT 
	game_items,
	COUNT(transaction_id) count_of_bought,
	COUNT(DISTINCT id) AS count_of_users,/*Мы понимаем, что один человек мог несколько раз купить определенный предмет, следовательно его id
						будет встречаться несколько раз*/
	COUNT(DISTINCT id)::NUMERIC / (SELECT COUNT(id)
	FROM fantasy.users) AS share_of_users
FROM fantasy.events
LEFT JOIN fantasy.items i USING(item_code)
GROUP BY game_items
ORDER BY share_of_users DESC; /* так как доля линейно зависит от кол-ва пользователей, мы можем сортировать сразу по доле*/

-- Часть 2. Решение ad hoc-задач
-- Задача 1. Зависимость активности игроков от расы персонажа:

SELECT


-- Задача 2: Частота покупок
-- Напишите ваш запрос здесь
