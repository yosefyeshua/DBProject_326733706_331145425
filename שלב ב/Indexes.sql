-- =================================================================================
-- פרויקט בסיס נתונים - שלב ב': הוספת 3 אינדקסים (Indexes)
-- =================================================================================

-- אינדקס 1: על תאריך הזמנה (OrderDate)
-- שאילתת בדיקה לצלם לפני ואחרי: 
-- EXPLAIN ANALYZE SELECT * FROM PURCHASEORDER WHERE OrderDate = '2024-05-10';
CREATE INDEX idx_order_date ON PURCHASEORDER(OrderDate);

-- אינדקס 2: על מפתח זר - מזהה ספק בטבלת הזמנות (SupplierID)
-- שאילתת בדיקה לצלם לפני ואחרי: 
-- EXPLAIN ANALYZE SELECT * FROM PURCHASEORDER WHERE SupplierID = 150;
CREATE INDEX idx_fk_supplier ON PURCHASEORDER(SupplierID);

-- אינדקס 3: על שם מוצר לחיפוש טקסטואלי
-- שאילתת בדיקה לצלם לפני ואחרי: 
-- EXPLAIN ANALYZE SELECT * FROM PRODUCT WHERE ProductName LIKE 'Premium%';
CREATE INDEX idx_product_name ON PRODUCT(ProductName);