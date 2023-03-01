-- admin: list_all_admins
create or replace function list_all_admins(a_id int)
returns table
(
   r_staff_id int,
   r_full_name varchar(50),
   r_phone varchar(10),
   r_email varchar(50),
   r_password varchar(50),
   r_address varchar(100)
)
as
$$
begin

	if (
		select s.staff_role 
		from staff s 
		join users u on s.user_id = u.user_id 
		where u.user_id = a_id
	) != 2 then 
		raise exception 'Permission denied.';
	end if;
	
	-- table alias is mandatory, or use tablename as alias
	RETURN QUERY
	select 	
		u.user_id,
		cast(concat_ws(' ', u.first_name, u.last_name) as varchar(50)),
		u.phone_number,
		u.email,
		u."password",
		cast(concat_ws(' ', u.house_number, u.street, u.district, u.city) as varchar(100))
	from users u 
	join staff s on s.user_id = u.user_id 
	where s.staff_role = 2;
	
end;
$$
Language plpgsql;

-- general: sign_in 
create or replace function sign_in(
	u_email varchar(50),
	u_password varchar(50)
)
returns int
as
$$
DECLARE
   	email_check varchar(50);  
    password_check varchar(50);
   	id int;
begin
	select u.email from users u where u.email = u_email into email_check;
	select u."password" from users u where u."password" = u_password into password_check;
	select u.user_id from users u where u.email = u_email and u."password" = u_password into id;
	if email_check is null then
		raise notice 'email not exist.';
		return -1;
	elsif password_check is null then
		raise notice 'wrong password.';
		return -1;
	else
		raise notice 'succeed!';
		return id;
	end if;
end;
$$
Language plpgsql;

-- general: create_new_user
create or replace function register_new_user(
	new_fname varchar(20), 
	new_lname varchar(20),
	new_phone varchar(10),
	new_email varchar(50),
	new_password varchar(50),
	new_house_no varchar(10),
	new_street varchar(20),
	new_district varchar(20),
	new_city varchar(20),
	new_role int
)
returns int
as
$$
declare returned_id int;
begin
	INSERT INTO users (first_name, last_name, phone_number, email, password, house_number, street, district, city, user_role) 
	VALUES (new_fname, new_lname, new_phone, new_email, new_password, new_house_no, new_street, new_district, new_city, new_role)
	returning user_id into returned_id;
	raise notice '%', returned_id;
	return returned_id;
end;
$$
Language plpgsql;

-- admin: get_user_by_id
create or replace function get_user_by_id(a_id int, u_id int)
returns table
(
   r_full_name varchar(50),
   r_phone varchar(10),
   r_email varchar(50),
   r_password varchar(50),
   r_address varchar(100)
)
as
$$
begin

	if (
		select s.staff_role 
		from staff s 
		join users u on s.user_id = u.user_id 
		where u.user_id = a_id
	) != 2 then 
		raise exception 'Permission denied.';
	end if;
	
	-- table alias is mandatory, or use tablename as alias
	RETURN QUERY
	select 	
		concat_ws(' ', u.first_name, u.last_name),
		u.phone_number,
		u.email,
		u."password",
		concat_ws(' ', u.house_number, u.street, u.district, u.city)
	from users u 
	where u.user_id = u_id;
	
end;
$$
Language plpgsql;

-- admin: create_new_staff
create or replace function create_new_staff(
	a_id int,
	new_fname varchar(20), 
	new_lname varchar(20),
	new_phone varchar(10),
	new_email varchar(50),
	new_password varchar(50),
	new_house_no varchar(10),
	new_street varchar(20),
	new_district varchar(20),
	new_city varchar(20),
	new_rate int,
	new_role int
)
returns int
as
$$
DECLARE
   	u_id int;
    s_id int;
begin
	if (
		select s.staff_role 
		from staff s 
		join users u on s.user_id = u.user_id 
		where u.user_id = a_id
	) != 2 then 
		raise exception 'Permission denied.';
	end if;

	INSERT INTO users (first_name, last_name, phone_number, email, password, house_number, street, district, city, user_role) 
	VALUES (new_fname, new_lname, new_phone, new_email, new_password, new_house_no, new_street, new_district, new_city, 2)
	returning user_id into u_id;

	INSERT INTO staff (user_id, hourly_rate, staff_role) values (u_id, new_rate, new_role)
	returning staff_id into s_id;

	return u_id;
end;
$$
Language plpgsql;

