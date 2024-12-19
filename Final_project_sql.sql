/* Проект первого модуля: анализ данных для агентства недвижимости
 * Часть 2. Решаем ad hoc задачи
 * 
 * Автор: Колдашев Виталий Андреевич
 * Дата: 14.11.2024
 * Ссылка на GitHub: https://github.com/PsychoCoderrr/YPracticumProjects/blob/main/Final_project_sql.sql
*/

-- Пример фильтрации данных от аномальных значений
-- Определим аномальные значения (выбросы) по значению перцентилей:
-- Определим аномальные значения (выбросы) по значению перцентилей:
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    )
-- Выведем объявления без выбросов:
SELECT *
FROM real_estate.flats
WHERE id IN (SELECT * FROM filtered_id);


-- Задача 1: Время активности объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. Какие сегменты рынка недвижимости Санкт-Петербурга и городов Ленинградской области 
--    имеют наиболее короткие или длинные сроки активности объявлений?

-- 2. Какие характеристики недвижимости, включая площадь недвижимости, среднюю стоимость квадратного метра, 
--    количество комнат и балконов и другие параметры, влияют на время активности объявлений? 
--    Как эти зависимости варьируют между регионами?
-- 3. Есть ли различия между недвижимостью Санкт-Петербурга и Ленинградской области по полученным результатам?

-- Напишите ваш запрос здесь
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
),
information_with_categories AS
(
	SELECT 
		CASE 
			WHEN city_id = (SELECT 
								city_id
							FROM real_estate.city
							WHERE city = 'Санкт-Петербург')
			THEN 'Санкт-Петербург'
			ELSE 'ЛенОбл'
		END AS sp_or_not,
		*,
		ROUND((last_price::NUMERIC / total_area)::NUMERIC, 2) AS price_for_square_metr,
		CASE --видел пример как предлагалось сделать в подсказке, захотелось свою реализацию использовать для данной категоризации
			WHEN justify_days(days_exposition * INTERVAL '1 day') < '1 month'::INTERVAL
			THEN 'меньше месяца'
			WHEN justify_days(days_exposition * INTERVAL '1 day') < '3 months'::INTERVAL 
			THEN 'меньше 3 месяцев'
			WHEN justify_days(days_exposition * INTERVAL '1 day') < '6 month'::INTERVAL 
			THEN 'меньше полугода'
			WHEN justify_days(days_exposition * INTERVAL '1 day') >= '6 month'::INTERVAL 
			THEN 'больше полугода'
		END AS activity
	FROM real_estate.flats
	JOIN real_estate.advertisement USING(id)
	WHERE id IN (SELECT * FROM filtered_id) AND days_exposition IS NOT NULL AND type_id = (SELECT 
																								type_id
																							FROM real_estate.type 
																							WHERE type = 'город')
)
SELECT 
	sp_or_not AS Region,
	activity AS Segment_activity,
	ROUND(AVG(price_for_square_metr)::NUMERIC, 2) AS avg_price_for_square_metr,
	ROUND(AVG(total_area)::NUMERIC, 2) AS avg_area,
	PERCENTILE_DISC(0.5)
	WITHIN GROUP (ORDER BY rooms) AS median_room_count,
	PERCENTILE_DISC(0.5)
	WITHIN GROUP (ORDER BY balcony) AS median_balcony_count,
	PERCENTILE_DISC(0.5)
	WITHIN GROUP (ORDER BY floor) AS median_floor
FROM information_with_categories
WHERE price_for_square_metr IS NOT NULL 
	AND total_area IS NOT NULL
	AND rooms IS NOT NULL
	AND balcony IS NOT NULL
	AND floor IS NOT NULL
GROUP BY sp_or_not, activity
ORDER BY Region DESC, AVG(days_exposition); /* в сортировке используется здесь среднее, чтобы более красивая была сортировка 
												по сегментации*/


/*
-- Запрос для проверки правильности нахождения айди Санкт-Петербурга
SELECT 
	city_id
FROM real_estate.city
WHERE city = 'Санкт-Петербург'

-- Запрос для проверки правильности нахождения айди типа населенного пункта город
SELECT 
	type_id
FROM real_estate.type 
WHERE type = 'город'


--запрос для проверки правильности работы функции justify_days
WITH helpful AS 
(
SELECT 
	days_exposition,
	justify_days(days_exposition * INTERVAL '1 day') AS time_interval
FROM real_estate.advertisement
WHERE days_exposition IS NOT NULL
)
SELECT
	*,
	CASE 
		WHEN time_interval < '1 month'::INTERVAL 
		THEN 'меньше месяца'
		WHEN time_interval < '3 months'::INTERVAL 
		THEN 'меньше 3 месяцев'
		WHEN time_interval < '6 month'::INTERVAL 
		THEN 'меньше полугода'
		WHEN time_interval >= '6 month'::INTERVAL 
		THEN 'больше полугода'
	END
FROM helpful;
*/

-- Задача 2: Сезонность объявлений
-- Результат запроса должен ответить на такие вопросы:
-- 1. В какие месяцы наблюдается наибольшая активность в публикации объявлений о продаже недвижимости? 
--    А в какие — по снятию? Это показывает динамику активности покупателей.
-- 2. Совпадают ли периоды активной публикации объявлений и периоды, 
--    когда происходит повышенная продажа недвижимости (по месяцам снятия объявлений)?
-- 3. Как сезонные колебания влияют на среднюю стоимость квадратного метра и среднюю площадь квартир? 
--    Что можно сказать о зависимости этих параметров от месяца?

