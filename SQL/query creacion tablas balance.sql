create database balance_aluminio_mike_bd
go
use balance_aluminio_mike_bd
go

create table aluminio(
	Id int primary key identity(1,1),
	Codigo varchar(50) not null unique,
	Descripcion varchar(200),
	PesoXMetro decimal(10,2),
	Observacion varchar(255),
	Estado bit default 1
)

create table tiposMovimiento(
	Id int primary key identity(1,1),
	Codigo varchar(50),
	Descripcion varchar(200),
	Estado bit default 1
)

create table depositos(
	Id int primary key identity(1,1),
	Codigo varchar(50),
	Descripcion varchar(200),
	Estado bit default 1
)

create table movimientos(
	Id bigint primary key identity(1,1),
	Fecha date not null,
	IdAluminio int not null foreign key references aluminio(Id),
	IdTipoMovimiento int not null foreign key references tiposMovimiento(Id),
	Cantidad decimal(10,2) not null,
	Desde int null foreign key references depositos(Id),
	Hacia int null foreign key references depositos(Id),
	Observaciones varchar(250),
	Estado bit not null default 1
)

create table stock_x_deposito(
	IdDeposito int foreign key references depositos(Id),
	IdAluminio int foreign key references aluminio(Id),
	Cantidad decimal(10,2) default 0
	primary key(IdDeposito, IdAluminio)
)