-- staff: get_staff_by_id
drop function get_staff_by_id;
create or replace function get_staff_by_id(u_id int)
returns table
(
   r_staff_id int,
   r_full_name varchar(50),
   r_phone varchar(10),
   r_email varchar(50),
   r_password varchar(50),
   r_address varchar(100),
   r_rate int,
   r_role int
)
as
$$
begin
	if (select u.user_role from users u where u.user_id = u_id) != 2 then 
		raise exception 'Not id of a staff.';
	end if;

	-- table alias is mandatory, or use tablename as alias
	RETURN QUERY
	select 	
		s.staff_id,
		cast(concat_ws(' ', u.first_name, u.last_name) as varchar(50)),
		u.phone_number,
		u.email,
		u."password",
		cast(concat_ws(' ', u.house_number, u.street, u.district, u.city) as varchar(100)),
		s.hourly_rate,
		s.staff_role 
	from users u 
	join staff s on s.user_id = u.user_id 
	where u.user_id = u_id;
	
end;
$$
Language plpgsql;

-- admin: create_new_shift
create or replace function create_new_shift(
	a_id int,
	new_start_time time,
	new_end_time time,
	new_week_day int
)
returns int
as
$$
declare new_shift_id int;
begin

	if (
		select s.staff_role 
		from staff s 
		join users u on s.user_id = u.user_id 
		where u.user_id = a_id
	) != 2 then 
		raise exception 'Permission denied.';
	end if;

	insert into shifts (starting_time, ending_time, day_of_week)
	values (new_start_time, new_end_time, new_week_day)
	returning shift_id into new_shift_id;
	
	return new_shift_id;

end;
$$
Language plpgsql;

-- staff: get_shift_by_id
create or replace function get_shift_by_id(
	u_id int,
	in_shift_id int
)
returns table (
	out_start_time time,
	out_end_time time,
	out_week_day int
)
as
$$
declare new_shift_id int;
begin

	if (
		select u.user_role 
		from users u
		where u.user_id = u_id
	) != 2 then 
		raise exception 'Permission denied.';
	end if;

	return query 
	select 
		s.starting_time,
		s.ending_time,
		s.day_of_week 
	from shifts s 
	where s.shift_id = in_shift_id;

end;
$$
Language plpgsql;

-- staff: list_shifts
create or replace function list_shifts(
	u_id int
)
returns table (
	out_start_time time,
	out_end_time time,
	out_week_day int
)
as
$$
begin

	if (
		select u.user_role 
		from users u
		where u.user_id = u_id
	) != 2 then 
		raise exception 'Permission denied.';
	end if;

	return query 
	select 
		s.starting_time,
		s.ending_time,
		s.day_of_week 
	from shifts s;

end;
$$
Language plpgsql;

-- admin: create_new_session
create or replace function create_new_session(
	a_id int,
	in_staff_id int,
	in_shift_id int,
	in_date date
)
returns int
as
$$
declare out_session_id int;
begin

	if (
		select s.staff_role 
		from staff s 
		join users u on s.user_id = u.user_id 
		where u.user_id = a_id
	) != 2 then 
		raise exception 'Permission denied.';
	end if;

	insert into sessions (staff_id, shift_id, session_date)
	values (in_staff_id, in_shift_id, in_date)
	returning session_id into out_session_id;
	
	return out_session_id;

end;
$$
Language plpgsql;

-- staff: get_session_by_id
create or replace function get_session_by_id(
	u_id int,
	in_session_id int
)
returns table (
	out_name varchar(50),
	out_phone varchar(10),
	out_email varchar(20),
	out_password varchar(20),
	out_address varchar(100),
	out_rate int,
	out_staff_role int,
	out_start_time time,
	out_end_time time,
	out_week_day int,
	out_date date
)
as
$$
declare new_shift_id int;
begin

	if (
		select u.user_role 
		from users u
		where u.user_id = u_id
	) != 2 then 
		raise exception 'Permission denied.';
	end if;

	return query 
	select 
		cast(concat_ws(' ', u.first_name, u.last_name) as varchar(50)),
		u.phone_number,
		u.email,
		u."password",
		cast(concat_ws(', ', u.house_number, u.street, u.district, u.city) as varchar(100)),
		s3.hourly_rate,
		s3.staff_role,
		s2.starting_time,
		s2.ending_time,
		s2.day_of_week,
		s.session_date 
	from sessions s 
	join shifts s2 on s2.shift_id = s.shift_id 
	join staff s3 on s3.staff_id = s.staff_id 
	join users u on u.user_id = s3.user_id
	where s.session_id = in_session_id;

end;
$$
Language plpgsql;

-- admin: create_new_ingredient
create or replace function create_new_ingredient(
	a_id int,
	in_ing_name varchar(20),
	in_avail_quantity int,
	in_price_per_gram int
)
returns int
as
$$
declare out_ing_id int;
begin

	if (
		select s.staff_role 
		from staff s 
		join users u on s.user_id = u.user_id 
		where u.user_id = a_id
	) != 2 then 
		raise exception 'Permission denied.';
	end if;

	insert into ingredients (name, available_quantity, price_per_gram)
	values (in_ing_name, in_avail_quantity, in_price_per_gram)
	returning ing_id into out_ing_id;
	
	return out_ing_id;

