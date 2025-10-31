use FinalProject







select *
from uktrain

select [Transaction ID]
from uktrain 
where [Transaction ID] = null


DELETE FROM uktrain
WHERE [Departure Station] IS NULL
   OR [Arrival Destination] IS NULL
   OR [Departure Time] IS NULL
   OR [Arrival Time] IS NULL
   OR [Price] IS NULL;

UPDATE uktrain
SET 
[Departure Station] = LTRIM(RTRIM([Departure Station])),
[Arrival Destination] = LTRIM(RTRIM([Arrival Destination])),
[Payment Method] = LTRIM(RTRIM([Payment Method])),
[Journey Status] = LTRIM(RTRIM([Journey Status]));

SELECT *
INTO uktrainClean
FROM uktrain;

select *
from uktrainClean

--كم عدد الرحلات
select count(*) as Total_rides
from uktrainClean;

-- اكثر محطه مغادره
select top(1)[Departure Station] , count(*) as total_departure
from uktrainClean
group by [Departure Station]
order by total_departure desc;

--اكثر محطه وصولا
select top(1)[Arrival Destination] , count(*) as total_Arrive
from uktrainClean
group by [Arrival Destination]
order by total_Arrive desc;

--متوسط سعر التذكره
select AVG(price) as avg_price
from uktrainClean;

--اعلي قيمه للتذكره
select max(price) as max_value
from uktrainClean;

--اقل قيمه للتذكره
select min(price) as min_value
from uktrainClean;

--اكثر وسيله دفع
select top(1) [Payment Method],count(*) as total_payment
from uktrainClean 
group by [Payment Method];

--عدد الرحلات on time
select [Journey Status] ,count(*) as total_ontime
from uktrainClean
where [Journey Status] = 'On Time'
group by  [Journey Status];

--عدد الرحلات Delayed
select [Journey Status] ,count(*) as total_Delayed
from uktrainClean
where [Journey Status] = 'Delayed'
group by  [Journey Status];

--اجمالي الايرادات 
select sum(price) as total_revenue
from uktrainClean;

--متوسط سعر حسب نوع الذكره 
select [Ticket Type],avg(price) as avg_price
from uktrainClean
group by [Ticket Type]
order by avg_price;









