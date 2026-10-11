-- WES corrected design. Requires MySQL 8.0.16+ for enforced CHECK constraints.
-- Run once against an empty schema. This is not a data migration.
CREATE SCHEMA IF NOT EXISTS wes_corrected DEFAULT CHARACTER SET utf8mb4;
USE wes_corrected;

CREATE TABLE `Customer_Types` (
  `Customer_Type` VARCHAR(45) NOT NULL PRIMARY KEY,
  CHECK (Customer_Type IN ('Student','Staff','Alumni','Guest'))
) ENGINE=InnoDB;

CREATE TABLE `Customers` (
  `Cust_ID` INT NOT NULL,
  `Cust_L_Nm` VARCHAR(45) NOT NULL,
  `Cust_F_Nm` VARCHAR(45) NOT NULL,
  `Cust_DOB` DATE NOT NULL,
  `Cust_ph` VARCHAR(25) NOT NULL,
  `Cust_Type` VARCHAR(45) NOT NULL,
  `Sponsor_ID` INT NULL,
  PRIMARY KEY (`Cust_ID`),
  INDEX `fk_Customers_Discount Tariff1_idx` (`Cust_Type` ASC),
  INDEX `fk_Customers_Customers1_idx` (`Sponsor_ID` ASC),
  CONSTRAINT `fk_Customers_Discount Tariff1`
    FOREIGN KEY (`Cust_Type`)
    REFERENCES `Customer_Types` (`Customer_Type`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Customers_Customers1`
    FOREIGN KEY (`Sponsor_ID`)
    REFERENCES `Customers` (`Cust_ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CHECK ((Cust_Type = 'Guest' AND Sponsor_ID IS NOT NULL) OR (Cust_Type <> 'Guest' AND Sponsor_ID IS NULL)),
  CHECK (Sponsor_ID IS NULL OR Sponsor_ID <> Cust_ID)
) ENGINE=InnoDB;

CREATE TABLE `WES_Staff` (
  `staff_ID` INT NOT NULL,
  `staff_l_name` VARCHAR(45) NOT NULL,
  `staff_f_name` VARCHAR(45) NOT NULL,
  `staff_des` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`staff_ID`)
) ENGINE=InnoDB;

CREATE TABLE `Trips` (
  `Trip_Code` VARCHAR(45) NOT NULL,
  `Trip_Nm` VARCHAR(45) NOT NULL,
  `Trip_Diff_Lvl` VARCHAR(45) NOT NULL,
  `Trip_Fee` DECIMAL(10,2) NOT NULL,
  `Trip_Length` SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (`Trip_Code`),
  CHECK (Trip_Fee >= 0),
  CHECK (Trip_Length > 0)
) ENGINE=InnoDB;