end;
$$
Language plpgsql;

-- staff: get_ingredient_by_id
create or replace function get_ingredient_by_id(
	u_id int,
	in_ing_id int
)
returns table (
	out_name varchar(20),
	out_avail_quantity int,
	out_price_per_gram int
)
as
$$
declare new_shift_id int;
begin

	if (
		select u.user_role 
		from users u
		where u.user_id = u_id
	) != 2 then 
		raise exception 'Permission denied.';
	end if;

	return query 
	select 
		i."name",
		i.available_quantity,
		i.price_per_gram
	from ingredients i 
	where i.ing_id = in_ing_id;

end;
$$
Language plpgsql;

-- staff: list_ingredients
create or replace function list_ingredients(
	u_id int
)
returns table (
	out_name varchar(20),
	out_avail_quantity int,
	out_price_per_gram int
)
as
$$
declare new_shift_id int;
begin

	if (
		select u.user_role 
		from users u
		where u.user_id = u_id
	) != 2 then 
		raise exception 'Permission denied.';
	end if;

	return query 
	select 
		i."name",
		i.available_quantity,
		i.price_per_gram
	from ingredients i ;

end;
$$
Language plpgsql;

-- admin: create_new_item
create or replace function create_new_item(
	a_id int,
	in_item_name varchar(20),
	in_category varchar(20),
	in_item_size int,
	in_ing_ids int[],
	in_ing_quantity int[]
)
returns int
as
$$
declare out_item_id int;
begin

	if (
		select s.staff_role 
		from staff s 
		join users u on s.user_id = u.user_id 
		where u.user_id = a_id
	) != 2 then 
		raise exception 'Permission denied.';
	end if;

	insert into items (category, name, item_size) 
	values (in_category, in_item_name, in_item_size)
	returning item_id into out_item_id;

	FOR i IN 1..array_length(in_ing_ids, 1) 
	LOOP
        INSERT into item_detail (ingredient_id, item_id, ingredient_quantity)
        values (in_ing_ids[i], out_item_id, in_ing_quantity[i]);
    END LOOP;
	
	return out_item_id;

end;
$$
Language plpgsql;

-- staff: get_item_with_ings_by_item_id
create or replace function get_item_with_ings_by_item_id(
	u_id int,
	in_item_id int
)
returns table (
	out_item_name varchar(20),
	out_item_size int,
	out_item_price int,
	out_category varchar(20),
	out_ing_id int,
	out_ing_name varchar(20),
	out_ing_needed_amount int,
	out_ing_available_quantity int,
	out_price_per_gram int
)
as
$$
declare new_shift_id int;
begin

	if (
		select u.user_role 
		from users u
		where u.user_id = u_id
	) != 2 then 
		raise exception 'Permission denied.';
	end if;

	return query 
	select 
		i."name",
		i.item_size,
		i.item_price,
		i.category,
		i2.ing_id,
		i2."name",
		id.ingredient_quantity as needed_amount,
		i2.available_quantity,
		i2.price_per_gram 
	from items i 
	left join item_detail id on id.item_id = i.item_id 
	left join ingredients i2 on i2.ing_id = id.ingredient_id 
	where i.item_id = in_item_id;
	
end;
$$
Language plpgsql;

