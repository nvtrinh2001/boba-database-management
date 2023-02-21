-- get user information
create or replace function get_cust_info_by_id(cust_id int)
returns table
(
	full_name varchar(50),
	phone char(10)
)
as
$$
begin
	-- table alias is mandatory, or use tablename as alias
	RETURN QUERY
	select 	
		concat_ws(' ', c.first_name, c.last_name),
		c.phone 
	from customers c
	where c.cust_id = cust_id;
	
end;
$$
Language plpgsql;

-- get item information
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