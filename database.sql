/* ===========================================================
   ONLINE ORDER MANAGEMENT SYSTEM — FINAL SQL SCRIPT
   Includes:
   - Tables, Triggers, Procedures, Functions
   - User Privileges
   - Demonstration Calls (CALL / SELECT)
   =========================================================== */

DROP DATABASE IF EXISTS online_order_system;
CREATE DATABASE online_order_system;
USE online_order_system;

/* ===========================================================
   TABLE CREATION
   =========================================================== */

CREATE TABLE CUSTOMER (
    ID INT PRIMARY KEY AUTO_INCREMENT,
    Fname VARCHAR(50),
    Lname VARCHAR(50),
    DoB DATE NOT NULL,
    Age INT CHECK (Age > 0),
    City VARCHAR(50),
    Pincode VARCHAR(10)
);

CREATE TABLE CUSTOMER_PHONE (
    ID INT,
    Ph_no VARCHAR(15),
    PRIMARY KEY (ID, Ph_no),
    FOREIGN KEY (ID) REFERENCES CUSTOMER(ID)
);

CREATE TABLE SELLER (
    SID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100),
    City VARCHAR(50),
    Pincode VARCHAR(10),
    Rating DECIMAL(2,1) CHECK (Rating BETWEEN 1 AND 5)
);

CREATE TABLE SELLER_PHONE (
    SID INT,
    Ph_no VARCHAR(15),
    PRIMARY KEY (SID, Ph_no),
    FOREIGN KEY (SID) REFERENCES SELLER(SID)
);

CREATE TABLE PRODUCT (
    Sel_ID INT,
    Item VARCHAR(100),
    Category VARCHAR(50),
    Price DECIMAL(10,2) CHECK (Price > 0),
    PRIMARY KEY (Sel_ID, Item),
    FOREIGN KEY (Sel_ID) REFERENCES SELLER(SID)
);

CREATE TABLE DELIVERY_PARTNER (
    DID INT PRIMARY KEY AUTO_INCREMENT,
    D_Name VARCHAR(100),
    City VARCHAR(50)
);

CREATE TABLE DELIVERY_PARTNER_PHONE (
    DID INT,
    Ph_no VARCHAR(15),
    PRIMARY KEY (DID, Ph_no),
    FOREIGN KEY (DID) REFERENCES DELIVERY_PARTNER(DID)
);

CREATE TABLE `ORDER` (
    OID INT PRIMARY KEY AUTO_INCREMENT,
    CID INT,
    Sel_ID INT,
    D_ID INT,
    Item VARCHAR(100),
    Status VARCHAR(20) CHECK (Status IN ('Pending','Preparing','Out for Delivery','Delivered','Cancelled')),
    Quantity INT CHECK (Quantity > 0),
    FOREIGN KEY (CID) REFERENCES CUSTOMER(ID),
    FOREIGN KEY (Sel_ID, Item) REFERENCES PRODUCT(Sel_ID, Item),
    FOREIGN KEY (D_ID) REFERENCES DELIVERY_PARTNER(DID)
);

CREATE TABLE PAYMENT (
    ONO INT,
    Txn_no VARCHAR(30),
    Mode VARCHAR(20) CHECK (Mode IN ('Cash','Credit Card','UPI','Net Banking')),
    PRIMARY KEY (ONO),
    FOREIGN KEY (ONO) REFERENCES `ORDER`(OID)
);

/* ===========================================================
   INITIAL DATA INSERTION
   =========================================================== */

-- CUSTOMERS
INSERT INTO CUSTOMER (Fname, Lname, DoB, Age, City, Pincode) VALUES
('Ravi', 'Kumar', '2000-04-15', 25, 'Bangalore', '560001'),
('Priya', 'Sharma', '1998-09-21', 27, 'Hyderabad', '500001'),
('Amit', 'Verma', '1999-12-05', 26, 'Chennai', '600001');

INSERT INTO CUSTOMER_PHONE VALUES
(1, '9876543210'),
(1, '9822334455'),
(2, '9998887776'),
(3, '9123456789');

-- SELLERS
INSERT INTO SELLER (Name, City, Pincode, Rating) VALUES
('Spice Garden', 'Bangalore', '560002', 4.7),
('Tandoori Treats', 'Hyderabad', '500002', 4.4),
('Pizza Point', 'Mumbai', '400001', 4.9);

INSERT INTO SELLER_PHONE VALUES
(1, '9123456700'),
(1, '9876500011'),
(2, '9988776655'),
(3, '9000000001');

-- PRODUCTS
INSERT INTO PRODUCT (Sel_ID, Item, Category, Price) VALUES
(1, 'Paneer Butter Masala', 'North Indian', 220.00),
(1, 'Veg Biryani', 'South Indian', 180.00),
(2, 'Chicken Tikka', 'Mughlai', 250.00),
(3, 'Margherita Pizza', 'Italian', 300.00);