CREATE TABLE `Scheduled_Trips` (
  `Trip_Date` DATE NOT NULL,
  `Trip_Code` VARCHAR(45) NOT NULL,
  `Trip_Ldr` INT NOT NULL,
  `Trip_Asst_Ldr` INT NOT NULL,
  PRIMARY KEY (`Trip_Date`, `Trip_Code`),
  INDEX `fk_Scheduled Trips_WES_Employees1_idx` (`Trip_Ldr` ASC),
  INDEX `fk_Scheduled Trips_WES_Employees2_idx` (`Trip_Asst_Ldr` ASC),
  INDEX `fk_Scheduled_Trips_Trips1_idx` (`Trip_Code` ASC),
  CONSTRAINT `fk_Scheduled Trips_WES_Employees1`
    FOREIGN KEY (`Trip_Ldr`)
    REFERENCES `WES_Staff` (`staff_ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Scheduled Trips_WES_Employees2`
    FOREIGN KEY (`Trip_Asst_Ldr`)
    REFERENCES `WES_Staff` (`staff_ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Scheduled_Trips_Trips1`
    FOREIGN KEY (`Trip_Code`)
    REFERENCES `Trips` (`Trip_Code`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CHECK (Trip_Ldr <> Trip_Asst_Ldr)
) ENGINE=InnoDB;

CREATE TABLE `Trip_Reg` (
  `Reg_ID` INT NOT NULL,
  `Reg_Date` DATE NOT NULL,
  `Cust_ID` INT NOT NULL,
  `Trip_Date` DATE NOT NULL,
  `Trip_Code` VARCHAR(45) NOT NULL,
  `Ins_Waiv` BOOLEAN NOT NULL DEFAULT FALSE,
  `Transport_Needed` BOOLEAN NOT NULL DEFAULT FALSE,
  INDEX `fk_Registration_Customers_idx` (`Cust_ID` ASC),
  INDEX `fk_Registration_Scheduled Trips1_idx` (`Trip_Date` ASC),
  PRIMARY KEY (`Reg_ID`),
  CONSTRAINT `fk_Registration_Customers`
    FOREIGN KEY (`Cust_ID`)
    REFERENCES `Customers` (`Cust_ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Registration_Scheduled Trips1`
    FOREIGN KEY (`Trip_Date`, `Trip_Code`)
    REFERENCES `Scheduled_Trips` (`Trip_Date`, `Trip_Code`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  UNIQUE (Cust_ID, Trip_Date, Trip_Code),
  CHECK (Ins_Waiv IN (0,1)),
  CHECK (Transport_Needed IN (0,1)),
  CHECK (Reg_Date <= Trip_Date)
) ENGINE=InnoDB;

CREATE TABLE `Equipment_Type` (
  Equip_Type_ID INT NOT NULL PRIMARY KEY,
  Equip_Nm VARCHAR(100) NOT NULL,
  Equip_Category VARCHAR(45) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE `Equipment_Hire_Rate` (
  Equip_Type_ID INT NOT NULL,
  Rate_Category ENUM('Student','Staff/Alumni','Guest') NOT NULL,
  Daily_Rate DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (Equip_Type_ID, Rate_Category),
  FOREIGN KEY (Equip_Type_ID) REFERENCES Equipment_Type (Equip_Type_ID),
  CHECK (Daily_Rate >= 0)
) ENGINE=InnoDB;

CREATE TABLE `Equipments` (
  Equip_ID INT NOT NULL PRIMARY KEY,
  Equip_Type_ID INT NOT NULL,
  Equip_Condn VARCHAR(30) NOT NULL,
  FOREIGN KEY (Equip_Type_ID) REFERENCES Equipment_Type (Equip_Type_ID),
  CHECK (Equip_Condn IN ('Good','Fair','Poor'))
) ENGINE=InnoDB;

CREATE TABLE `Hire_Agreement` (
  Agreement_ID INT NOT NULL PRIMARY KEY,
  Hire_Date DATE NOT NULL,
  Cust_ID INT NOT NULL,
  Staff_empID INT NOT NULL,
  FOREIGN KEY (Cust_ID) REFERENCES Customers (Cust_ID),
  FOREIGN KEY (Staff_empID) REFERENCES WES_Staff (staff_ID)
) ENGINE=InnoDB;

CREATE TABLE `Hire_Item` (
  Agreement_ID INT NOT NULL,
  Equip_ID INT NOT NULL,
  Expected_Return DATE NOT NULL,
  Actual_ReturnDate DATE NULL,
  Daily_Rate_Agreed DECIMAL(10,2) NOT NULL COMMENT 'Rate snapshot at hire time',
  PRIMARY KEY (Agreement_ID, Equip_ID),
  FOREIGN KEY (Agreement_ID) REFERENCES Hire_Agreement (Agreement_ID),
  FOREIGN KEY (Equip_ID) REFERENCES Equipments (Equip_ID),
  CHECK (Daily_Rate_Agreed >= 0)
) ENGINE=InnoDB;

CREATE TABLE `Receipt` (
  Receipt_no VARCHAR(45) NOT NULL PRIMARY KEY,
  Agreement_ID INT NOT NULL,
  Payment_Date DATETIME NOT NULL,
  Amount_Paid DECIMAL(10,2) NOT NULL,
  Payment_Method VARCHAR(45) NOT NULL,
  Transaction_ID VARCHAR(45) NULL,
  FOREIGN KEY (Agreement_ID) REFERENCES Hire_Agreement (Agreement_ID),
  CHECK (Amount_Paid > 0)
) ENGINE=InnoDB;

CREATE TABLE `Uni_Vehicles` (
  `Vehicle_Regn` VARCHAR(15) NOT NULL,
  `Vehicle_Type` VARCHAR(45) NOT NULL,
  `Vehicle_Cap` SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (`Vehicle_Regn`),
  CHECK (Vehicle_Cap > 0)
) ENGINE=InnoDB;

CREATE TABLE `Trip_Vehicles` (
  `Regn` VARCHAR(15) NOT NULL,
  `Trip_Date` DATE NOT NULL,
  `Trip_Code` VARCHAR(45) NOT NULL,
  `Trip_Driver` INT NOT NULL,
  PRIMARY KEY (`Regn`, `Trip_Date`),
  INDEX `fk_Booking Vehicles_WES_Employees1_idx` (`Trip_Driver` ASC),
  INDEX `fk_Trip_Vehicles_Scheduled_Trips1_idx` (`Trip_Date` ASC, `Trip_Code` ASC),
  INDEX `fk_Trip_Vehicles_Uni_Vehicles1_idx` (`Regn` ASC),
  CONSTRAINT `fk_Booking Vehicles_WES_Employees1`
    FOREIGN KEY (`Trip_Driver`)
    REFERENCES `WES_Staff` (`staff_ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Trip_Vehicles_Scheduled_Trips1`
    FOREIGN KEY (`Trip_Date` , `Trip_Code`)
    REFERENCES `Scheduled_Trips` (`Trip_Date` , `Trip_Code`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Trip_Vehicles_Uni_Vehicles1`
    FOREIGN KEY (`Regn`)
    REFERENCES `Uni_Vehicles` (`Vehicle_Regn`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
) ENGINE=InnoDB;

CREATE TABLE `Qualifications` (
  `qual_ID` VARCHAR(45) NOT NULL,
  `qual_nm` VARCHAR(60) NOT NULL,
  `qual_desc` VARCHAR(80) NOT NULL,
  `qual_validity` INT NOT NULL,
  PRIMARY KEY (`qual_ID`),
  CHECK (qual_validity >= 0)
) ENGINE=InnoDB;

CREATE TABLE `Staff_Qualification` (
  `staff_ID` INT NOT NULL,
  `qual_ID` VARCHAR(45) NOT NULL,
  `date_acquired` DATE NOT NULL,
  `expiry_date` DATE NULL,
  `renewal_stat` VARCHAR(45) NULL,
  INDEX `fk_Staff Qualification_WES_Staff1_idx` (`staff_ID` ASC),
  PRIMARY KEY (`staff_ID`, `qual_ID`, `date_acquired`),
  INDEX `fk_Staff_Qualification_Qualifications1_idx` (`qual_ID` ASC),
  CONSTRAINT `fk_Staff Qualification_WES_Staff1`
    FOREIGN KEY (`staff_ID`)
    REFERENCES `WES_Staff` (`staff_ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Staff_Qualification_Qualifications1`
    FOREIGN KEY (`qual_ID`)
    REFERENCES `Qualifications` (`qual_ID`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CHECK (expiry_date IS NULL OR expiry_date >= date_acquired)
) ENGINE=InnoDB;

INSERT INTO Customer_Types VALUES ('Student'),('Staff'),('Alumni'),('Guest');
