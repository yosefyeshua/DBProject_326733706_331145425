-- ==============================================================================
-- קובץ מחיקת טבלאות - סדר המחיקה הוא הפוך ליצירה (מהבן לאב) 
-- כדי למנוע שגיאות Foreign Key Constraints.
-- ==============================================================================

DROP TABLE PAYMENT;
DROP TABLE INVOICE;
DROP TABLE ORDERITEM;
DROP TABLE PURCHASEORDER;
DROP TABLE PRODUCT;
DROP TABLE SUPPLIER;