-- DELIVERY PARTNERS
INSERT INTO DELIVERY_PARTNER (D_Name, City) VALUES
('FastEats', 'Bangalore'),
('QuickServe', 'Mumbai'),
('SpeedyDelivery', 'Chennai');

INSERT INTO DELIVERY_PARTNER_PHONE VALUES
(1, '8887776665'),
(1, '8887776666'),
(2, '9999998888'),
(3, '9876543221');

-- ORDERS
INSERT INTO `ORDER` (CID, Sel_ID, D_ID, Item, Status, Quantity) VALUES
(1, 1, 1, 'Paneer Butter Masala', 'Preparing', 2),
(2, 2, 2, 'Chicken Tikka', 'Out for Delivery', 1),
(3, 3, 3, 'Margherita Pizza', 'Delivered', 1);

-- PAYMENTS
INSERT INTO PAYMENT (ONO, Txn_no, Mode) VALUES
(1, 'TXN20001', 'UPI'),
(2, 'TXN20002', 'Credit Card'),
(3, 'TXN20003', 'Cash');

/* ===========================================================
   TRIGGERS
   =========================================================== */

DELIMITER $$

DROP TRIGGER IF EXISTS before_customer_insert_age$$
CREATE TRIGGER before_customer_insert_age
BEFORE INSERT ON CUSTOMER
FOR EACH ROW
BEGIN
  IF NEW.DoB IS NOT NULL THEN
    SET NEW.Age = TIMESTAMPDIFF(YEAR, NEW.DoB, CURDATE());
    IF NEW.Age <= 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid DoB: computed Age <= 0';
    END IF;
  END IF;
END$$


/* ===========================================================
   STORED PROCEDURES & FUNCTION DEFINITIONS
   =========================================================== */

-- CUSTOMER CRUD
DROP PROCEDURE IF EXISTS CreateCustomer$$
CREATE PROCEDURE CreateCustomer(
  IN p_Fname VARCHAR(50), IN p_Lname VARCHAR(50),
  IN p_DoB DATE, IN p_City VARCHAR(50), IN p_Pincode VARCHAR(10)
)
BEGIN
  INSERT INTO CUSTOMER (Fname, Lname, DoB, City, Pincode)
  VALUES (p_Fname, p_Lname, p_DoB, p_City, p_Pincode);
END$$

DROP PROCEDURE IF EXISTS ReadAllCustomers$$
CREATE PROCEDURE ReadAllCustomers()
BEGIN
  SELECT * FROM CUSTOMER;
END$$

DROP PROCEDURE IF EXISTS UpdateCustomer$$
CREATE PROCEDURE UpdateCustomer(
  IN p_ID INT, IN p_Fname VARCHAR(50), IN p_Lname VARCHAR(50),
  IN p_City VARCHAR(50), IN p_Pincode VARCHAR(10)
)
BEGIN
  UPDATE CUSTOMER
  SET Fname = p_Fname, Lname = p_Lname, City = p_City, Pincode = p_Pincode
  WHERE ID = p_ID;
END$$

DROP PROCEDURE IF EXISTS DeleteCustomer$$
CREATE PROCEDURE DeleteCustomer(IN p_ID INT)
BEGIN
  DELETE FROM CUSTOMER WHERE ID = p_ID;
END$$

-- PRODUCT CRUD
DROP PROCEDURE IF EXISTS CreateProduct$$
CREATE PROCEDURE CreateProduct(
  IN p_Sel_ID INT, IN p_Item VARCHAR(100), IN p_Category VARCHAR(50), IN p_Price DECIMAL(10,2)
)
BEGIN
  INSERT INTO PRODUCT (Sel_ID, Item, Category, Price)
  VALUES (p_Sel_ID, p_Item, p_Category, p_Price);
END$$

DROP PROCEDURE IF EXISTS ReadAllProducts$$
CREATE PROCEDURE ReadAllProducts()
BEGIN
  SELECT p.*, s.Name AS SellerName FROM PRODUCT p
  LEFT JOIN SELLER s ON p.Sel_ID = s.SID;
END$$

DROP PROCEDURE IF EXISTS UpdateProductPrice$$
CREATE PROCEDURE UpdateProductPrice(
  IN p_Sel_ID INT, IN p_Item VARCHAR(100), IN p_Price DECIMAL(10,2)
)
BEGIN
  UPDATE PRODUCT SET Price = p_Price WHERE Sel_ID = p_Sel_ID AND Item = p_Item;
END$$

DROP PROCEDURE IF EXISTS DeleteProduct$$
CREATE PROCEDURE DeleteProduct(IN p_Sel_ID INT, IN p_Item VARCHAR(100))
BEGIN
  DELETE FROM PRODUCT WHERE Sel_ID = p_Sel_ID AND Item = p_Item;
END$$

