# דוח פרויקט - שלב ב'

בשלב זה אנו מבצעים תשאול של מודל הנתונים שבנינו, על מנת להפיק ממנו מידע משמעותי ולא טריוויאלי. כמו כן אנו מדגימים שימוש בטרנזקציות ויצירת אינדקסים ואילוצים במטרה להגן על הנתונים ולייעל את השליפה בחסות האפיון החזותי שתיעדנו.

---

## תשאול נתונים (SELECT)

### א' - 4 שאילתות בשתי תצורות כתיבה (השוואת יעילות)

#### שאילתה 1: "ספקים מובילים (הוצאה שנתית מעל 50,000)"
**תיאור השאילתא:** מציאת ספקים שהוצאנו מולם למעלה מ-50,000 דולר במהלך שנת 2024. השאילתה מסכמת סכומים ומציגה מידע שלא נגיש ישירות מהטבלאות.

**קוד תצורה א' (JOIN ו-HAVING):**
```sql
SELECT s.SupplierName, s.ContactName, SUM(p.TotalAmount) AS TotalSpent
FROM SUPPLIER s
JOIN PURCHASEORDER p ON s.SupplierID = p.SupplierID
WHERE EXTRACT(YEAR FROM p.OrderDate) = 2024
GROUP BY s.SupplierName, s.ContactName
HAVING SUM(p.TotalAmount) > 50000
ORDER BY TotalSpent DESC;
```
**קוד תצורה ב' (תת-שאילתה מקושרת - IN):**
```sql
SELECT s.SupplierName, s.ContactName, 
       (SELECT SUM(TotalAmount) FROM PURCHASEORDER WHERE SupplierID = s.SupplierID AND EXTRACT(YEAR FROM OrderDate) = 2024) AS TotalSpent
FROM SUPPLIER s
WHERE s.SupplierID IN (
    SELECT SupplierID FROM PURCHASEORDER 
    WHERE EXTRACT(YEAR FROM OrderDate) = 2024
    GROUP BY SupplierID HAVING SUM(TotalAmount) > 50000
)
ORDER BY TotalSpent DESC;
```
* ![צילום מסך הרצה](images/image1.png)
* ![צילום מסך תוצאות](images/image2.png)

**הבדלי יעילות:** תצורה א' (JOIN + GROUP BY) הינה היעילה ביותר; שרת ה-SQL מבצע את פקודות ה-Hash Join והחישוב (ה-Aggregation) מידית עבור המשתתפים. בתצורה ב', התת-שאילתה רצה באופן מסורבל, והפילטור על בסיס `IN` מקשה משמעותית על חשיבת מנוע הפוסטגרס המחייבת סריקות חוזרות כבדות.

#### שאילתה 2: "ספקים רדומים"
**תיאור השאילתא:** מציאת ספקים שלא ביצענו מולם אף הזמנה בשנת 2025.

**קוד תצורה א' (שימוש ב-NOT IN):**
```sql
SELECT SupplierID, SupplierName, Phone 
FROM SUPPLIER 
WHERE SupplierID NOT IN (
    SELECT SupplierID FROM PURCHASEORDER WHERE EXTRACT(YEAR FROM OrderDate) = 2025
);
```
**קוד תצורה ב' (שימוש ב-LEFT JOIN ו-IS NULL):**
```sql
SELECT s.SupplierID, s.SupplierName, s.Phone 
FROM SUPPLIER s
LEFT JOIN PURCHASEORDER p ON s.SupplierID = p.SupplierID AND EXTRACT(YEAR FROM p.OrderDate) = 2025
WHERE p.OrderID IS NULL;
```
* ![צילום מסך הרצה](images/image3.png)
* ![צילום מסך תוצאות](images/image4.png)

**הבדלי יעילות:** גרסה ב' (`LEFT JOIN` יחד עם פסילת ערכים ב-`IS NULL`, המושג Anti-Join) נחשבת לשיטה היעילה והמומלצת בהרבה למציאת היעדרויות, השרת מאפטם זאת היטב! גרסה א' (NOT IN) קלה יותר לקריאה בעין אנושית אולם עלולה להיות פחות יעילה במיוחד כשנכנסים ערכי `NULL` בחיתוכים.

