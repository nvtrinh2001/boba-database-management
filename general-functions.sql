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