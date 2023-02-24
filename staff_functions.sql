-- get work related information
create or replace function get_sessions(
	staff_id int, 
	s_id int default null,
	session_date date default null, 
	day_of_week int default null
) returns table
(
	start_time time,
	end_time time,
	weekday int,
	work_date date
)
as
$$
begin	
	-- table alias is mandatory, or use tablename as alias
	RETURN QUERY
	select 
		s2.starting_time,
		s2.ending_time,
		s2.day_of_week,
		s.session_date 
	from sessions s
	join shifts s2 on s2.shift_id = s.shift_id 
	where s.staff_id = staff_id
	and (session_date is null or s.session_date = session_date)
	and (day_of_week is null or s2.day_of_week = day_of_week)
	and (s_id is null or s.session_id = s_id);
	
end;
$$
Language plpgsql;

-- get item ingredients
create or replace function list_ingredients(
	u_id int,
	i_id int default null, 
	i_name varchar(20) default null,
	i_category varchar(20) default null
) 
returns table
(
	item_id,
	item_name,
	item_size,
	item_category,
	ing_quantity,
	ing_id,
	ing_name,
	ing_available_quantity 
)
as
$$
begin
	if (select u.user_role from users u where u.user_id = u_id) != 2
	then 
		raise exception 'Permission denied!';
	end if;
	-- table alias is mandatory, or use tablename as alias
	RETURN QUERY
	select 
		i.item_id,
		i."name",
		i.item_size,
		i.category,
		id.ingredient_quantity,
		ing.ing_id,
		ing."name",
		ing.available_quantity 
	from items i
	join item_detail id on id.item_id = i.item_id 
	join ingredients ing on ing.ing_id = id.ingredient_id 
	where (i_id is null or i.item_id = i_id)
	and (i_name is null or i."name" = i_name)
	and (i_category is null or i.category = i_category);
	
end;
$$
Language plpgsql;

-- update order status
create or replace function update_order_status(
	u_id int, 
	o_id int, 
	c_id int,
	new_status int
)
as
$$
begin
	if (select u.user_role from users u where u.user_id = u_id) != 2 
	then 
		raise exception 'Permission denied!';
	end if;

	update orders 
	set order_status = new_status
	where cust_id = c_id
	and order_id = o_id;

end;
$$
language plpgsql;