-- ORDER / PAYMENT Procedures
DROP PROCEDURE IF EXISTS PlaceOrder$$
CREATE PROCEDURE PlaceOrder(
  IN p_CID INT, IN p_Sel_ID INT, IN p_Item VARCHAR(100), IN p_DID INT, IN p_Quantity INT
)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM PRODUCT WHERE Sel_ID = p_Sel_ID AND Item = p_Item) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Product not found';
  END IF;

  INSERT INTO `ORDER` (CID, Sel_ID, D_ID, Item, Status, Quantity)
  VALUES (p_CID, p_Sel_ID, p_DID, p_Item, 'Pending', p_Quantity);

  SET @last_oid = LAST_INSERT_ID();
  INSERT INTO PAYMENT (ONO, Txn_no, Mode)
  VALUES (@last_oid, CONCAT('TXN', LPAD(FLOOR(RAND()*1000000),6,'0')), 'UPI');
END$$

DROP PROCEDURE IF EXISTS CancelOrder$$
CREATE PROCEDURE CancelOrder(IN p_OID INT)
BEGIN
  UPDATE `ORDER` SET Status = 'Cancelled' WHERE OID = p_OID;
  DELETE FROM PAYMENT WHERE ONO = p_OID;
END$$

-- Analytical Queries
DROP PROCEDURE IF EXISTS GetOrdersJoinDetails$$
CREATE PROCEDURE GetOrdersJoinDetails()
BEGIN
  SELECT o.OID, c.ID AS CustomerID, CONCAT(c.Fname,' ',c.Lname) AS CustomerName,
         o.Item, o.Quantity, o.Status, s.SID AS SellerID, s.Name AS SellerName,
         d.DID AS DeliveryPartnerID, d.D_Name AS DeliveryPartner
  FROM `ORDER` o
  LEFT JOIN CUSTOMER c ON o.CID = c.ID
  LEFT JOIN SELLER s ON o.Sel_ID = s.SID
  LEFT JOIN DELIVERY_PARTNER d ON o.D_ID = d.DID
  ORDER BY o.OID DESC;
END$$

DROP PROCEDURE IF EXISTS GetCustomersWithMultiplePhones$$
CREATE PROCEDURE GetCustomersWithMultiplePhones()
BEGIN
  SELECT c.ID, CONCAT(c.Fname,' ',c.Lname) AS CustomerName,
         (SELECT COUNT(*) FROM CUSTOMER_PHONE cp WHERE cp.ID = c.ID) AS PhoneCount
  FROM CUSTOMER c
  WHERE (SELECT COUNT(*) FROM CUSTOMER_PHONE cp WHERE cp.ID = c.ID) > 1;
END$$

DROP FUNCTION IF EXISTS GetCustomerTotalSpent$$
CREATE FUNCTION GetCustomerTotalSpent(p_CID INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
  DECLARE total DECIMAL(12,2) DEFAULT 0;
  SELECT IFNULL(SUM(pr.Price * o.Quantity),0) INTO total
  FROM `ORDER` o
  JOIN PRODUCT pr ON pr.Sel_ID = o.Sel_ID AND pr.Item = o.Item
  WHERE o.CID = p_CID AND o.Status = 'Delivered';
  RETURN total;
END$$

DELIMITER ;

/* ===========================================================
   DEMONSTRATION CALLS (FOR PRESENTATION / VIVA)
   =========================================================== */

-- 1️⃣ View all customers
CALL ReadAllCustomers();

-- 2️⃣ Add a new customer (trigger auto-calculates Age)
CALL CreateCustomer('Sita', 'Rao', '2002-03-12', 'Delhi', '110001');

-- 3️⃣ Update a customer's details
CALL UpdateCustomer(1, 'Ravi', 'Kumar', 'Bangalore', '560002');

-- 4️⃣ Delete a customer
-- CALL DeleteCustomer(4);

-- 5️⃣ View all products (JOIN with Seller)
CALL ReadAllProducts();

-- 6️⃣ Add a new product
CALL CreateProduct(1, 'Masala Dosa', 'South Indian', 150.00);

-- 7️⃣ Update product price
CALL UpdateProductPrice(1, 'Masala Dosa', 160.00);

-- 8️⃣ Place an order (auto inserts Payment)
CALL PlaceOrder(1, 1, 'Masala Dosa', 1, 2);

-- 9️⃣ Cancel an order
CALL CancelOrder(1);

-- 🔟 Display order details (JOIN query)
CALL GetOrdersJoinDetails();

-- 11️⃣ Display customers with multiple phone numbers (Nested query)
CALL GetCustomersWithMultiplePhones();

-- 12️⃣ Calculate total amount spent by a customer (Aggregate function)
SELECT GetCustomerTotalSpent(3) AS Total_Spent_By_Customer3;

/* ===========================================================
   END OF SCRIPT
   =========================================================== */
