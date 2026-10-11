-- Read-only examples for the revised schema.
USE wes_corrected;

-- Participants and waiver status for each scheduled trip.
SELECT t.Trip_Nm, r.Trip_Date, c.Cust_F_Nm, c.Cust_L_Nm, r.Ins_Waiv
FROM Trip_Reg AS r
JOIN Trips AS t ON t.Trip_Code = r.Trip_Code
JOIN Customers AS c ON c.Cust_ID = r.Cust_ID
ORDER BY r.Trip_Date, r.Trip_Code, c.Cust_L_Nm;

-- Equipment still out on hire, including overdue items.
SELECT h.Agreement_ID, h.Cust_ID, i.Equip_ID, t.Equip_Nm,
       i.Expected_Return, i.Expected_Return < CURRENT_DATE AS Is_Overdue
FROM Hire_Item AS i
JOIN Hire_Agreement AS h ON h.Agreement_ID = i.Agreement_ID
JOIN Equipments AS e ON e.Equip_ID = i.Equip_ID
JOIN Equipment_Type AS t ON t.Equip_Type_ID = e.Equip_Type_ID
WHERE i.Actual_ReturnDate IS NULL;

-- Credentials expiring in the next 30 days.
SELECT s.staff_ID, s.staff_f_name, s.staff_l_name, q.qual_nm, sq.expiry_date
FROM Staff_Qualification AS sq
JOIN WES_Staff AS s ON s.staff_ID = sq.staff_ID
JOIN Qualifications AS q ON q.qual_ID = sq.qual_ID
WHERE sq.expiry_date BETWEEN CURRENT_DATE AND DATE_ADD(CURRENT_DATE, INTERVAL 30 DAY);