#### שאילתה 3: "חשבוניות עם חוב פתוח"
**תיאור השאילתא:** שאילתה שמציגה נתונים חשבונאיים מתקדמים: התרעה על כל החשבוניות שסכום התשלומים שנאסף למענן לא מכסה את סכום החשבונית המקורי (הפרשים חיוביים לחוב).

**קוד תצורה א' (GROUP BY ו-COALESCE עם LEFT JOIN):**
```sql
SELECT i.InvoiceID, i.InvoiceDate, i.TotalDue, 
       COALESCE(SUM(p.AmountPaid), 0) AS PaidAmount, 
       (i.TotalDue - COALESCE(SUM(p.AmountPaid), 0)) AS Debt
FROM INVOICE i
LEFT JOIN PAYMENT p ON i.InvoiceID = p.InvoiceID
GROUP BY i.InvoiceID, i.InvoiceDate, i.TotalDue
HAVING (i.TotalDue - COALESCE(SUM(p.AmountPaid), 0)) > 0
ORDER BY Debt DESC;
```
**קוד תצורה ב' (Correlated Subqueries - תת שאילתה מקושרת ב-WHERE):**
```sql
SELECT i.InvoiceID, i.InvoiceDate, i.TotalDue,
       (SELECT COALESCE(SUM(AmountPaid), 0) FROM PAYMENT WHERE InvoiceID = i.InvoiceID) AS PaidAmount,
       (i.TotalDue - (SELECT COALESCE(SUM(AmountPaid), 0) FROM PAYMENT WHERE InvoiceID = i.InvoiceID)) AS Debt
FROM INVOICE i
WHERE i.TotalDue > (SELECT COALESCE(SUM(AmountPaid), 0) FROM PAYMENT WHERE InvoiceID = i.InvoiceID)
ORDER BY Debt DESC;
```
* ![צילום מסך הרצה](images/image5.png)
* ![צילום מסך תוצאות](images/image6.png)

**הבדלי יעילות:** תצורה א' מבצעת חיבור מרוכז (JOIN). מרווחי השליפה יוצרים מפה אחת שעליה מנוע המסד רוכב ומבצע רצף אגרסיוני יעיל. בתצורה ב', התת-שאילתות שב-SELECT וב-WHERE מקושרות, כלומר הן רצות מחדש (הלוך חזור על בסיס משתנה אינדקס i.InvoiceID) עבור *כל שורה ושורה* בכרטיסיות החשבוניות. זו כתיבה איטית באופן תהומי.

#### שאילתה 4: "מוצרי פרימיום מבוקשים"
**תיאור השאילתא:** הצגת פריטי יוקרה מקטלוג ששמם כולל את המילה 'Premium', שמחירם גבוה מהמחיר הממוצע בסורק, ושהוזמנו בכמויות של מעל 500 יחידות בסך הכל היסטורית.

**קוד תצורה א' (JOIN ו-HAVING עם תת-שאילתה בודדת):**
```sql
SELECT pr.ProductName, MAX(pr.UnitPrice) AS CurrentPrice, SUM(oi.Quantity) AS TotalOrdered
FROM PRODUCT pr
JOIN ORDERITEM oi ON pr.ProductID = oi.ProductID
WHERE pr.ProductName LIKE '%Premium%' 
  AND pr.UnitPrice > (SELECT AVG(UnitPrice) FROM PRODUCT)
GROUP BY pr.ProductName
HAVING SUM(oi.Quantity) > 500
ORDER BY TotalOrdered DESC;
```
**קוד תצורה ב' (Inline View - שימוש בטבלה זמנית בתוך ה-FROM):**
```sql
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
```
* ![צילום מסך הרצה](images/image7.png)
* ![צילום מסך תוצאות](images/image8.png)

