select * from netflix_raw
where title like '?%'

-- remove duplicates
select * from netflix_raw
where concat(upper(title),type) in (
select concat(upper(title),type) from netflix_raw
where title not like '?%'
group by concat(upper(title),type)
having count(*) > 1
)
order by title

with cte as (
select *, ROW_NUMBER() over (partition by title,type order by show_id) as rn
from netflix_raw)
select * from cte where rn = 1
--and title not like '?%' 

-- new table for listed in,director, country, cast
-- if we do a string split, if the columns are null then those will not at all be populated in the target table

select show_id,trim(value) as director
into netflix_directors
from netflix_raw
cross apply string_split(director,',')

select * from netflix_directors

select show_id,trim(value) as country
into netflix_country
from netflix_raw
cross apply string_split(country,',')

select show_id,trim(value) as cast
into netflix_cast
from netflix_raw
cross apply string_split(cast,',')

select show_id,trim(value) as genre
into netflix_genre
from netflix_raw
cross apply string_split(listed_in,',')

----------------------------------------------------------------------------------------------------------------------------
-- populate missing values in country, duration columns : 

select * from netflix_raw
where country is null

select * from netflix_country where show_id = 's1001'
-- now take the director of 1001 and populate the country for the director for the missing row also

select * from netflix_raw where director = 'Ahishor Solomon'

select distinct director,country from netflix_country nc
join netflix_directors nd on nd.show_id = nc.show_id
order by director

insert into netflix_country
select show_id,m.country from 
netflix_raw nr 
inner join (select distinct director,country from netflix_country nc
join netflix_directors nd on nd.show_id = nc.show_id
) m on nr.director = m.director
where nr.country is null

---------------------------------------------------------------------------------------------------------------------
-- handling duration null value and final query :
select * from netflix_raw where duration is null

with cte as (
select *,
row_number() over (partition by title,type order by show_id) as rn
from netflix_raw)
select show_id,type,title,cast(date_added as date) as date_added,release_year,rating,case when duration is null then rating 
else duration end as duration,description 
into netflix 
from cte 


select * from netflix
-- For Each director count the number of movies and tv shows created by them in separate columns 
--for directors who have created tv shows and movies both

with cte as (
select director,count(case when type='Movie' then title end) as movies,
count(case when type = 'TV Show' then title end) as tvshow from netflix
join netflix_directors on netflix.show_id = netflix_directors.show_id
--where director = 'Tig Notaro'
group by director)
select * from cte where movies >= 1 and tvshow >= 1

-- which country has highest number of comedy movies:

select top 1 count(*) as max_comedy_movies,country from netflix_country nc 
join netflix_genre ng on nc.show_id=ng.show_id
where ng.genre = 'comedies'
group by country
order by 1 desc

-- for each year ( as per date added to netflix), which director has maximum number of movies released:

with cte as (
select DATEPART(YEAR,date_added) as year_added,count(*) as number_of_films,director from netflix n
join netflix_directors nd on n.show_id = nd.show_id
where type = 'Movie'
group by DATEPART(YEAR,date_added),director
--order by number_of_films desc
)
,maxfilms as (
select *,row_number() over (partition by year_added order by number_of_films desc,director)
as rn from cte)
select * from maxfilms where rn=1
order by year_added

--what is the average duration of movies in each genre ?

select avg(cast(replace(duration,' min','') as int)) as average_duration,genre from netflix n 
join netflix_genre ng on n.show_id = ng.show_id
where type = 'Movie'
group by genre

-- find the directors who have created horror and comedy movies both
-- display director names along with number of comedy and horror movies directed by them

select nd.director from netflix n 
join netflix_directors nd on n.show_id = nd.show_id
join netflix_genre ng on nd.show_id = ng.show_id
and type = 'Movie'
where genre in ('Horror Movies','comedies')
group by nd.director
having count(distinct ng.genre) = 2

-- extended version 
select count(distinct case when ng.genre = 'Horror Movies' then n.show_id end) as number_of_horrors,
count(distinct case when ng.genre = 'Comedies' then n.show_id end) as number_of_comedies,director from netflix n 
join netflix_directors nd on n.show_id = nd.show_id
join netflix_genre ng on nd.show_id = ng.show_id
and type = 'Movie'
where genre in ('Horror Movies','comedies')
group by director
having count(ng.genre) = 2