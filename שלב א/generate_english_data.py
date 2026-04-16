import random
from datetime import date, timedelta

START_DATE = date(2023, 1, 1)

# ==========================================
# מאגרי נתונים מורחבים וריאליסטיים לגן חיות
# ==========================================

adjectives = [
    'Premium', 'Standard', 'Organic', 'Heavy-Duty', 'Veterinary', 'Bulk', 'Fresh', 'Sterile',
    'Eco-Friendly', 'Commercial', 'Zoo-Grade', 'High-Protein', 'Industrial', 'Natural', 'Professional'
]

animals = [
    'Lion', 'Tiger', 'Elephant', 'Giraffe', 'Zebra', 'Rhino', 'Hippo', 'Gorilla', 'Chimpanzee', 'Lemur',
    'Kangaroo', 'Koala', 'Penguin', 'Ostrich', 'Parrot', 'Flamingo', 'Eagle', 'Snake', 'Crocodile', 'Turtle',
    'Iguana', 'Shark', 'Dolphin', 'Seal', 'Otter', 'Bear', 'Wolf', 'Fox', 'Deer', 'Camel', 'Meerkat', 
    'Cheetah', 'Leopard', 'Sloth', 'Panda', 'Monkey', 'Bat', 'Avian', 'Reptile', 'Aquatic', 'General'
]

# חלוקה לקטגוריות של ציוד אמיתי
food_items = [
    'Diet Pellets', 'Fresh Meat Cubes', 'Live Insects', 'Frozen Fish', 'Mixed Seeds', 'Alfalfa Hay Bales',
    'Nutritional Supplement', 'Vitamin Drops', 'Nectar Mix', 'Dried Fruit Assortment', 'Vegetable Mix', 'Calcium Powder'
]

medical_items = [
    'Syringes (50ml)', 'Gauze Bandages', 'Antibiotic Ointment', 'Anesthesia Darts', 'Surgical Scalpels', 
    'Ultrasound Gel', 'Digital Thermometer', 'Blood Test Kits', 'IV Fluids', 'Vaccine Vials', 'Deworming Tablets'
]

habitat_items = [
    'Chainlink Fencing', 'UV Heat Lamps', 'Industrial Water Filter', 'Climbing Ropes', 'Artificial Vines', 
    'Bedding Straw', 'Heated Artificial Rocks', 'Aquarium Glass Cleaner', 'Substrate Sand', 'Wooden Nesting Boxes'
]

enrichment_items = [
    'Puzzle Feeder', 'Giant Boomer Ball', 'Scratching Post', 'Heavy Chew Bones', 'Scent Lures', 
    'Foraging Mats', 'Rope Swings', 'Floating Pool Buoys', 'Treat Dispenser'
]

maintenance_items = [
    'Enclosure Disinfectant', 'Pressure Washer Hose', 'Steel Rakes', 'Shovels', 'Heavy Wheelbarrow', 
    'Trash Can Liners', 'Protective Handling Gloves', 'Safety Goggles', 'Brass Padlocks'
]

# איחוד כל סוגי הציוד לרשימה אחת ענקית
all_item_types = food_items + medical_items + habitat_items + enrichment_items + maintenance_items


with open('insertTables_Realistic_Pro.sql', 'w', encoding='utf-8') as f:
    f.write("-- ==================================================================\n")
    f.write("-- Professional Realistic Data Population Script (Except SUPPLIER)\n")
    f.write("-- ==================================================================\n\n")

    # --- 1. PRODUCT (500 Records) - ייצור שמות ייחודיים ---
    f.write("-- 2. PRODUCT (500 Records)\n")
    f.write("INSERT INTO PRODUCT (ProductID, ProductName, UnitPrice) VALUES\n")
    products = []
    generated_names = set() # שימוש בסט כדי לוודא שאין כפילויות בשמות
    
    i = 1
    while i <= 500:
        # יצירת קומבינציה אקראית
        adj = random.choice(adjectives)
        animal = random.choice(animals)
        item = random.choice(all_item_types)
        
        # לפעמים המוצר הוא כללי ולא משויך לחיה ספציפית (כמו מטאטא או מסנן מים)
        if item in maintenance_items or random.random() > 0.7:
            product_name = f"{adj} {item}"
        else:
            product_name = f"{adj} {animal} {item}"
            
        # בדיקה שהשם לא הוגרל כבר
        if product_name not in generated_names:
            generated_names.add(product_name)
            price = round(random.uniform(5.0, 1200.0), 2)
            clean_name = product_name.replace('"', '').replace("'", "")
            products.append(f"({i}, '{clean_name}', {price})")
            i += 1
            
    f.write(",\n".join(products) + ";\n\n")


    # --- 2. PURCHASEORDER (20,000 Records) ---
    f.write("-- 3. PURCHASEORDER (20,000 Records)\n")
    for i in range(1, 20001):
        sup_id = random.randint(1, 500) # מתחבר ל-500 הספקים שלך
        amount = round(random.uniform(150.0, 25000.0), 2)
        d = START_DATE + timedelta(days=random.randint(0, 1100)) # תאריכים פרוסים על פני כ-3 שנים
        f.write(f"INSERT INTO PURCHASEORDER (OrderID, TotalAmount, OrderDate, Status, SupplierID) VALUES ({i}, {amount}, '{d}', 'Approved', {sup_id});\n")
    f.write("\n")


    # --- 3. ORDERITEM (20,000 Records) ---
    f.write("-- 4. ORDERITEM (20,000 Records)\n")
    for i in range(1, 20001):
        prod_id = random.randint(1, 500)
        qty = random.randint(1, 250)
        price = round(random.uniform(5.0, 1200.0), 2)
        f.write(f"INSERT INTO ORDERITEM (OrderID, ProductID, Quantity, ActualPrice) VALUES ({i}, {prod_id}, {qty}, {price});\n")
    f.write("\n")


    # --- 4. INVOICE (500 Records) ---
    f.write("-- 5. INVOICE (500 Records)\n")
    f.write("INSERT INTO INVOICE (InvoiceID, InvoiceDate, TotalDue, OrderID) VALUES\n")
    invoices = []
    for i in range(1, 501):
        order_id = random.randint(1, 20000)
        d = START_DATE + timedelta(days=random.randint(30, 1150))
        due = round(random.uniform(500.0, 12000.0), 2)
        invoices.append(f"({i}, '{d}', {due}, {order_id})")
    f.write(",\n".join(invoices) + ";\n\n")


    # --- 5. PAYMENT (500 Records) ---
    f.write("-- 6. PAYMENT (500 Records)\n")
    f.write("INSERT INTO PAYMENT (PaymentID, PaymentDate, AmountPaid, PaymentMethod, InvoiceID) VALUES\n")
    payments = []
    methods = ['Credit Card', 'Bank Transfer', 'Wire Transfer', 'Corporate Check', 'ACH']
    for i in range(1, 501):
        d = START_DATE + timedelta(days=random.randint(60, 1200))
        amount = round(random.uniform(500.0, 12000.0), 2)
        method = random.choice(methods)
        payments.append(f"({i}, '{d}', {amount}, '{method}', {i})")
    f.write(",\n".join(payments) + ";\n\n")

print("The PRO realistic script is ready!")