-- customers: create_new_customer
create or replace function create_new_customer(
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
DECLARE
   	out_cust_id int;
begin

	INSERT INTO users (first_name, last_name, phone_number, email, password, house_number, street, district, city) 
	VALUES (new_fname, new_lname, new_phone, new_email, new_password, new_house_no, new_street, new_district, new_city)
	returning user_id into out_cust_id;

	return out_cust_id;
end;
$$
Language plpgsql;

-- customers: get_customer_by_id
create or replace function get_customer_by_id(u_id int)
returns table
(
   r_full_name varchar(50),
   r_phone varchar(10),
   r_email varchar(50),
   r_password varchar(50),
   r_address varchar(100)
)
as
$$
begin
	if (select u.user_role from users u where u.user_id = u_id) != 1 then 
		raise exception 'Not an id of a customer.';
	end if;

	-- table alias is mandatory, or use tablename as alias
	RETURN QUERY
	select 	
		cast(concat_ws(' ', u.first_name, u.last_name) as varchar(50)),
		u.phone_number,
		u.email,
		u."password",
		cast(concat_ws(' ', u.house_number, u.street, u.district, u.city) as varchar(100))
	from users u 
	where u.user_id = u_id;
	
end;
$$
Language plpgsql;

-- customers: get_item_by_id_for_cust
create or replace function get_item_by_id_for_cust(
	u_id int,
	in_item_id int
)
returns table (
	item_name varchar(20),
	item_size int,
	item_price int,
	category varchar(20)
)
as
$$
declare new_shift_id int;
begin

	if (
		select u.user_role 
		from users u
		where u.user_id = u_id
	) != 1 then 
		raise exception 'Permission denied.';
	end if;

	return query 
	select 
		i."name",
		i.item_size,
		i.item_price * 2,
		i.category
	from items i 
	where i.item_id = in_item_id;
	
end;
$$
Language plpgsql;

-- customers: list_items_for_cust
create or replace function list_items_for_cust(
	u_id int
)
returns table (
	item_name varchar(20),
	item_size int,
	item_price int,
	category varchar(20)
)
as
$$
begin

	if (
		select u.user_role 
		from users u
		where u.user_id = u_id
	) != 1 then 
		raise exception 'Permission denied.';
	end if;

	return query 
	select 
		i."name",
		i.item_size,
		i.item_price * 2,
		i.category
	from items i ;
	
end;
$$
Language plpgsql;

-- customers: create_new_order
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
	if (
		select u.user_role 
		from users u
		where u.user_id = c_id
	) != 1 then 
		raise exception 'Permission denied.';
	end if;
	
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

-- customers: get_order_by_id
drop function get_order_by_id;
create or replace function get_order_by_id(
	in_u_id int,
	in_o_id int
)
returns table
(
	out_order_id int, 
	out_order_status int,
	out_created_date timestamp,
	out_address varchar(100),
	out_payment_method varchar(20),
	out_delivery_method varchar(20),
	out_item_id int,
	out_item_name varchar(20),
	out_item_size int,
	out_category varchar(20),
	out_item_quantity int,
	out_order_price int,
	out_total_order_price int
)
as
$$
begin
	-- table alias is mandatory, or use tablename as alias
	if (
		select u.user_role 
		from users u
		where u.user_id = in_u_id
	) != 1 then 
		raise exception 'Permission denied.';
	end if;

	RETURN QUERY
	select 	
		o.order_id, 
		o.order_status,
		o.created_date,
		cast(CONCAT_WS(', ', o.house_number, o.street, o.district, o.city) as varchar(100)) as address,
		o.payment_method,
		o.delivery_method,
		od.item_id,
		i."name",
		i.item_size,
		i.category,
		od.item_quantity,
		od.order_price,
		cast(t.total_order_price as int)
	from orders o
	left join order_detail od on od.order_id = o.order_id
	left join items i on i.item_id = od.item_id 
	JOIN (
		  SELECT order_id, SUM(order_price) as total_order_price
		  FROM order_detail 
		  GROUP BY order_id
	) t ON t.order_id = o.order_id
	where o.cust_id = in_u_id
	and o.order_id = in_o_id;
	
end;
$$
Language plpgsql;

-- staff: list_orders_by_session_id
drop function list_orders_by_session_id;
create or replace function list_orders_by_session_id(
	in_user_id int, 
	in_session_id int
) returns table (
	out_order_id int, 
	out_order_status int,
	out_created_date timestamp,
	out_address varchar(100),
	out_payment_method varchar(20),
	out_delivery_method varchar(20),
	out_item_id int,
	out_item_name varchar(20),
	out_item_size int,
	out_category varchar(20),
	out_item_quantity int,
	out_order_price int,
	out_total_order_price int
)
as
$$
begin
	if (
		select u.user_role 
		from users u
		where u.user_id = in_user_id
	) != 2 then 
		raise exception 'Permission denied.';
	end if;

	RETURN QUERY
	select 	
		o.order_id, 
		o.order_status,
		o.created_date,
		cast(CONCAT_WS(', ', o.house_number, o.street, o.district, o.city) as varchar(100)) as address,
		o.payment_method,
		o.delivery_method,
		od.item_id,
		i."name",
		i.item_size,
		i.category,
		od.item_quantity,
		od.order_price,
		cast(t.total_order_price as int)
	from orders o
	left join order_detail od on od.order_id = o.order_id
	left join items i on i.item_id = od.item_id 
	JOIN (
		  SELECT order_id, SUM(order_price) as total_order_price
		  FROM order_detail 
		  GROUP BY order_id
	) t ON t.order_id = o.order_id
	where o.session_id = in_session_id;
	
end;
$$
Language plpgsql;

-- staff: update_order_status_by_order_id
create or replace function update_order_status(
	u_id int, 
	o_id int, 
	c_id int,
	new_status int
)
returns boolean
as
$$
begin
	if (select u.user_role from users u where u.user_id = u_id) != 2 
	then 
		raise exception 'Permission denied!';
	end if;

	if (select o.order_status from orders o where o.cust_id = c_id) = 0
	then 
		raise exception 'Cannot update a cancelled order.';
	end if;

	update orders 
	set order_status = new_status
	where cust_id = c_id
	and order_id = o_id;

	return true;
end;
$$
language plpgsql;