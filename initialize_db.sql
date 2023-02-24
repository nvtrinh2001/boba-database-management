create table users (
   user_id serial primary key,
   first_name varchar(20) not null,
   last_name varchar(20) not null,
   phone_number varchar(10) not null,
   email varchar(50) not null unique,
   password varchar(50) not null,
   house_number varchar(10) not null,
   street varchar(20) not null,
   district varchar(20) not null,
   city varchar(20) not null
);

create table staff (
   staff_id serial primary key,
   user_id int not null,
   hourly_rate int not null,
   staff_role int default 1 check (staff_role = 1 or staff_role = 2),
   unique (user_id, staff_role),
   constraint inherit_fk foreign key (user_id) references users(user_id)
);

create table orders (
   order_id serial primary key,
   order_status integer DEFAULT 1 check ((order_status >= 0) and (order_status <= 4)),
   payment_method varchar(20) not null,
   delivery_method varchar(20) not null,
   created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
   house_number varchar(10) not null,
   city varchar(20) not null,
   district varchar(20) not null,
   street varchar(20) not null,
   cust_id integer not null,
   session_id integer default 1,
   constraint customer_fk foreign key (cust_id) references users(user_id),
   constraint session_fk foreign key (session_id) references sessions(session_id)
);

create table items (
   item_id serial primary key,
   category varchar(20) not null,
   item_price integer default 0,
   name varchar(20) not null,
   item_size integer not null check ((item_size >= 0) and (item_size <= 3))
);

create table order_detail(
   order_id integer not null,
   item_id integer not null,
   item_quantity integer not null check (item_quantity > 0),
   order_price integer default 0,
   constraint order_fk foreign key (order_id) references orders(order_id),
   constraint item_fk foreign key (item_id) references items(item_id),
   constraint order_detail_pk primary key (order_id, item_id)
)

create table ingredients (
   ing_id serial primary key,   
   name varchar(20) not null,
   available_quantity integer not null check (available_quantity > 0),
   price_per_gram integer not null check (price_per_gram > 0)
);

create table item_detail(
   ingredient_id integer not null,
   item_id integer not null,
   ingredient_quantity integer not null check (ingredient_quantity > 0),
   constraint ingredient_fk foreign key (ingredient_id) references ingredients(ing_id),
   constraint item_fk foreign key (item_id) references items(item_id),
   constraint item_detail_pk primary key (ingredient_id, item_id)
)

drop table sessions cascade;
create table sessions (
   session_id serial primary key,
   staff_id integer not null,
   shift_id integer not null,
   session_date date not null,
   constraint shift_fk foreign key (shift_id) references shifts(shift_id),
   constraint staff_fk foreign key (staff_id) references staff(staff_id)
);

create table shifts(
   shift_id serial primary key,
   starting_time time not null,
   ending_time time not null, 
   day_of_week integer not null check ((day_of_week >= 2) and (day_of_week <= 8))
);