**הבדלי יעילות:** תלוי באילוצי שרת הזיכרון, אך לעיתים קרובות Inline View (תצורה ב') עשויה לקבל יתרון מפלט בשאילתות ענק, מכיוון שאנו כופים על המערכת לצמצם (Aggregate) תחילה את שורות ה-ORDERITEM בנפרד טרם חיבור (JOIN) הענק לטבלאות קטלוג המוצרים, וזה מרוקן עומסים מכמות המידע שנשמרת על הכוונת בזיכרון.

---

### ב' - 4 שאילתות מורכבות נוספות (תצורה יחידה)

#### שאילתה 5: "דוח סיכום רכש חודשי"
**תיאור השאילתא:** מציג באופן מנותח להנהלה כמה הזמנות ומה סך ההוצאה לכל חודש ושנה בנפרד (שימוש בפונקציות תאריכים מרובות).
```sql
SELECT EXTRACT(YEAR FROM OrderDate) AS OrderYear, 
       EXTRACT(MONTH FROM OrderDate) AS OrderMonth, 
       COUNT(OrderID) AS TotalOrders, 
       SUM(TotalAmount) AS MonthlySpend
FROM PURCHASEORDER
GROUP BY EXTRACT(YEAR FROM OrderDate), EXTRACT(MONTH FROM OrderDate)
ORDER BY OrderYear DESC, OrderMonth DESC;
```
* **[>> צילום מסך של הרצת השאילתה + צילום תוצאה מותאמת <<]**

#### שאילתה 6: "פירוט שרשרת אספקה ענק"
**תיאור השאילתא:** צירוף של 4 טבלאות שונות לחשיפה ופירוט מלא של הזמנות בסכום מעל 20,000, כולל שמות הספקים והמוצרים מהעבר.
```sql
SELECT po.OrderID, po.OrderDate, s.SupplierName, pr.ProductName, oi.Quantity, oi.ActualPrice, 
       (oi.Quantity * oi.ActualPrice) AS LineTotal
FROM PURCHASEORDER po
JOIN SUPPLIER s ON po.SupplierID = s.SupplierID
JOIN ORDERITEM oi ON po.OrderID = oi.OrderID
JOIN PRODUCT pr ON oi.ProductID = pr.ProductID
WHERE po.TotalAmount > 20000
ORDER BY po.TotalAmount DESC, po.OrderID
LIMIT 100;
```
* **[>> צילום מסך של הרצת השאילתה + צילום תוצאה מותאמת <<]**

#### שאילתה 7: "פער מחירי קטלוג לעומת רכש בפועל"
**תיאור השאילתא:** מאתרת במדויק מוצרים שהמחיר בו הם נקנו בסוף השורה בפועל (ActualPrice) היה נמוך משמעותית ממחיר הקטלוג המקורי (השגת הנחות!).
```sql
SELECT pr.ProductID, pr.ProductName, pr.UnitPrice AS CatalogPrice, 
       AVG(oi.ActualPrice) AS AvgPurchasePrice, 
       (pr.UnitPrice - AVG(oi.ActualPrice)) AS AverageDiscount
FROM PRODUCT pr
JOIN ORDERITEM oi ON pr.ProductID = oi.ProductID
GROUP BY pr.ProductID, pr.ProductName, pr.UnitPrice
HAVING AVG(oi.ActualPrice) < pr.UnitPrice
ORDER BY AverageDiscount DESC;
```
* **[>> צילום מסך של הרצת השאילתה + צילום תוצאה מותאמת <<]**

#### שאילתה 8: "תזרים מזומנים - העברות בנקאיות בחצי השנה האחרונה"
**תיאור השאילתא:** מציג למנהלי כספים רק תשלומים שבוצעו בשיטת העברה בנקאית 'Bank Transfer' ורק מחצי השנה האחרונה (התמודדות טבעית עם מאפייני זמן מתגלגלים).
```sql
SELECT p.PaymentID, p.PaymentDate, p.AmountPaid, i.InvoiceID, s.SupplierName
FROM PAYMENT p
JOIN INVOICE i ON p.InvoiceID = i.InvoiceID
JOIN PURCHASEORDER po ON i.OrderID = po.OrderID
JOIN SUPPLIER s ON po.SupplierID = s.SupplierID
WHERE p.PaymentMethod = 'Bank Transfer' 
  AND p.PaymentDate > CURRENT_DATE - INTERVAL '6 months'
ORDER BY p.PaymentDate DESC;
```
* **[>> צילום מסך של הרצת השאילתה + צילום תוצאה מותאמת <<]**

---

## עדכון הנתונים בעומק (UPDATE ו-DELETE)

### שאילתות UPDATE

1. **עדכון מחירון וטרינרי:** העלאת מחיר ב-10% לכל המוצרים מקטגוריית "Veterinary" שמחירם קטן מ-50.
```sql
UPDATE PRODUCT SET UnitPrice = UnitPrice * 1.10 
WHERE ProductName LIKE '%Veterinary%' AND UnitPrice < 50;
```
* **[>> צילום הרצת השאילתה <<]**
* **[>> צילום מסך מצב בסיס הנתונים לפני ואחרי העדכון בטבלה <<]**

2. **החלת מצב תקופתי אוטומטי:** סגירה ושינוי סטטוס הזמנה מ-Pending ל-Approved סדרתי עבור ההזמנות הישנות שטרחתו מאז 2023.
```sql
UPDATE PURCHASEORDER SET Status = 'Approved' 
WHERE EXTRACT(YEAR FROM OrderDate) <= 2023 AND Status = 'Pending';
```
* **[>> צילום הרצת השאילתה <<]**
* **[>> צילום מסך מצב בסיס הנתונים לפני ואחרי העדכון הרדיקלי <<]**

3. **הנחת כמות ריאלית להזמנה:** הוזלת המחיר בפועל שנמשך אחורנית ב-5% לכל שורת פריט שבה נרשמה כמות גדולה מ-200.
```sql
UPDATE ORDERITEM SET ActualPrice = ActualPrice * 0.95 WHERE Quantity > 200;
```
* **[>> צילום הרצת השאילתה <<]**
* **[>> צילום מסך מצב בסיס הנתונים לפני ואחרי <<]**

### שאילתות DELETE

1. **ניקוי שגיאות חישוב מיקרו במערכת (טבלת קצה):** השמדת כל טופסי התשלומים שיש בהם במכוון פחות מ-5 דולר משום שאלו שגויים.
```sql
DELETE FROM PAYMENT WHERE AmountPaid < 5;
```
* **[>> צילום הרצה + צילום מסך לפני/אחרי <<]**

2. **ניקוי שורות רוח (0 כמות):** מחיקת שורות קצה המלמדות שכמות ההזמנה שיצאה בפועל הינה מחוסרת משמעות (אפס).
```sql
DELETE FROM ORDERITEM WHERE Quantity = 0;
```
* **[>> צילום הרצה + צילום מסך לפני/אחרי <<]**

3. **הסרת מוצרים רדומים באמצעות תת-שאילתה דינאמית:** משמיד מקטלוג מניפת המוצרים את המוצרים שלעולם לא דרכו בשורת רכש מתישהו.
```sql
DELETE FROM PRODUCT 
WHERE ProductID NOT IN (SELECT DISTINCT ProductID FROM ORDERITEM);
```
* **[>> צילום הרצה + צילום מסך לפני/אחרי <<]**

---

## 3 אילוצים (Constraints)
**הסברים למילון הנתונים (מוטיבציה ותועלת):**
אילוצים משפרים את אמינות המערכת. אי הוספת אילוץ תאפשר למשתמש להחריב מידע קריטי על ידי הכנסת "זבל" כנתונים פיננסיים אלו.

#### אילוץ 1. מניעת הזנת כמות אפסית או שלילית
אף משתמש לא יכול להזמין מספר פריטים שקטן מ-1:
```sql
ALTER TABLE ORDERITEM ADD CONSTRAINT chk_quantity_positive CHECK (Quantity > 0);
```
* **[>> צילום שגיאת מערכת לאחר ניסיון להכניס שורת כמות מינוס <<]**

#### אילוץ 2. הגנה על מחירי קטלוג
מוצר לא תומך במחיר פריק ושלילי:
```sql
ALTER TABLE PRODUCT ADD CONSTRAINT chk_price_positive CHECK (UnitPrice >= 0);
```
* **[>> צילום שגיאת מערכת על ניסיון INSERT של מחיר -50 לשטרות <<]**

#### אילוץ 3. ברירת מחדל לסטטוס רכש פתוח - Pending
מרבית ההזמנות הפרונטליות לא זכאיות לסטטוס ייצור, ולכן במקור אין להכניס אותן כשהן חצויות אלא בתור מצב מתפתח להמשך.
```sql
ALTER TABLE PURCHASEORDER ALTER COLUMN Status SET DEFAULT 'Pending';
```
* **[>> צילום מסך כראייה לשאילתת הוספה בלי עמודת סטטוס והתאכלסות הדיפולטיבית <<]**

---

## 3 אינדקסים (Indexes) וניתוח זמני ריצה

**הסבר למילון הנתונים ולמוטיבציה:**
כשיש לנו 20,000 שורות רכש במערכת נתונים, חיפושים פנימיים מצד מסכי האפליקציה עלולים לערוך המון זמן. ברגע שנוסיף אינדקס על אלמנט רלוונטי, קצוות הריצה יהפכו מחיפוש טורי שמונף על כל השורות ("Seq Scan") לכיוון קבלת האינדקס המהיר ("Index Scan").

1. **אינדקס על תאריך ההזמנה (`orderdate`)**
```sql
CREATE INDEX idx_order_date ON PURCHASEORDER(OrderDate);
```
* **תוצאה לפני ואחרי (כולל הסבר): [>> שים פה צילומי Explain Analyze <<]**
רצינו מהירות בחיפושי טווח שנות רכש. הוספתו הורידה את ה-Cost מיד!

2. **אינדקס על מפתח זר לשם ספק (`supplierid` בהזמנות)**
```sql
CREATE INDEX idx_fk_supplier ON PURCHASEORDER(SupplierID);
```
* **תוצאה לפני ואחרי (כולל הסבר): [>> שים פה צילומי Explain Analyze <<]**
מסייע בהצלות רבות כי סילוק הדוואנלוג נעשה מידי, אחרת חיבור ספק אחד לעשרות אלפי הזמנות יהיה חסר שליטה.

3. **אינדקס הצרנה של שם המוצר (`productname`)**
```sql
CREATE INDEX idx_product_name ON PRODUCT(ProductName);
```
* **תוצאה לפני ואחרי (כולל הסבר): [>> שים פה צילומי Explain Analyze <<]** 
לחיפוש שמי ברשימה `LIKE`.

---

## טרנזקציות: ROLLBACK לעומת COMMIT

### דרישה 8: טעות הרסנית ופעולת הצלה - ROLLBACK
1. **[>> להציג את מצב בסיס הנתונים השקוף בתמונה (עבור המוצרים לפני מחיר עתק) <<]**
2. נפתחה בועת טרנזקציה `BEGIN;`. התרחש עדכון כושל שהכפיל מחירי מוצרים המונית:
```sql
UPDATE PRODUCT SET UnitPrice = UnitPrice * 100;
```
3. במקביל לעדכון, המציאות נראית שחורה **[>> להציג את מצב הבלגן הזמני פנימית <<]**
4. ביטול מהיר `ROLLBACK;`. כל היסטוריית העדכון לא נשלחה לכתיבה לקשיח.
5. **[>> הצגת מצב ה-DB לאחר נביעת הריסט הרטרואקטיבי ולראות את המצב התקין! <<]**

### דרישה 9: עדכון שנעשה והוכר במערכת בשיטת COMMIT
1. כניסה שוב לתצורה של `BEGIN;`.
2. שרשור עדכון:
```sql
UPDATE PURCHASEORDER SET Status = 'Delivered' WHERE OrderID = 1;
```
3. עורכים בדיקות תקינות על קובץ האוורירי הזה מקרוב **[>> צילום המצב הפועם בעת בדיקה <<]**
4. הצלחה, מעגל הזיכרון מתהדק קדימה עם `COMMIT;`. עכשיו הוא חתום.
5. הנתונים זמינים לכל משתמש מחדש **[>> צילום המצב בו מצב ההזמנה נותר על Delivered לרווחה <<]** 
