ALTER TABLE customer
ADD COLUMN platinum_member BOOLEAN DEFAULT FALSE;

CREATE FUNCTION CalculateLateFee(rental_id INT) RETURNS DECIMAL(10,2)
BEGIN
    RETURN (SELECT IF(DATEDIFF(return_date, rental_date + INTERVAL rental_duration DAY) > 0, DATEDIFF(return_date, rental_date + INTERVAL rental_duration DAY) * 1.50, 0) 
            FROM rental 
            WHERE rental.rental_id = rental_id);
END;

-- update 'platinum_member' status
CREATE PROCEDURE UpdatePlatinumStatusAndLateFees()
BEGIN
    UPDATE customer
    SET platinum_member = (SELECT SUM(payment.amount) > 200 FROM payment WHERE payment.customer_id = customer.customer_id);

    UPDATE payment p
    JOIN rental r ON p.rental_id = r.rental_id
    SET p.amount = p.amount + CalculateLateFee(p.rental_id)
    WHERE r.return_date > r.rental_date + INTERVAL r.rental_duration DAY;
END;
