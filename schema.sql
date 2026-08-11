-- ============================================
-- Ride Sharing Management System
-- Part-1 : Database & Tables
-- ============================================

USE defaultdb;
-- ============================================
-- USERS TABLE
-- ============================================

CREATE TABLE Users
(
    UserID INT AUTO_INCREMENT PRIMARY KEY,

    FullName VARCHAR(100) NOT NULL,

    Email VARCHAR(100) NOT NULL UNIQUE,

    Password VARCHAR(100) NOT NULL,

    Phone VARCHAR(20) NOT NULL,

    Role ENUM('Passenger','Driver','Admin')
    NOT NULL DEFAULT 'Passenger',

    RegistrationDate DATETIME
    DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- DRIVERS TABLE
-- ============================================

CREATE TABLE Drivers
(
    DriverID INT AUTO_INCREMENT PRIMARY KEY,

    UserID INT NOT NULL UNIQUE,

    LicenseNumber VARCHAR(50) NOT NULL UNIQUE,

    VehicleType VARCHAR(50) NOT NULL,

    AvailabilityStatus
    ENUM('Available','Unavailable')
    DEFAULT 'Available',

    FOREIGN KEY(UserID)
    REFERENCES Users(UserID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- ============================================
-- VEHICLES TABLE
-- ============================================

CREATE TABLE Vehicles
(
    VehicleID INT AUTO_INCREMENT PRIMARY KEY,

    DriverID INT NOT NULL,

    VehicleNumber VARCHAR(30) NOT NULL UNIQUE,

    VehicleModel VARCHAR(100),

    VehicleColor VARCHAR(50),

    VehicleType VARCHAR(50),

    FOREIGN KEY(DriverID)
    REFERENCES Drivers(DriverID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- ============================================
-- RIDES TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS Rides (
    RideID INT AUTO_INCREMENT PRIMARY KEY,
    PassengerID INT NOT NULL,
    DriverID INT NULL,
    PickupLocation VARCHAR(150) NOT NULL,
    DropoffLocation VARCHAR(255) NOT NULL,
    Distance DECIMAL(6, 2) DEFAULT NULL,
    Fare DECIMAL(10, 2) DEFAULT NULL,
    VehicleType VARCHAR(20) DEFAULT 'Car',
    RideDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Status ENUM('Requested', 'Accepted', 'Completed', 'Cancelled') DEFAULT 'Requested',
    FOREIGN KEY (PassengerID) REFERENCES Users(UserID) ON DELETE CASCADE,
    FOREIGN KEY (DriverID) REFERENCES Users(UserID) ON DELETE SET NULL
);

-- ============================================
-- SETTINGS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS Settings (
    SettingKey VARCHAR(50) PRIMARY KEY,
    SettingValue VARCHAR(50) NOT NULL
);

INSERT INTO Settings (SettingKey, SettingValue) VALUES 
('rate_car', '30'),
('rate_bike', '15'),
('rate_cng', '20')
ON DUPLICATE KEY UPDATE SettingValue=VALUES(SettingValue);


-- ============================================
-- PAYMENTS TABLE
-- ============================================

CREATE TABLE Payments
(
    PaymentID INT AUTO_INCREMENT PRIMARY KEY,

    RideID INT NOT NULL,

    Amount DECIMAL(10,2) NOT NULL,

    PaymentMethod
    ENUM('Cash','Bkash','Nagad','Card')
    NOT NULL,

    PaymentStatus
    ENUM('Pending','Paid','Failed')
    DEFAULT 'Pending',

    PaymentDate DATETIME
    DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY(RideID)
    REFERENCES Rides(RideID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- ============================================
-- REWARD POINTS TABLE
-- ============================================

CREATE TABLE RewardPoints
(
    RewardID INT AUTO_INCREMENT PRIMARY KEY,

    PassengerID INT NOT NULL UNIQUE,

    TotalPoint INT DEFAULT 0,

    FOREIGN KEY(PassengerID)
    REFERENCES Users(UserID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- ============================================
-- REVIEWS TABLE
-- ============================================

CREATE TABLE Reviews
(
    ReviewID INT AUTO_INCREMENT PRIMARY KEY,

    RideID INT NOT NULL,

    PassengerID INT NOT NULL,

    DriverID INT NOT NULL,

    Rating INT CHECK(Rating BETWEEN 1 AND 5),

    Comment VARCHAR(255),

    ReviewDate DATETIME
    DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY(RideID)
    REFERENCES Rides(RideID)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

    FOREIGN KEY(PassengerID)
    REFERENCES Users(UserID)
    ON DELETE CASCADE
    ON UPDATE CASCADE,

    FOREIGN KEY(DriverID)
    REFERENCES Drivers(DriverID)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- ============================================
-- END OF PART-1
-- ============================================


-- ============================================
-- Ride Sharing Management System
-- Part-2A : Insert Data (Users)
-- ============================================

USE defaultdb;

INSERT INTO Users (FullName, Email, Password, Phone, Role)
VALUES
('Jubayer Hasan', 'jubayerhasan447@gmail.com', 'jubayeradmin', '01751533374', 'Admin'),
('Rahim Uddin', 'rahim@gmail.com', 'rahim123', '01710000002', 'Driver'),
('Karim Hasan', 'karim@gmail.com', 'karim123', '01710000003', 'Driver'),
('Sakib Ahmed', 'sakib@gmail.com', 'sakib123', '01710000004', 'Driver'),
('Nayeem Islam', 'nayeem@gmail.com', 'nayeem123', '01710000005', 'Driver'),
('Rafi Hossain', 'rafi@gmail.com', 'rafi123', '01710000006', 'Driver'),
('Noman Khan', 'noman@gmail.com', 'noman123', '01710000007', 'Passenger'),
('Tanvir Hasan', 'tanvir@gmail.com', 'tanvir123', '01710000008', 'Passenger'),
('Mehedi Islam', 'mehedi@gmail.com', 'mehedi123', '01710000009', 'Passenger'),
('Farhan Ahmed', 'farhan@gmail.com', 'farhan123', '01710000010', 'Passenger')
ON DUPLICATE KEY UPDATE 
FullName=VALUES(FullName), 
Password=VALUES(Password), 
Phone=VALUES(Phone);

-- ============================================
-- Check Data
-- ============================================

SELECT * FROM Users;


-- ============================================
-- Ride Sharing Management System
-- Part-2B : Insert Drivers & Vehicles
-- ============================================

USE defaultdb;

-- ============================================
-- INSERT INTO Drivers
-- ============================================

INSERT INTO Drivers
(UserID, LicenseNumber, VehicleType, AvailabilityStatus)

VALUES

(2,'DL10001','Car','Available'),

(3,'DL10002','Bike','Available'),

(4,'DL10003','Car','Unavailable'),

(5,'DL10004','Bike','Available'),

(6,'DL10005','Car','Available');


-- ============================================
-- INSERT INTO Vehicles
-- ============================================

INSERT INTO Vehicles
(DriverID, VehicleNumber, VehicleModel, VehicleColor, VehicleType)

VALUES

(1,'DHK-11-1234','Toyota Axio','White','Car'),

(2,'DHK-22-5678','Honda CBR','Black','Bike'),

(3,'DHK-33-9012','Toyota Premio','Silver','Car'),

(4,'DHK-44-3456','Yamaha FZS','Blue','Bike'),

(5,'DHK-55-7890','Toyota Corolla','Red','Car');


-- ============================================
-- CHECK DATA
-- ============================================

SELECT * FROM Drivers;

SELECT * FROM Vehicles;


-- ============================================
-- Ride Sharing Management System
-- Part-2C : Insert Rides
-- ============================================

USE defaultdb;

INSERT INTO Rides
(
    PassengerID,
    DriverID,
    PickupLocation,
    DropoffLocation,
    Distance,
    Fare,
    RideDate,
    Status
)

VALUES

(7,1,'Mirpur','Banani',12.50,250.00,'2026-08-01 09:00:00','Completed'),

(8,2,'Uttara','Airport',8.20,180.00,'2026-08-01 10:30:00','Completed'),

(9,3,'Dhanmondi','Gulshan',10.50,220.00,'2026-08-02 11:15:00','Accepted'),

(10,4,'Mohakhali','Farmgate',6.80,150.00,'2026-08-02 01:45:00','Requested'),

(7,5,'Banani','Bashundhara',9.70,210.00,'2026-08-03 03:00:00','Completed'),

(8,1,'Mirpur','Motijheel',15.40,320.00,'2026-08-03 05:30:00','Cancelled'),

(9,2,'Farmgate','Shyamoli',5.30,120.00,'2026-08-04 08:45:00','Completed'),

(10,3,'Gulshan','Mohakhali',4.90,100.00,'2026-08-04 12:20:00','Accepted'),

(7,4,'Uttara','Banani',11.80,260.00,'2026-08-05 02:10:00','Requested'),

(8,5,'Mirpur','Dhanmondi',13.60,280.00,'2026-08-05 06:00:00','Completed');

-- ============================================
-- CHECK DATA
-- ============================================

SELECT * FROM Rides;


-- ============================================
-- Ride Sharing Management System
-- Part-2D : Insert Payments
-- ============================================

USE defaultdb;

INSERT INTO Payments
(
    RideID,
    Amount,
    PaymentMethod,
    PaymentStatus,
    PaymentDate
)

VALUES

(1,250.00,'Bkash','Paid','2026-08-01 09:30:00'),

(2,180.00,'Cash','Paid','2026-08-01 11:00:00'),

(3,220.00,'Nagad','Pending','2026-08-02 11:45:00'),

(4,150.00,'Cash','Pending','2026-08-02 02:10:00'),

(5,210.00,'Card','Paid','2026-08-03 03:30:00'),

(6,320.00,'Bkash','Failed','2026-08-03 06:00:00'),

(7,120.00,'Nagad','Paid','2026-08-04 09:15:00'),

(8,100.00,'Cash','Pending','2026-08-04 12:45:00'),

(9,260.00,'Bkash','Pending','2026-08-05 02:40:00'),

(10,280.00,'Card','Paid','2026-08-05 06:30:00');

-- ============================================
-- CHECK DATA
-- ============================================

SELECT * FROM Payments;

-- ============================================
-- Ride Sharing Management System
-- Part-2E : Insert Reward Points & Reviews
-- ============================================

USE defaultdb;

-- ============================================
-- INSERT INTO RewardPoints
-- ============================================

INSERT INTO RewardPoints
(
    PassengerID,
    TotalPoint
)

VALUES

(7,120),

(8,85),

(9,60),

(10,40);

-- ============================================
-- INSERT INTO Reviews
-- ============================================

INSERT INTO Reviews
(
    RideID,
    PassengerID,
    DriverID,
    Rating,
    Comment,
    ReviewDate
)

VALUES

(1,7,1,5,'Excellent ride and friendly driver.','2026-08-01 10:00:00'),

(2,8,2,4,'Good driving experience.','2026-08-01 11:20:00'),

(5,7,5,5,'Very comfortable journey.','2026-08-03 04:00:00'),

(7,9,2,4,'Driver was polite and on time.','2026-08-04 09:30:00'),

(10,8,5,5,'Fast and safe ride.','2026-08-05 07:00:00');

-- ============================================
-- CHECK DATA
-- ============================================

SELECT * FROM RewardPoints;

SELECT * FROM Reviews;

-- ============================================
-- END OF INSERT DATA
-- ============================================


-- ============================================
-- Ride Sharing Management System
-- Part-3 : Views, Stored Procedures, Functions
-- ============================================

USE defaultdb;

-- ============================================
-- VIEW-1 : Ride Details
-- ============================================

CREATE VIEW RideDetails AS

SELECT

R.RideID,

P.FullName AS Passenger,

DUser.FullName AS Driver,

R.PickupLocation,

R.DropoffLocation,

R.Distance,

R.Fare,

R.Status,

R.RideDate

FROM Rides R

INNER JOIN Users P
ON R.PassengerID=P.UserID

INNER JOIN Drivers D
ON R.DriverID=D.DriverID

INNER JOIN Users DUser
ON D.UserID=DUser.UserID;


-- ============================================
-- VIEW-2 : Payment Details
-- ============================================

CREATE VIEW PaymentDetails AS

SELECT

P.PaymentID,

U.FullName,

R.RideID,

P.Amount,

P.PaymentMethod,

P.PaymentStatus,

P.PaymentDate

FROM Payments P

INNER JOIN Rides R
ON P.RideID=R.RideID

INNER JOIN Users U
ON R.PassengerID=U.UserID;


-- ============================================
-- VIEW-3 : Driver Information
-- ============================================

CREATE VIEW DriverInformation AS

SELECT

D.DriverID,

U.FullName,

U.Email,

U.Phone,

D.VehicleType,

D.AvailabilityStatus

FROM Drivers D

INNER JOIN Users U
ON D.UserID=U.UserID;


-- ============================================
-- STORED PROCEDURE-1
-- Get All Completed Rides
-- ============================================

DELIMITER $$

CREATE PROCEDURE GetCompletedRides()

BEGIN

SELECT *

FROM RideDetails

WHERE Status='Completed';

END$$

DELIMITER ;


-- ============================================
-- STORED PROCEDURE-2
-- Get Passenger Ride History
-- ============================================

DELIMITER $$

CREATE PROCEDURE GetPassengerRides

(

IN pid INT

)

BEGIN

SELECT *

FROM RideDetails

WHERE RideID IN

(

SELECT RideID

FROM Rides

WHERE PassengerID=pid

);

END$$

DELIMITER ;


-- ============================================
-- STORED PROCEDURE-3
-- Get Driver Information
-- ============================================

DELIMITER $$

CREATE PROCEDURE GetDriverInformation()

BEGIN

SELECT *

FROM DriverInformation;

END$$

DELIMITER ;


-- ============================================
-- FUNCTION-1
-- Total Fare By Passenger
-- ============================================

DELIMITER $$

CREATE FUNCTION TotalFare

(

pid INT

)

RETURNS DECIMAL(10,2)

DETERMINISTIC

BEGIN

DECLARE total DECIMAL(10,2);

SELECT SUM(Fare)

INTO total

FROM Rides

WHERE PassengerID=pid;

RETURN IFNULL(total,0);

END$$

DELIMITER ;


-- ============================================
-- FUNCTION-2
-- Total Completed Ride
-- ============================================

DELIMITER $$

CREATE FUNCTION CompletedRideCount

(

pid INT

)

RETURNS INT

DETERMINISTIC

BEGIN

DECLARE total INT;

SELECT COUNT(*)

INTO total

FROM Rides

WHERE PassengerID=pid

AND Status='Completed';

RETURN total;

END$$

DELIMITER ;


-- ============================================
-- TEST QUERIES
-- ============================================

SELECT * FROM RideDetails;

SELECT * FROM PaymentDetails;

SELECT * FROM DriverInformation;

CALL GetCompletedRides();

CALL GetPassengerRides(7);

CALL GetDriverInformation();

SELECT TotalFare(7);

SELECT CompletedRideCount(7);

-- ============================================
-- END OF PART-3
-- ============================================


-- ============================================
-- Ride Sharing Management System
-- Part-4 : Triggers, Transactions & Advanced Queries
-- ============================================

USE defaultdb;

-- ============================================
-- TRIGGER-1
-- Update Ride Status After Successful Payment
-- ============================================

DELIMITER $$

CREATE TRIGGER PaymentStatusTrigger

AFTER INSERT

ON Payments

FOR EACH ROW

BEGIN

    IF NEW.PaymentStatus='Paid' THEN

        UPDATE Rides

        SET Status='Completed'

        WHERE RideID=NEW.RideID;

    END IF;

END$$

DELIMITER ;



-- ============================================
-- TRIGGER-2
-- Add Reward Point After Completed Ride
-- ============================================

DELIMITER $$

CREATE TRIGGER RewardPointTrigger

AFTER UPDATE

ON Rides

FOR EACH ROW

BEGIN

    IF NEW.Status='Completed'
    AND OLD.Status<>'Completed' THEN

        UPDATE RewardPoints

        SET TotalPoint=TotalPoint+10

        WHERE PassengerID=NEW.PassengerID;

    END IF;

END$$

DELIMITER ;



-- ============================================
-- TRANSACTION EXAMPLE
-- ============================================

START TRANSACTION;

INSERT INTO Payments
(
RideID,
Amount,
PaymentMethod,
PaymentStatus
)

VALUES
(
3,
220,
'Bkash',
'Paid'
);

UPDATE Rides

SET Status='Completed'

WHERE RideID=3;

COMMIT;



-- ============================================
-- ROLLBACK EXAMPLE
-- ============================================

START TRANSACTION;

INSERT INTO Payments
(
RideID,
Amount,
PaymentMethod,
PaymentStatus
)

VALUES
(
4,
150,
'Cash',
'Pending'
);

ROLLBACK;



-- ============================================
-- ADVANCED SQL QUERIES
-- ============================================

-- Total Income

SELECT SUM(Amount) AS TotalIncome

FROM Payments

WHERE PaymentStatus='Paid';


-- Total Ride

SELECT COUNT(*) AS TotalRide

FROM Rides;


-- Total Passenger

SELECT COUNT(*) AS TotalPassenger

FROM Users

WHERE Role='Passenger';


-- Total Driver

SELECT COUNT(*) AS TotalDriver

FROM Drivers;


-- Completed Ride

SELECT COUNT(*) AS CompletedRide

FROM Rides

WHERE Status='Completed';


-- Pending Ride

SELECT COUNT(*) AS PendingRide

FROM Rides

WHERE Status='Requested';


-- Cancelled Ride

SELECT COUNT(*) AS CancelledRide

FROM Rides

WHERE Status='Cancelled';


-- Highest Fare

SELECT MAX(Fare)

AS HighestFare

FROM Rides;


-- Lowest Fare

SELECT MIN(Fare)

AS LowestFare

FROM Rides;


-- Average Fare

SELECT AVG(Fare)

AS AverageFare

FROM Rides;


-- Top 5 Expensive Ride

SELECT *

FROM Rides

ORDER BY Fare DESC

LIMIT 5;


-- Driver Wise Ride Count

SELECT

DriverID,

COUNT(*) AS TotalRide

FROM Rides

GROUP BY DriverID;


-- Passenger Wise Ride Count

SELECT

PassengerID,

COUNT(*) AS TotalRide

FROM Rides

GROUP BY PassengerID;


-- Paid Payment

SELECT *

FROM Payments

WHERE PaymentStatus='Paid';


-- Pending Payment

SELECT *

FROM Payments

WHERE PaymentStatus='Pending';


-- Failed Payment

SELECT *

FROM Payments

WHERE PaymentStatus='Failed';


-- Available Driver

SELECT *

FROM Drivers

WHERE AvailabilityStatus='Available';


-- Unavailable Driver

SELECT *

FROM Drivers

WHERE AvailabilityStatus='Unavailable';


-- Reward Point List

SELECT *

FROM RewardPoints

ORDER BY TotalPoint DESC;


-- Review List

SELECT *

FROM Reviews;

-- ============================================
-- END OF PART-4
-- ============================================

