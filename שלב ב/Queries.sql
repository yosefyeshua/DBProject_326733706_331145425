
SELECT s.SupplierName, s.ContactName, SUM(p.TotalAmount) AS TotalSpent
FROM SUPPLIER s
JOIN PURCHASEORDER p ON s.SupplierID = p.SupplierID
WHERE EXTRACT(YEAR FROM p.OrderDate) = 2024
GROUP BY s.SupplierName, s.ContactName
HAVING SUM(p.TotalAmount) > 50000
ORDER BY TotalSpent DESC;

-- תצורה ב' (תת-שאילתה ב-WHERE + הקבלת נתונים):
SELECT s.SupplierName, s.ContactName, 
       (SELECT SUM(TotalAmount) FROM PURCHASEORDER WHERE SupplierID = s.SupplierID AND EXTRACT(YEAR FROM OrderDate) = 2024) AS TotalSpent
FROM SUPPLIER s
WHERE s.SupplierID IN (
    SELECT SupplierID FROM PURCHASEORDER 
    WHERE EXTRACT(YEAR FROM OrderDate) = 2024
    GROUP BY SupplierID HAVING SUM(TotalAmount) > 50000
)
ORDER BY TotalSpent DESC;


-- ---------------------------------------------------------------------------------
-- שאילתה 2: "ספקים רדומים"
-- מציאת ספקים שלא ביצענו מולם אף הזמנה בשנת 2025.
-- הבדל ביעילות: גרסה א' (NOT IN) קלה לקריאה אבל יכולה להיות איטית מאוד אם יש NULLS.
-- גרסה ב' (LEFT JOIN + IS NULL) נחשבת לרוב לדרך הכי יעילה ומהירה למצוא נתונים חסרים (Anti-Join).
-- ---------------------------------------------------------------------------------
-- תצורה א' (שימוש ב-NOT IN):
SELECT SupplierID, SupplierName, Phone 
FROM SUPPLIER 
WHERE SupplierID NOT IN (
    SELECT SupplierID 
    FROM PURCHASEORDER 
    WHERE EXTRACT(YEAR FROM OrderDate) = 2025
);

-- תצורה ב' (שימוש ב-LEFT JOIN ו-IS NULL):
SELECT s.SupplierID, s.SupplierName, s.Phone 
FROM SUPPLIER s
LEFT JOIN PURCHASEORDER p ON s.SupplierID = p.SupplierID AND EXTRACT(YEAR FROM p.OrderDate) = 2025
WHERE p.OrderID IS NULL;


-- ---------------------------------------------------------------------------------
-- שאילתה 3: "חשבוניות עם חוב פתוח"
-- מציג חשבוניות שסכום התשלומים עבורן קטן מסכום החשבונית המקורי (יש חוב).
-- ---------------------------------------------------------------------------------
-- תצורה א' (LEFT JOIN ופונקציית COALESCE לטיפול ב-NULL):
SELECT i.InvoiceID, i.InvoiceDate, i.TotalDue, 
       COALESCE(SUM(p.AmountPaid), 0) AS PaidAmount, 
       (i.TotalDue - COALESCE(SUM(p.AmountPaid), 0)) AS Debt
FROM INVOICE i
LEFT JOIN PAYMENT p ON i.InvoiceID = p.InvoiceID
GROUP BY i.InvoiceID, i.InvoiceDate, i.TotalDue
HAVING (i.TotalDue - COALESCE(SUM(p.AmountPaid), 0)) > 0
ORDER BY Debt DESC;

-- תצורה ב' (Correlated Subquery - תת שאילתה מקושרת ב-WHERE):
-- הערת התייעלות: שיטה זו פחות יעילה כי התת-שאילתה רצה מחדש עבור כל שורה בחשבוניות!
SELECT i.InvoiceID, i.InvoiceDate, i.TotalDue,
       (SELECT COALESCE(SUM(AmountPaid), 0) FROM PAYMENT WHERE InvoiceID = i.InvoiceID) AS PaidAmount
FROM INVOICE i
WHERE i.TotalDue > (SELECT COALESCE(SUM(AmountPaid), 0) FROM PAYMENT WHERE InvoiceID = i.InvoiceID)
ORDER BY i.TotalDue DESC;


-- ---------------------------------------------------------------------------------
-- שאילתה 4: "מוצרי פרימיום מבוקשים"
-- מוצרים שהמילה 'Premium' בשמם, שמחירם מעל הממוצע, והוזמנו ביותר מ-500 יחידות בסך הכל.
-- ---------------------------------------------------------------------------------
-- תצורה א' (JOIN ו-HAVING עם Subquery):
SELECT pr.ProductName, MAX(pr.UnitPrice) AS CurrentPrice, SUM(oi.Quantity) AS TotalOrdered
FROM PRODUCT pr
JOIN ORDERITEM oi ON pr.ProductID = oi.ProductID
WHERE pr.ProductName LIKE '%Premium%' 
  AND pr.UnitPrice > (SELECT AVG(UnitPrice) FROM PRODUCT)
GROUP BY pr.ProductName
HAVING SUM(oi.Quantity) > 500
ORDER BY TotalOrdered DESC;

-- תצורה ב' (שימוש בטבלה זמנית בתוך ה-FROM - Inline View):
SELECT pr.ProductName, pr.UnitPrice AS CurrentPrice, Aggregated.TotalQty
FROM PRODUCT pr
JOIN (
    SELECT ProductID, SUM(Quantity) AS TotalQty
    FROM ORDERITEM
    GROUP BY ProductID
    HAVING SUM(Quantity) > 500
) Aggregated ON pr.ProductID = Aggregated.ProductID
WHERE pr.ProductName LIKE '%Premium%'
  AND pr.UnitPrice > (SELECT AVG(UnitPrice) FROM PRODUCT)
