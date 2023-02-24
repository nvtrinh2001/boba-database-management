-- register for new users
create or replace function register_new_user(
	new_fname varchar(20), 
	new_lname varchar(20),
	new_phone varchar(10),
	new_email varchar(50),
	new_password varchar(50),
	new_house_no varchar(10),
	new_street varchar(20),
	new_district varchar(20),
	new_city varchar(20)
)
returns int
as
$$
begin
	INSERT INTO users (first_name, last_name, phone_number, email, password, house_number, street, district, city) 
	VALUES (new_fname, new_lname, new_phone, new_email, new_password, new_house_no, new_street, new_district, new_city);
	return (select u.user_id from users u where u.email = new_email);
end;
$$
Language plpgsql;

-- list items for customers
create or replace function list_items(
	i_id int default null;
	category varchar(20) default null, 
	price_from int default null, 
	price_to int default null,
	name varchar(20) default null,
	size int default null
)
returns table
(
	item_id int,
	item_name varchar(20),
	item_size int,
	item_category varchar(20),
	final_item_price int
)
as
$$
begin
	-- table alias is mandatory, or use tablename as alias
	return query
	select 
		i.item_id,
		i."name",
		i.item_size,
		i.category,
		i.item_price * 2 as final_item_price
	from items i 
	where (category is null or i.category = category)
	and   (price_from is null or i.item_price >= price_from)
	and   (price_to is null or i.item_price <= price_to)
	and   (name is null or i."name" = item_name)
	and   (size is null or i.item_size = item_size)
	and   (i_id is null or i.item_id = i_id);
	
end;
$$
Language plpgsql;

-- cancel orders from customers
create or replace function cancel_order(
	c_id int, 
	o_id int
) returns boolean
as
$$
begin
	if (select o.order_status from orders o where o.order_id = o_id and o.cust_id = c_id) > 1 then 
		raise notice 'Cannot cancel as the order is already being prepared!';
		return false;
	end if;

	update orders 
	set order_status = 0
	where cust_id = c_id
	and order_id = o_id;
	
	return true;
end;
$$
Language plpgsql;

-- create order
create or replace function create_order(
	c_id int, 
	payment varchar(20), 
	delivery varchar(20), 
	house_no varchar(10), 
	new_city varchar(20), 
	new_district varchar(20), 
	new_street varchar(20),
	item_ids int[],
	item_quans int[]
) returns int
as
$$
DECLARE
    v_order_id integer;
   	item int;
begin
	INSERT INTO orders (payment_method, delivery_method, house_number, city, district, street, cust_id)
	values (payment, delivery, house_no, new_city, new_district, new_street, c_id)
	RETURNING order_id INTO v_order_id;
	
	-- Insert each item from the list into the order_detail table
	FOR i IN 1..array_length(item_ids, 1) 
	LOOP
        INSERT INTO order_detail (order_id, item_id, item_quantity)
        values (v_order_id, item_ids[i], item_quans[i]);
    END LOOP;
   
   	-- Return the ID of the new order
    RETURN v_order_id;
end;
$$
Language plpgsql;