-- Напишите ваш запрос здесь
 
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
),
full_advertisement AS
(
	SELECT 
		*,
		ROUND(last_price::NUMERIC/total_area::NUMERIC, 2) AS price_for_square_metr,
		(first_day_exposition + days_exposition * INTERVAL '1 day')::DATE AS last_day_exposition,
		EXTRACT(MONTH FROM first_day_exposition) AS month_of_first_exposition,
		EXTRACT(MONTH FROM (first_day_exposition + days_exposition * INTERVAL '1 day')::DATE) AS month_of_sale_exposition
	FROM real_estate.advertisement 
	JOIN real_estate.flats USING(id)
	WHERE days_exposition IS NOT NULL AND id IN (SELECT * FROM filtered_id)
),
statistic_for_start AS 
(
	SELECT
		COUNT(id),
		month_of_first_exposition,
		RANK() OVER(ORDER BY COUNT(id) DESC) AS start_month_rank,
		ROUND(AVG(price_for_square_metr)::NUMERIC, 2) AS avg_square_price,
		ROUND(AVG(total_area)::NUMERIC, 2) AS avg_total_area
	FROM full_advertisement
	GROUP BY(month_of_first_exposition)
	ORDER BY start_month_rank
),
statistic_for_sale AS
(
	SELECT 
		COUNT(id),
		month_of_sale_exposition,
		RANK() OVER(ORDER BY COUNT(id) DESC) AS sale_month_rank
	FROM full_advertisement
	GROUP BY month_of_sale_exposition
	ORDER BY sale_month_rank
)
SELECT 
	month_of_first_exposition AS month,
	start_month_rank,
	sale_month_rank,
	avg_square_price,
	avg_total_area
FROM statistic_for_start strt
JOIN statistic_for_sale sl ON strt.month_of_first_exposition = sl.month_of_sale_exposition
ORDER BY @(start_month_rank - sale_month_rank) DESC; /* данном моменте подумал, что сортировка по разнице между рангами местами в ранге
														будет логичной, ведь с помощью этого мы можем увидеть месяцы, в которые кол-во 
														выставлений объявлений будет совпадать с кол-вом снятий объявлений*/ 







/* 
SELECT 
	*,
	(first_day_exposition + days_exposition * INTERVAL '1 day')::DATE AS last_day_exposition
FROM real_estate.advertisement 
WHERE days_exposition IS NOT NULL;
*/



-- Задача 3: Анализ рынка недвижимости Ленобласти
-- Результат запроса должен ответить на такие вопросы:
-- 1. В каких населённые пунктах Ленинградской области наиболее активно публикуют объявления о продаже недвижимости?
-- 2. В каких населённых пунктах Ленинградской области — самая высокая доля снятых с публикации объявлений? 
--    Это может указывать на высокую долю продажи недвижимости.
-- 3. Какова средняя стоимость одного квадратного метра и средняя площадь продаваемых квартир в различных населённых пунктах? 
--    Есть ли вариация значений по этим метрикам?
-- 4. Среди выделенных населённых пунктов какие пункты выделяются по продолжительности публикации объявлений? 
--    То есть где недвижимость продаётся быстрее, а где — медленнее.

-- Напишите ваш запрос здесь

WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
),
count_of_saled_advertisements AS 
(
	SELECT 
		city_id,
		COUNT(id) AS count_of_saled
	FROM  real_estate.advertisement
	JOIN real_estate.flats USING(id)
	WHERE days_exposition IS NOT NULL
	AND id IN (SELECT * FROM filtered_id)
	AND city_id <> (SELECT city_id FROM real_estate.city WHERE city = 'Санкт-Петербург')
	GROUP BY city_id
),
information_table AS
(
	SELECT
		city_id,
		COUNT(id) AS city_activity, --не забыть потом в основном запросе заджойнить таблицу выше и посчитать долю
		AVG(last_price / total_area) AS avg_price_for_square,
		AVG(total_area) AS avg_area,
		justify_days(ROUND(AVG(days_exposition)::NUMERIC)::int * INTERVAL '1 day') AS time_for_sale
	FROM real_estate.flats
	JOIN real_estate.city USING(city_id)
	JOIN real_estate.advertisement USING(id)
	JOIN count_of_saled_advertisements USING(city_id)
	WHERE id IN (SELECT * FROM filtered_id) 
	AND city_id <> (SELECT city_id FROM real_estate.city WHERE city = 'Санкт-Петербург')
	GROUP BY city_id
)
SELECT 
	city,
	city_activity,
	ROUND(count_of_saled::NUMERIC / city_activity::NUMERIC, 2) AS share_of_saled,
	ROUND(avg_price_for_square::NUMERIC, 2) AS avg_price_for_square,
	ROUND(avg_area::NUMERIC, 2) AS avg_area,
	time_for_sale
FROM information_table
JOIN real_estate.city USING(city_id)
JOIN count_of_saled_advertisements USING(city_id)
WHERE city_activity > 50 /*решил все-таки добавить данный фильтр, иначе при расчете доли проданных лидировали регионы, в которых было по 
							по 1-5 продаж, естественно это не очень объективно*/
ORDER BY time_for_sale  --изменяя поле, по которому проходит фильтрация, я получал ответы на поставленные вопросы
LIMIT 15;
	
	
	



