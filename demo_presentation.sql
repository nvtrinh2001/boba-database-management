select list_all_admins(61);

select create_new_staff(
	61,
	'Trinh1', 
	'Nguyen1',
	'0123456789',
	'nguyenvantrinh102@gmail.com',
	'123password',
	'23',
	'Tan Lac',
	'Hai Ba Trung',
	'Ha Noi',
	20000,
	1
);
select get_staff_by_id(73);
select list_shifts(61);
select create_new_session(61, 17, 10, current_date);
select get_session_by_id(61, 101);
select create_new_ingredient(61, 'eggs', 100, 2000);
select get_ingredient_by_id(61, 31);
select list_ingredients(61);
select create_new_item(61, 'Creamy Tea', 'Milk Tea', 2, array[1,31], array[4,7]);
select get_item_with_ings_by_item_id(61, 102);

select create_new_customer(
	'Trinh2', 
	'Nguyen2',
	'0123456788',
	'nguyenvantrinh03@gmail.com',
	'123password',
	'23',
	'Tan Lac',
	'Hai Ba Trung',
	'Ha Noi'
);
select get_customer_by_id(72);
select get_item_by_id_for_cust(72, 106);
select list_items_for_cust(72);
select list_orders_by_session_id(71, 102);
select create_order(
	72, 
	'Banking',
	'Shopee',
	'23',
	'Tan Lac',
	'Hai Ba Trung',
	'Ha Noi',
	array[106, 3, 5, 7],
	array[1, 4, 2, 4]
);
select get_order_by_id(72, 54);
select list_orders_by_session_id(61, 102);
select update_order_status(71, 52, 72, 2);
select get_item_with_ings_by_item_id(61, 106);
