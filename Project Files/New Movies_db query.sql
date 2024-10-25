USE Movies_db;

-------------------------------------------------------------------
SELECT * FROM Netflix_cast;
SELECT * FROM Netflix_country;
SELECT * FROM Netflix_director;
SELECT * FROM Netflix_listed_in;
SELECT * FROM Netflix_Movies;
---------------------------Analysis Netflix Movies--------------------------------

--1. Understanding what content is available in different countries--
--1. فهم المحتوى المتاح في بلدان مختلفة  ----
SELECT 
    c.country, 
    n.type, 
    COUNT(n.show_id) OVER (PARTITION BY c.country, n.type) AS content_count
FROM 
    Netflix_Movies AS n INNER JOIN Netflix_country AS c
	ON n.show_id = c.show_id
ORDER BY 
    country, content_count DESC;
---------------------------------------------------------------------------
--2. Identifying similar content by matching text-based features (matching titles)----
--2. تحديد المحتوى المشابه بمطابقة الميزات النصية (مطابقة العناوين) ---
--- Self Join in the Same Table ----
SELECT 
    N1.title AS Title_1, 
    N2.title AS Title_2,
    L1.listed_in AS Genre_1, 
    L2.listed_in AS Genre_2, 
    N1.release_year AS Year_1, 
    N2.release_year AS Year_2,
    C1.country AS Country_1, 
    C2.country AS Country_2
FROM 
    Netflix_Movies N1 INNER JOIN Netflix_listed_in L1
	ON N1.show_id = L1.show_id INNER JOIN Netflix_country C1
	ON N1.show_id = C1.show_id
INNER JOIN 
    Netflix_Movies N2 INNER JOIN Netflix_listed_in L2
	ON N2.show_id = L2.show_id INNER JOIN Netflix_country C2
	ON N2.show_id = C2.show_id 
    ON N1.show_id = N2.show_id 
    AND N1.title = N2.title
ORDER BY 
    N1.title;
---------------------------------------------------------------------------
--3. Network analysis of Actors/Directors: How often do actors and directors collaborate?--
--3. تحليل الشبكة بين الممثلين/المخرجين: عدد مرات التعاون بينهم  ---
SELECT DISTINCT
    d.director, 
    c.cast,n.type,
    COUNT(*) OVER (PARTITION BY d.director, c.cast) AS collaboration_count
FROM 
    Netflix_Movies AS n INNER JOIN Netflix_director AS d
	ON n.show_id = d.show_id INNER JOIN Netflix_cast AS c
	ON n.show_id = c.show_id
ORDER BY 
    collaboration_count DESC;
---------------------------------------------------------------------------
--4. Actors appearing in multiple shows (find the most frequent actors)--
--4. الممثلون الذين ظهروا في عدة عروض (العثور على الممثلين الأكثر تكرارًا) --
SELECT DISTINCT TOP 5
    c.cast,n.type, 
    COUNT(n.show_id) OVER (PARTITION BY c.cast) AS show_count
FROM 
    Netflix_cast AS c INNER JOIN Netflix_Movies AS n
	ON c.show_id = n.show_id
ORDER BY 
    show_count DESC;
---------------------------------------------------------------------------
--5. Directors who have worked on the most shows--
--5. المخرجون الذين عملوا على أكبر عدد من العروض --
SELECT  DISTINCT TOP 5
    d.director,n.type, 
    COUNT(n.show_id) OVER (PARTITION BY d.director) AS show_count
FROM 
    Netflix_Movies AS n INNER JOIN Netflix_director AS d
	ON N.show_id = d.show_id
ORDER BY 
    show_count DESC;
---------------------------------------------------------------------------
--6. Is Netflix more focused on TV Shows than movies in recent years? (Yearly analysis)---
--6. هل تركز Netflix على العروض التلفزيونية أكثر من الأفلام في السنوات الأخيرة؟ (تحليل سنوي) ---
SELECT DISTINCT
    release_year, 
    type, 
    COUNT(show_id) OVER (PARTITION BY release_year, type) AS content_count
FROM 
    Netflix_Movies --Amazon_Prime
