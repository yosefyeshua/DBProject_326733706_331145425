-- =================================================================================
-- פרויקט בסיס נתונים - שלב ב': הוספת 3 אילוצים (Constraints)
-- =================================================================================

-- אילוץ 1: מניעת הזנת כמות שלילית או אפס בשורות הזמנה (אי אפשר להזמין 0 פריטים)
ALTER TABLE ORDERITEM 
ADD CONSTRAINT chk_quantity_positive CHECK (Quantity > 0);

-- אילוץ 2: מניעת מחיר שלילי למוצר בקטלוג
ALTER TABLE PRODUCT 
ADD CONSTRAINT chk_price_positive CHECK (UnitPrice >= 0);

-- אילוץ 3: ערך ברירת מחדל - אם פותחים הזמנה ולא מכניסים סטטוס, היא תוגדר כ-'Pending'
ALTER TABLE PURCHASEORDER 
ALTER COLUMN Status SET DEFAULT 'Pending';