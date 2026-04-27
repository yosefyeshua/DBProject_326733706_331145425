-- =================================================================================
-- פרויקט בסיס נתונים - שלב ב': הוספת 3 אילוצים (Constraints)
-- =================================================================================

-- אילוץ 1: מניעת הזנת כמות שלילית או אפס בשורות הזמנה (אי אפשר להזמין 0 פריטים)
ALTER TABLE ORDERITEM 
ADD CONSTRAINT chk_quantity_positive CHECK (Quantity > 0);

-- אילוץ 2: מניעת מחיר שלילי למוצר בקטלוג
ALTER TABLE PRODUCT 
ADD CONSTRAINT chk_price_positive CHECK (UnitPrice >= 0);


-- אילוץ 3: הגבלת סטטוס הזמנה לרשימה מורשית בלבד (כדי שנוכל להוכיח שגיאה בדוח)
ALTER TABLE PURCHASEORDER 
ADD CONSTRAINT chk_valid_status CHECK (Status IN ('Pending', 'Approved', 'Delivered', 'Cancelled'));