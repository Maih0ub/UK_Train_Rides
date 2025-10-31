CREATE DATABASE TrainRidesDB;


SELECT COLUMN_NAME 
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'UK_Train_Rides';


SELECT TABLE_SCHEMA, TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'UK_Train_Rides';

----------------------------------------------------------------------------------------------------------------

--------------------------------------------------
-- 1️ حذف الصفوف المكررة بناءً على Transaction_ID
--------------------------------------------------
WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Transaction_ID ORDER BY Transaction_ID) AS rn
    FROM UK_Train_Rides
)
DELETE FROM CTE WHERE rn > 1;
GO


--------------------------------------------------
-- 2️ حذف الصفوف اللي فيها بيانات أساسية ناقصة
--------------------------------------------------
DELETE FROM UK_Train_Rides
WHERE Price IS NULL
   OR Departure_Station IS NULL
   OR Arrival_Destination IS NULL
   OR Date_of_Journey IS NULL
   OR Journey_Status IS NULL;
GO


--------------------------------------------------
-- 3️ تحويل الأعمدة الخاصة بالتاريخ والوقت إلى الأنواع المناسبة
--------------------------------------------------
ALTER TABLE UK_Train_Rides ALTER COLUMN Date_of_Purchase DATE;
ALTER TABLE UK_Train_Rides ALTER COLUMN Date_of_Journey DATE;
ALTER TABLE UK_Train_Rides ALTER COLUMN Time_of_Purchase TIME;
ALTER TABLE UK_Train_Rides ALTER COLUMN Departure_Time TIME;
ALTER TABLE UK_Train_Rides ALTER COLUMN Arrival_Time TIME;
ALTER TABLE UK_Train_Rides ALTER COLUMN Actual_Arrival_Time TIME;
GO


--------------------------------------------------
-- 4️ تنظيف القيم النصية (إزالة المسافات الزائدة + توحيد الحالة)
--------------------------------------------------
UPDATE UK_Train_Rides
SET Journey_Status = LOWER(LTRIM(RTRIM(Journey_Status))),
    Purchase_Type = LOWER(LTRIM(RTRIM(Purchase_Type))),
    Payment_Method = LOWER(LTRIM(RTRIM(Payment_Method))),
    Railcard = LOWER(LTRIM(RTRIM(Railcard))),
    Ticket_Class = LOWER(LTRIM(RTRIM(Ticket_Class))),
    Ticket_Type = LOWER(LTRIM(RTRIM(Ticket_Type))),
    Refund_Request = LOWER(LTRIM(RTRIM(Refund_Request)));
GO


--------------------------------------------------
-- 5️ حذف القيم غير المنطقية في السعر (سعر أقل من أو يساوي صفر أو أكتر من 500)
--------------------------------------------------
DELETE FROM UK_Train_Rides
WHERE Price <= 0 OR Price > 500;
GO


--------------------------------------------------
-- 6️ إضافة عمود Boolean لطلبات الاسترجاع (yes/no)
--------------------------------------------------
ALTER TABLE UK_Train_Rides
ADD RefundRequestBit BIT;
GO


--------------------------------------------------
-- 7️ تحويل عمود Refund_Request النصي إلى رقمي (1 أو 0)
--------------------------------------------------
UPDATE UK_Train_Rides
SET RefundRequestBit = CASE
        WHEN LOWER(LTRIM(RTRIM(Refund_Request))) IN ('yes', 'y', 'true', '1') THEN 1
        ELSE 0
    END;
GO


--------------------------------------------------
-- 8️ مراجعة النتائج
--------------------------------------------------
SELECT TOP 20
    Transaction_ID,
    Refund_Request,
    RefundRequestBit
FROM UK_Train_Rides;
GO

------------------------------------------------------------------------------------------------------------

-- عدد الصفوف الإجمالي بعد التنضيف
SELECT COUNT(*) AS TotalRows FROM UK_Train_Rides;

-- عدد الرحلات اللي فيها Refund (القيمة = 1)
SELECT COUNT(*) AS Refunds FROM UK_Train_Rides WHERE RefundRequestBit = 1;

-- توزيع حالة الرحلة (on time, delayed, cancelled...)
SELECT Journey_Status, COUNT(*) AS Count
FROM UK_Train_Rides
GROUP BY Journey_Status
ORDER BY Count DESC;

-- متوسط السعر + أقل وأعلى سعر
SELECT 
    AVG(Price) AS AvgPrice,
    MIN(Price) AS MinPrice,
    MAX(Price) AS MaxPrice
