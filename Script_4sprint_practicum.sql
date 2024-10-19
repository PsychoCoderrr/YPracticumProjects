/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Колдашев В.А.
 * Дата: 19.10.2024
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
	paying_users_category,
	all_users_category,
	ROUND(paying_users_category::NUMERIC / all_users_category, 2) AS share_of_paying_players
FROM all_count
JOIN paying_count USING(race);



-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:

SELECT
	COUNT(amount) AS count_of_purchases,
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
		COUNT(transaction_id) AS count_of_purchases,
		SUM(amount) AS total_sum
	FROM fantasy.events e 
	JOIN fantasy.users u USING(id) 
	WHERE amount <> 0
	GROUP BY payer
)
SELECT 
	payer,
	total_count_of_users,
	count_of_purchases,
	total_sum,
	ROUND(total_sum::NUMERIC / total_count_of_users, 2) AS avg_total_sum
FROM category_of_users
JOIN count_of_paying_users USING(payer);
	

-- 2.4: Популярные эпические предметы:

SELECT 
	game_items,
	COUNT(transaction_id) count_of_bought,
	COUNT(DISTINCT id) AS count_of_users,/*Мы понимаем, что один человек мог несколько раз купить определенный предмет, следовательно его id
						будет встречаться несколько раз*/
	ROUND(COUNT(DISTINCT id)::NUMERIC / (SELECT COUNT(id)
	FROM fantasy.users), 3) AS share_of_users
FROM fantasy.events
LEFT JOIN fantasy.items i USING(item_code)
WHERE amount <> 0
GROUP BY game_items
ORDER BY share_of_users DESC; /* так как доля линейно зависит от кол-ва пользователей, мы можем сортировать сразу по доле*/

-- Часть 2. Решение ad hoc-задач
-- Задача 1. Зависимость активности игроков от расы персонажа:

WITH all_registred_users AS 
(
	SELECT /* используется для подсчета всех игроков */
		race,
		COUNT(id) AS all_users
	FROM fantasy.users
	JOIN fantasy.race r USING(race_id)
	GROUP BY race
),
buyers AS ( /*используется для подсчета кол-ва игроков, которые совершают внутриигровые покупки*/
	SELECT 
		race,
		COUNT(DISTINCT id) unique_buyers
	FROM fantasy.events
	JOIN fantasy.users USING(id)
	JOIN fantasy.race USING(race_id)
	JOIN all_registred_users USING(race)
	GROUP BY race
),
paying_users AS ( /* используется для подсчета количества платящих игроков*/ 
	SELECT 
		race, 
		COUNT(id) AS paying_users
	FROM fantasy.users
	JOIN fantasy.race USING(race_id)
	WHERE payer = 1
	GROUP BY race
),
users_buy_information AS 
(
	SELECT 
		race,
		id,
		COUNT(transaction_id) AS count_of_purchases,
		AVG(amount) AS avg_solo_amount,
		SUM(amount) AS sum_amount_for_user
	FROM fantasy.events
	JOIN fantasy.users USING(id)
	JOIN fantasy.race USING(race_id)
	WHERE amount <> 0
	GROUP BY race, id
),
avg_users_but_information AS
(
	SELECT 
		race,
		ROUND(AVG(count_of_purchases)::NUMERIC, 2) AS avg_count_of_purchases_for_user,
		ROUND(AVG(avg_solo_amount)::NUMERIC, 2) AS avg_amount_for_user,
		ROUND(AVG(sum_amount_for_user)::NUMERIC, 2) AS avg_total_sum_for_user
	FROM users_buy_information
	GROUP BY race
)
SELECT
	u.race,
	all_users,
	unique_buyers,
	ROUND(unique_buyers::NUMERIC / all_users, 2) AS share_of_buying_users,
	paying_users,
	ROUND(paying_users::NUMERIC / unique_buyers, 2) AS share_of_paying_users,
	avg_count_of_purchases_for_user,
	avg_amount_for_user,
	avg_total_sum_for_user
FROM all_registred_users u
JOIN buyers b USING(race)
JOIN paying_users pu USING(race)
JOIN avg_users_but_information USING(race);

-- Задача 2: Частота покупок
-- Напишите ваш запрос здесь

WITH 
users_with_lead AS 
(
	SELECT 
		id,
		e.date,
		LEAD(e.date) OVER(PARTITION BY id ORDER BY e.date) next_date
	FROM fantasy.events e
),
avg_diff_between_date AS
(
	SELECT
		id,
		ROUND(AVG(next_date::date - date::date), 2) AS diff_in_days
	FROM users_with_lead
	WHERE next_date IS NOT NULL 
	GROUP BY id
),
user_count_of_transaction AS
(
	SELECT 
		id, 
		COUNT(transaction_id) count_of_purchases
	FROM fantasy.events
	GROUP BY id
),
user_information_and_ranking AS
(
	SELECT 
		id,
		count_of_purchases,
		diff_in_days,
		NTILE(3) OVER( ORDER BY count_of_purchases DESC, diff_in_days) named_ranking/*если оценивать частоту,
																						то я считаю, что самый хороший случай, 
																						когда человек делает много покупок и 
																						разность по времени у него минимальная*/
	FROM user_count_of_transaction
	JOIN avg_diff_between_date USING(id)/*у человека может быть одна покупка, его ну будет в таблице avg_diff_between_date,
										я считаю, что стоит исключить такого пользователя из выборки, т.к.
										мы не можем делать выводы о его активности*/								
),
avg_quantities AS 
(
	SELECT 
		named_ranking,
		COUNT(id) AS buying_users,
		AVG(count_of_purchases) AS avg_count_of_purchases_per_user,
		AVG(diff_in_days) AS avg_diff_between_dates_per_user
	FROM user_information_and_ranking
	GROUP BY named_ranking
),
paying_users_with_categories AS 
(
	SELECT
		named_ranking,
		COUNT(uiar.id) AS paying_users
	FROM user_information_and_ranking uiar
	JOIN fantasy.users u USING(id)
	WHERE u.payer = 1
	GROUP BY named_ranking
)
SELECT 
	aq.named_ranking,
	aq.buying_users,
	puwc.paying_users,
	ROUND(puwc.paying_users / aq.buying_users::NUMERIC, 2) AS share_of_paying_users,
	aq.avg_count_of_purchases_per_user,
	aq.avg_diff_between_dates_per_user
FROM avg_quantities aq
JOIN paying_users_with_categories puwc USING(named_ranking)
ORDER BY named_ranking;