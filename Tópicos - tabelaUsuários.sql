CREATE TABLE usuarios(
	user_id serial primary key,
	username varchar(255) NOT NULL,
	senha varchar(255) NOT NULL,
	email varchar(255) NOT NULL
);

drop table usuarios;