FROM UK_Train_Rides;


--------------------------------------------------------------------------------------------------------------

--أكتر محطات انطلاق شيوعًا
SELECT TOP 10 Departure_Station, COUNT(*) AS Trips
FROM UK_Train_Rides
GROUP BY Departure_Station
ORDER BY Trips DESC;


--أكتر وجهات الوصول شيوعًا
SELECT TOP 10 Arrival_Destination, COUNT(*) AS Trips
FROM UK_Train_Rides
GROUP BY Arrival_Destination
ORDER BY Trips DESC;


--متوسط السعر حسب نوع التذكرة
SELECT Ticket_Type, AVG(Price) AS AvgPrice
FROM UK_Train_Rides
GROUP BY Ticket_Type
ORDER BY AvgPrice DESC;



--نسبة التأخير في الرحلات
SELECT 
    Journey_Status,
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM UK_Train_Rides) AS Percentage
FROM UK_Train_Rides
GROUP BY Journey_Status;

----------------------------------------------------------------------------------------------------------------

--تحليل متوسط السعر حسب نوع التذكرة ودرجة القطار (Class)    
-- (  يوضح أي نوع تذاكر وأي درجة أغلى وأكتر استخدامًا.)
SELECT 
    Ticket_Type,
    Ticket_Class,
    AVG(Price) AS AvgPrice,
    COUNT(*) AS TicketCount
FROM UK_Train_Rides
GROUP BY Ticket_Type, Ticket_Class
ORDER BY AvgPrice DESC;



--تحليل الطلب حسب اليوم
--بيقولك في أي يوم من الأسبوع الناس بتشتري تذاكر أكتر (مثلاً الجمعة أو الاثنين).
SELECT 
    DATENAME(WEEKDAY, Date_of_Purchase) AS DayOfWeek,
    COUNT(*) AS TicketsSold
FROM UK_Train_Rides
GROUP BY DATENAME(WEEKDAY, Date_of_Purchase)
ORDER BY TicketsSold DESC;






--مقارنة بين الدفع الإلكتروني والنقدي
SELECT 
    Payment_Method,
    COUNT(*) AS Count,
    AVG(Price) AS AvgPrice,
    SUM(CASE WHEN RefundRequestBit = 1 THEN 1 ELSE 0 END) AS Refunds
FROM UK_Train_Rides
GROUP BY Payment_Method
ORDER BY Count DESC;


--تحليل الــ Railcard (البطاقات المخفّضة)
SELECT 
    Railcard,
    COUNT(*) AS UsageCount,
    AVG(Price) AS AvgPrice
FROM UK_Train_Rides
GROUP BY Railcard
ORDER BY UsageCount DESC;


--تحليل الرحلات الملغاة أو المتأخرة
SELECT 
    Journey_Status,
    COUNT(*) AS Count,
    AVG(Price) AS AvgPrice,
    SUM(CASE WHEN RefundRequestBit = 1 THEN 1 ELSE 0 END) AS Refunds
FROM UK_Train_Rides
GROUP BY Journey_Status
ORDER BY Count DESC;


--تحليل اتجاهات الوجهات
--بتوضح أكتر خطوط السفر نشاطًا  
SELECT TOP 10 
    Departure_Station,
    Arrival_Destination,
    COUNT(*) AS TripCount
FROM UK_Train_Rides
GROUP BY Departure_Station, Arrival_Destination
ORDER BY TripCount DESC;


--تحليل الأسعار عبر الزمن (Monthly Trends)
--يوضح اتجاه الأسعار وعدد التذاكر عبر الشهور.
SELECT 
    FORMAT(Date_of_Purchase, 'yyyy-MM') AS Month,
    AVG(Price) AS AvgPrice,
    COUNT(*) AS Tickets
FROM UK_Train_Rides
GROUP BY FORMAT(Date_of_Purchase, 'yyyy-MM')
ORDER BY Month;


--تحليل الطلب في ساعات اليوم
--هل الناس بتحجز أكتر الصبح ولا بالليل؟
SELECT 
    DATEPART(HOUR, Time_of_Purchase) AS HourOfDay,
    COUNT(*) AS TicketCount
FROM UK_Train_Rides
GROUP BY DATEPART(HOUR, Time_of_Purchase)
ORDER BY HourOfDay;


--علاقة السعر بنوع الرحلة 
SELECT 
    Ticket_Type,
    AVG(Price) AS AvgPrice,
    COUNT(*) AS Count
FROM UK_Train_Rides
GROUP BY Ticket_Type;