ORDER BY Aggregated.TotalQty DESC;



-- ==========================================
-- חלק ב': 4 שאילתות SELECT רגילות אך מורכבות
-- ==========================================

-- 5. "דוח סיכום רכש חודשי" - שימוש נרחב בפונקציות תאריך!
-- מציג להנהלה כמה הזמנות ומה סך ההוצאה לכל חודש ושנה בנפרד.
SELECT EXTRACT(YEAR FROM OrderDate) AS OrderYear, 
       EXTRACT(MONTH FROM OrderDate) AS OrderMonth, 
       COUNT(OrderID) AS TotalOrders, 
       SUM(TotalAmount) AS MonthlySpend
FROM PURCHASEORDER
GROUP BY EXTRACT(YEAR FROM OrderDate), EXTRACT(MONTH FROM OrderDate)
ORDER BY OrderYear DESC, OrderMonth DESC;


-- 6. "פירוט הזמנות ענק" - מצרף 4 טבלאות שונות!
-- מציג פירוט מלא של הזמנות בסכום מעל 20,000 כולל שם הספק והמוצרים שהוזמנו בהן.
SELECT po.OrderID, po.OrderDate, s.SupplierName, pr.ProductName, oi.Quantity, oi.ActualPrice, 
       (oi.Quantity * oi.ActualPrice) AS LineTotal
FROM PURCHASEORDER po
JOIN SUPPLIER s ON po.SupplierID = s.SupplierID
JOIN ORDERITEM oi ON po.OrderID = oi.OrderID
JOIN PRODUCT pr ON oi.ProductID = pr.ProductID
WHERE po.TotalAmount > 20000
ORDER BY po.TotalAmount DESC, po.OrderID
LIMIT 100;


-- 7. "פער מחירי קטלוג לעומת רכש בפועל"
-- מוצא מוצרים שהמחיר שבו קנינו אותם בפועל נמוך ממחיר הקטלוג (השגנו הנחה!).
SELECT pr.ProductID, pr.ProductName, pr.UnitPrice AS CatalogPrice, 
       AVG(oi.ActualPrice) AS AvgPurchasePrice, 
       (pr.UnitPrice - AVG(oi.ActualPrice)) AS AverageDiscount
FROM PRODUCT pr
JOIN ORDERITEM oi ON pr.ProductID = oi.ProductID
GROUP BY pr.ProductID, pr.ProductName, pr.UnitPrice
HAVING AVG(oi.ActualPrice) < pr.UnitPrice
ORDER BY AverageDiscount DESC;


-- 8. "תזרים מזומנים - תשלומים בהעברה בנקאית השנה"
-- מציג מידע לחשב (מסך תשלומים) על העברות בנקאיות שבוצעו בחצי השנה האחרונה.
SELECT p.PaymentID, p.PaymentDate, p.AmountPaid, i.InvoiceID, s.SupplierName
FROM PAYMENT p
JOIN INVOICE i ON p.InvoiceID = i.InvoiceID
JOIN PURCHASEORDER po ON i.OrderID = po.OrderID
JOIN SUPPLIER s ON po.SupplierID = s.SupplierID
WHERE p.PaymentMethod = 'Bank Transfer' 
  AND p.PaymentDate > CURRENT_DATE - INTERVAL '6 months'
ORDER BY p.PaymentDate DESC;



-- ==========================================
-- חלק ג': 3 שאילתות UPDATE
-- ==========================================

-- 1. עדכון מחירון: העלאת מחיר ב-10% לכל המוצרים מקטגוריית "Veterinary" שמחירם נמוך מ-50.
UPDATE PRODUCT 
SET UnitPrice = UnitPrice * 1.10 
WHERE ProductName LIKE '%Veterinary%' AND UnitPrice < 50;

-- 2. סגירת תקופה: שינוי סטטוס הזמנה מ-Pending ל-Approved עבור כל ההזמנות הישנות מ-2023.
UPDATE PURCHASEORDER 
SET Status = 'Approved' 
WHERE EXTRACT(YEAR FROM OrderDate) <= 2023 AND Status = 'Pending';

-- 3. הנחת כמות: הוזלת המחיר בפועל (ActualPrice) ב-5% לכל שורת הזמנה בה הוזמנו מעל 200 יחידות.
UPDATE ORDERITEM 
SET ActualPrice = ActualPrice * 0.95 
WHERE Quantity > 200;



-- ==========================================
-- חלק ד': 3 שאילתות DELETE
-- ==========================================

-- 1. ניקוי שגיאות: מחיקת תשלומים שגויים שסכומם נמוך מ-5 דולר (טבלת קצה ללא מפתחות זרים).
DELETE FROM PAYMENT 
WHERE AmountPaid < 5;

-- 2. ניקוי שורות הזמנה אפסיות: מחיקת שורות הזמנה בטעות שבהן הכמות היא 0 (טבלת קצה).
DELETE FROM ORDERITEM 
WHERE Quantity = 0;

-- 3. מחיקת מוצרים "מתים": מחיקת מוצרים מהקטלוג שמעולם לא הוזמנו (שימוש בתת-שאילתה).
DELETE FROM PRODUCT 
WHERE ProductID NOT IN (SELECT DISTINCT ProductID FROM ORDERITEM);