WHERE 
    release_year >= (select max(release_year)
					from Netflix_Movies) - 5
ORDER BY 
    release_year DESC, content_count DESC;

---------------------------------------------------------------------------
--7. Find the top 5 genres that have the most content across all countries--
--7. العثور على أفضل 5 أنواع محتوى تحتوي على أكبر عدد من المحتويات عبر جميع البلدان --
--- Using common table expression (CTE) --
WITH GenreCounts AS (
    SELECT 
        listed_in, 
        COUNT(show_id) OVER (PARTITION BY listed_in) AS genre_count
    FROM 
        Netflix_listed_in
)
SELECT DISTINCT 
    listed_in, 
    genre_count
FROM 
    GenreCounts
ORDER BY 
    genre_count DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;

---------------------------------------------------------------------------
--8. Determine the First and Last show added by country--
--8. تحديد أول وآخر عرض تم إضافته حسب البلد  --
SELECT DISTINCT 
    c.country, 
    MIN(n.date_added) OVER (PARTITION BY c.country) AS First_show,
    MAX(n.date_added) OVER (PARTITION BY c.country) AS Last_show
FROM 
    Netflix_Movies AS n INNER JOIN Netflix_country AS c
	ON n.show_id = c.show_id
ORDER BY 
	c.country;
--------------------------------------------
/*select distinct country, title
from Netflix_Movies --Amazon_Prime
where country like '%,%'*/

---------------------------------------------------------------------------
--9. Actors who appear in the most diverse genres---
--9. الممثلون الذين يظهرون في أكثر الأنواع تنوعًا --
SELECT DISTINCT
    c.cast, 
    COUNT(l.listed_in) OVER (PARTITION BY c.cast) AS genre_variety 
FROM 
    Netflix_cast AS c INNER JOIN Netflix_listed_in AS l
	ON c.show_id = l.show_id
ORDER BY 
		genre_variety DESC;

---------------------------------------------------------------------------
--10. Which directors have the most variety in content (genres)?--
--10. المخرجون الذين لديهم أكبر تنوع في المحتوى (الأنواع) ---
SELECT DISTINCT
    d.director, 
    COUNT(l.listed_in) OVER (PARTITION BY d.director) AS genre_variety 
FROM 
    Netflix_director AS d INNER JOIN Netflix_listed_in AS l
	ON d.show_id = l.show_id 
ORDER BY 
    genre_variety DESC;
---------------------------------------------------------------------------

-----------For Test a Coding---------------
/*
select * from Netflix_Movies;
SELECT
    show_id,
    title,
    LTRIM(RTRIM(value)) AS New_Director_Column
FROM
    Netflix_Movies
CROSS APPLY
    STRING_SPLIT(director, ',');
---------------------------------------------------------------------------
SELECT
    show_id,
    title,
    LTRIM(RTRIM(value)) AS New_Country_Column
FROM
    Netflix_Movies
CROSS APPLY
    STRING_SPLIT(country, ',');
---------------------------------------------------------------------------
SELECT
    show_id,
    title,
    LTRIM(RTRIM(value)) AS New_Cast_Column
FROM
    Netflix_Movies
CROSS APPLY
    STRING_SPLIT(cast, ',');
---------------------------------------------------------------------------
SELECT
    show_id,
    title,
    LTRIM(RTRIM(value)) AS New_ListedIn_Column
FROM
    Netflix_Movies
CROSS APPLY
    STRING_SPLIT(listed_in, ',');
---------------------------------------------------------------------------


SELECT DISTINCT
    c.cast, 
    COUNT(l.listed_in) OVER (PARTITION BY c.cast) AS genre_variety 
FROM 
    Netflix_cast AS c INNER JOIN Netflix_listed_in AS l
	ON c.show_id = l.show_id
ORDER BY genre_variety DESC;

------------Another solution----------------

SELECT 
    c.cast, 
    COUNT(DISTINCT l.listed_in) AS genre_variety 
FROM 
    Netflix_cast AS c
	INNER JOIN Netflix_listed_in AS l
	ON c.show_id = l.show_id
GROUP BY c.cast
ORDER BY genre_variety  DESC;
*/