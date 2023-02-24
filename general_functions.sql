-- get order information
-- can use by both users (with cust_id) and staff(with session_id)
create or replace function list_orders(
	cust_id int default null, 
	session_id int default null, 
	o_id int default null, 
	status int default null
)
returns table
(
	order_id int, 
	order_status int,
	created_date timestamp,
	address varchar(100),
	payment_method varchar(20),
	delivery_method varchar(20),
	item_id int,
	item_name varchar(20),
	item_size int,
	category varchar(20),
	item_quantity int,
	order_price int,
	total_order_price int
)
as
$$
begin
	-- table alias is mandatory, or use tablename as alias
	if cust_id is null and session_id is null then 
		raise exception 'cust_id and session_id cannot be null at the same time';
	end if;

	RETURN QUERY
	select 	
		o.order_id, 
		o.order_status,
		o.created_date,
		CONCAT_WS(', ', o.house_number, o.street, o.district, o.city) as address,
		o.payment_method,
		o.delivery_method,
		od.item_id,
		i."name",
		i.item_size,
		i.category,
		od.item_quantity,
		od.order_price,
		t.total_order_price
	from orders o
	left join order_detail od on od.order_id = o.order_id
	left join items i on i.item_id = od.item_id 
	JOIN (
		  SELECT order_id, SUM(order_price) as total_order_price
		  FROM order_detail 
		  GROUP BY order_id
	) t ON t.order_id = o.order_id
	where (cust_id is null or o.cust_id = cust_id)
	and (o_id is null or o.order_id = o_id)
	and (status is null or o.order_status = status);
	
end;
$$
Language plpgsql;

-- sign in 
create or replace function sign_in(
	u_email varchar(50),
	u_password varchar(50),
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

-- get staff information by id
create or replace function get_staff_info_by_staff_id(s_id int)
returns table
(
	u_id int,
	u_name varchar(50),
	u_phone varchar(10),
	u_email varchar(50),
	u_password varchar(50),
	u_address varchar(100),
	u_rate int,
	u_role int
)
as
$$
begin
	if (select u.user_role from users u where u.user_id = u_id) != 2 then
		raise exception 'Permission denied!';
	end if;
	
	-- table alias is mandatory, or use tablename as alias
	RETURN QUERY
	select 
		s.user_id,
		u.first_name || ' ' || u.last_name,
		u.phone_number,
		u.email,
		u."password",
		concat_ws(', ', u.house_number, u.street, u.district, u.city), 
		s.hourly_rate,
		s.staff_role 
	from staff s 
	join users u on u.user_id = s.user_id
	where s.staff_id = s_id;
	
end;
$$
Language plpgsql;

-- get user information by id
create or replace function get_user_info_by_id(u_id int)
returns table
(
   r_full_name varchar(50),
   r_phone varchar(10),
   r_email varchar(50),
   r_password varchar(50),
   r_address varchar(100),
)
as
$$
begin

	-- table alias is mandatory, or use tablename as alias
	RETURN QUERY
	select 	
		concat_ws(' ', u.first_name, u.last_name),
		u.phone_number,
		u.email,
		u."password",
		concat_ws(' ', u.house_number, u.street, u.district, u.city),
	from users u 
	where u.user_id = u_id;
	
end;
$$
Language plpgsql;

-- update user information by id
create or replace function update_user_info_by_id(
	u_id int,
	new_fname varchar(20) default null, 
	new_lname varchar(20) default null,
	new_phone varchar(10) default null,
	new_email varchar(50) default null,
	new_password varchar(50) default null,
	new_house_no varchar(10) default null,
	new_street varchar(20) default null,
	new_district varchar(20) default null,
	new_city varchar(20) default null
)
returns boolean
as
$$
begin

	if u_id is not null then
	
		if new_fname is not null then
			update users 
			set first_name = new_fname
			where user_id = u_id;
		end if;
	
		if new_lname is not null then
			update users 
			set last_name = new_lname
			where user_id = u_id;
		end if;
	
		if new_phone is not null then
			update users 
			set phone_number = new_phone
			where user_id = u_id;
		end if;
	
		if new_email is not null then
			update users 
			set email = new_email
			where user_id = u_id;
		end if;
	
		if new_password is not null then
			update users 
			set "password" = new_password
			where user_id = u_id;
		end if;
	
		if new_house_no is not null then
			update users 
			set house_number = new_house_no
			where user_id = u_id;
		end if;
	
		if new_street is not null then
			update users 
			set street = new_street
			where user_id = u_id;
		end if;
	
		if new_district is not null then
			update users 
			set district = new_district
			where user_id = u_id;
		end if;
	
		if new_city is not null then
			update users 
			set city = new_city
			where user_id = u_id;
		end if;

		return true;
	else
		raise notice 'Illegal user id!';
		return false;
	end if;

end;
$$
Language plpgsql;

-- delete user by id
create or replace function delete_user_by_id(u_id int)
returns boolean
as
$$
begin
	delete from users
	where user_id = u_id;
	return true;
end;
$$
language plpgsql;
