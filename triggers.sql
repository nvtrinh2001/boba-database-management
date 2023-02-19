-- trigger to update session_id of an order when new order is created
create or replace TRIGGER orders_session_id
AFTER insert ON orders
FOR EACH row
EXECUTE PROCEDURE update_orders_session_id();

CREATE OR REPLACE FUNCTION update_orders_session_id()  
RETURNS trigger 
AS 
$BODY$ 
declare ws_id int;
BEGIN    
	SELECT s.session_id 
    FROM sessions s
    JOIN shifts sh ON sh.shift_id = s.shift_id 
    WHERE s.session_date = new.created_date::date
    AND new.created_date::time < sh.ending_time
    AND new.created_date::time >= sh.starting_time 
    INTO ws_id;
    
    IF ws_id IS NOT NULL THEN
        RAISE NOTICE 'Updating created_date %: get ws_id %',
        NEW.created_date, ws_id;
        UPDATE orders
        SET session_id = ws_id
        WHERE order_id = new.order_id;     
    elsif ws_id is null then
		RAISE NOTICE 'ws_id is null. Cancel the order.';
		UPDATE orders
        SET order_status = 0
        WHERE order_id = new.order_id;    
    END IF;
   	return new;
end;     
$BODY$  
LANGUAGE plpgsql;

-- trigger to update order_price of order_detail table when new row is created
create or replace trigger order_detail_order_price
after insert on order_detail 
for each row 
execute procedure  update_order_detail_price();

CREATE OR REPLACE FUNCTION update_order_detail_price()  
RETURNS trigger 
AS 
$BODY$ 
declare price int;
BEGIN    
	select i.item_price * new.item_quantity * 2
	from items i where i.item_id = new.item_id
	into price;
	UPDATE order_detail
	SET order_price = price
	WHERE order_id = new.order_id
	and item_id = new.item_id;     
	Return new; 
end;     
$BODY$  
LANGUAGE plpgsql VOLATILE COST 100;

-- trigger to update item_price of items table when new row of item_detail is created
create or replace trigger items_item_price
after insert or update on item_detail
for each row 
execute procedure  update_item_price();

CREATE OR REPLACE FUNCTION update_item_price()
RETURNS TRIGGER AS $$
DECLARE
  price int;
  result_price int;
BEGIN 
  select i.item_price + ing.price_per_gram * new.ingredient_quantity 
  from items i 
  join ingredients ing on ing.ing_id = new.ingredient_id
  where i.item_id = new.item_id
  into price;

  UPDATE items 
  SET item_price = price
  WHERE item_id = NEW.item_id;
 
  select item_price from items i into result_price;
  
  RAISE NOTICE 'Updating item_price for item_id %: +%',
  NEW.item_id, result_price;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- trigger to update avail_amount of ingredients table when new order is created
create or replace trigger ing_avai_amount
after update on orders
for each row 
execute procedure avail_amount_calculate();

CREATE OR REPLACE FUNCTION avail_amount_calculate()  
RETURNS trigger 
AS 
$BODY$ 
DECLARE
    item record;
    ingredient record;
    total_ingredients int;
    id int;
begin
	if new.order_status = 2 then
		FOR item IN 
			SELECT * FROM order_detail od WHERE od.order_id = NEW.order_id
		LOOP
        -- loop through all ingredients used in the item
	        FOR ingredient IN 
	        	SELECT * FROM item_detail id WHERE id.item_id = item.item_id
	        loop
		        select ingredient.ingredient_quantity * item.item_quantity into total_ingredients;
		        select ingredient.ingredient_id into id;
	            -- update the available amount of the ingredient by subtracting the quantity used in the item
	            UPDATE ingredients
	            SET available_quantity = available_quantity - total_ingredients
	            WHERE ing_id = id;
	        END LOOP;
    	END LOOP;
	end if;
	return new;
end;     
$BODY$  
LANGUAGE plpgsql VOLATILE COST 100;
