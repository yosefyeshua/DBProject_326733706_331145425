-- ==============================================================================
-- פרויקט בסיסי נתונים - אגף ניהול ורכש (Finance & Procurement)
-- קובץ: createTable.sql
-- מילון נתונים, אילוצי מציאות וסוגי נתונים מדויקים כלולים בקוד.
-- ==============================================================================

-- 1. טבלת ספקים (SUPPLIER)
-- מילון: הטבלה שומרת את פרטי חברות האספקה שעובדות עם גן החיות.
CREATE TABLE SUPPLIER
(
  SupplierID INT NOT NULL,
  SupplierName VARCHAR(100) NOT NULL, -- תוקן לטקסט
  Category VARCHAR(50) NOT NULL,      -- תוקן לטקסט
  ContactName VARCHAR(100) NOT NULL,  -- תוקן לטקסט
  Phone VARCHAR(20) NOT NULL UNIQUE,  -- תוקן לטקסט + נוסף אילוץ למניעת כפילות טלפונים
  PRIMARY KEY (SupplierID)
);

-- 2. טבלת מוצרים (PRODUCT)
-- מילון: קטלוג כל הפריטים שניתן לרכוש מכל הספקים.
CREATE TABLE PRODUCT
(
  ProductID INT NOT NULL,
  ProductName VARCHAR(100) NOT NULL,       -- תוקן לטקסט
  UnitPrice NUMERIC(10, 2) NOT NULL CHECK (UnitPrice > 0), -- תוקן לעשרוני + אילוץ: מחיר חיוב להיות גדול מאפס
  PRIMARY KEY (ProductID)
);

-- 3. טבלת הזמנות רכש (PURCHASEORDER - תוקנה שגיאת הכתיב)
-- מילון: מתעדת את כל הזמנות הרכש שיוצאות מהמערכת לספקים.
CREATE TABLE PURCHASEORDER
(
  OrderID INT NOT NULL,
  TotalAmount NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (TotalAmount >= 0), -- תוקן לעשרוני + אילוץ: לא שלילי
  OrderDate DATE NOT NULL, -- תוקן לתאריך (דרישת פרויקט: שדה תאריך משמעותי 1)
  Status VARCHAR(20) NOT NULL DEFAULT 'Pending', -- תוקן לטקסט עם ערך ברירת מחדל
  SupplierID INT NOT NULL,
  PRIMARY KEY (OrderID),
  FOREIGN KEY (SupplierID) REFERENCES SUPPLIER(SupplierID)
);

-- 4. טבלת שורות הזמנה (ORDERITEM)
-- מילון: ישות חלשה המפרטת אילו מוצרים וכמה מכל אחד יש בתוך כל הזמנה.
CREATE TABLE ORDERITEM
(
  OrderID INT NOT NULL,
  ProductID INT NOT NULL,
  Quantity INT NOT NULL CHECK (Quantity > 0), -- אילוץ: כמות לא יכולה להיות 0 או שלילית
  ActualPrice NUMERIC(10, 2) NOT NULL CHECK (ActualPrice >= 0), -- תוקן לעשרוני
  PRIMARY KEY (OrderID, ProductID), -- מפתח ראשי מורכב (ישות חלשה)
  FOREIGN KEY (OrderID) REFERENCES PURCHASEORDER(OrderID),
  FOREIGN KEY (ProductID) REFERENCES PRODUCT(ProductID)
);

-- 5. טבלת חשבוניות (INVOICE)
-- מילון: דרישות התשלום שהתקבלו מהספקים לאחר ביצוע ההזמנה.
CREATE TABLE INVOICE
(
  InvoiceID INT NOT NULL,
  InvoiceDate DATE NOT NULL, -- תוקן לתאריך
  TotalDue NUMERIC(12, 2) NOT NULL CHECK (TotalDue >= 0), -- תוקן לעשרוני + אילוץ חיוביות
  OrderID INT NOT NULL,
  PRIMARY KEY (InvoiceID),
  FOREIGN KEY (OrderID) REFERENCES PURCHASEORDER(OrderID)
);

-- 6. טבלת תשלומים (PAYMENT)
-- מילון: תיעוד הכספים שיצאו בפועל מקופת גן החיות לכיסוי החשבוניות.
CREATE TABLE PAYMENT
(
  PaymentID INT NOT NULL,
  PaymentDate DATE NOT NULL, -- תוקן לתאריך (דרישת פרויקט: שדה תאריך משמעותי 2)
  AmountPaid NUMERIC(12, 2) NOT NULL CHECK (AmountPaid > 0), -- תוקן לעשרוני + אילוץ
  PaymentMethod VARCHAR(50) NOT NULL, -- תוקן לטקסט
  InvoiceID INT NOT NULL,
  PRIMARY KEY (PaymentID),
  FOREIGN KEY (InvoiceID) REFERENCES INVOICE(InvoiceID)
);