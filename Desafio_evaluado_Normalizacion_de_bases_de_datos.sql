--desafio_evaluado_2

--01 Crear base de datos desafio_2
create database desafio_normalizacion;

--02 Entrar a la base de datos creada
\c desafio_normalizacion

--03 eliminamos la tabla si existe
drop table if exists inventario;

--04 creamos la tabla inventario para importar el archivo
create table inventario(
codigo_producto float
, producto varchar(255)
, locales varchar(255)
, precio float
, existencia varchar(255)
, stock int
, ubicacion varchar(255)
, numero_bodega int
, vendedor varchar(255)
, rut_vendedor int
, numero_boleta int
, cantidad_vendida int
, rut_cliente int
, nombre_cliente varchar (255)
)
;

--05 revisamos la tabla creada
select * from inventario;

--06 Incorporamos el archivo CSV en la tabla 'inventario'
\COPY inventario 
FROM 'C:/Users/barbie/Desktop/Desafio Latam/4.- SQL para Data Science/2.- Modelamiento y normalizacion\Clases dia 2\sesion experimental 2\Apoyo desafio.csv' 
DELIMITER ',' CSV HEADER QUOTE '"'ENCODING 'latin1';

--\COPY inventario FROM 'C:/Users/barbie/Desktop/Desafio Latam/4.- SQL para Data Science/2.- Modelamiento y normalizacion\Clases dia 2\sesion experimental 2\Apoyo desafio.csv' DELIMITER ',' CSV HEADER QUOTE '"'ENCODING 'latin1';

--07 Revisamos la tabla creada con sus datos
select * from inventario;

/*
 Se establecen a priori las siguientes entidades y relaciones:
    entidad inventario => codigo_producto, existencia 
    entidad producto => codigo_producto, producto, precio
    entidad locales => local_id, local, ubicacion, numero bodega
    relacion producto_local => producto_id, local_id, stock
    entidad vendedor => rut_vendedor, vendedor
    entidad boleta (relacion producto - vendedor - cliente) => boleta_id, codigo_producto, vendedor_id, cliente_id, cantidad_vendida
    entidad_cliente => rut_cliente, nombre_cliente
*/

/*
Se revisa la tabla y a priori se determina que NO se encuentra en 1FN, 
pues no tiene clave primaria y no puede ser la fecha (primera forma normal) 
pues la columna 'vendedor' pareciera contenter datos no atomicos en las filas 1, 2, 4 y 5.

Se determina que la llave primaria es la columna codigo producto, sin embargo tanto en
una segunda revisión nos percatamos que la columna rut_vendedor contiene datos atómicos, es deicr,
no se pueden subdividir,(un solo rut) por lo que no es posible desagregar la columna vendedor al no 
poder asignar un unico rut a dos vendedores distintos.
Por lo expueso, se decide tratar la columna vendedor como atómica.

En base a lo expuesto se construye la tabla 'boleta', y define numero_boleta como su llave primaria.
*/

--08 eliminamos la tabla 'boleta' en caso de existir
drop table if exists boleta;

--09 modificar el nombre de la tabla
alter table inventario
rename to boleta;

--10 agregamos clave primaria
alter table boleta
add PRIMARY KEY(numero_boleta);

--11 Revisamos la tabla con los cambios realizados
SELECT * FROM boleta;

/*
 * 2da forma normal
Se revisan que atributos dependen de la clave primaria,
y se determina que son las siguientes:

locales
ubicacion
codigo_producto
producto
cantidad_vendida
precio
vendedor
rut_vendedor
rut_cliente
nombre_cliente

Por lo expuesto los demás atributos se trasladar a entidades y relaciones separadas:
 
bodega => numero_bodega (PK) local (FK)
producto_bodega => codigo_producto (FK-PK), numero_bodega (FK-PK), stock
Nos percatamos que para crear la entidad bodega y la relación producto bodega, necesitaremos previamente crear las entidades Local v producto:

locales => local (PK), ubicacion
producto => codigo_producto (PK), producto, existencia

Eliminaremos las columnas redundantes y crearemos las llaves foráneas respectivas 
 
 */

--Creamos las entidades y relaciones
--Creamos la entidad locales 

--12--eliminamos la tabla locales en caso de existir
drop table if exists locales;

--13 crear tabla locales con su clave primaria
CREATE TABLE locales(
	locales varchar (255) PRIMARY KEY, 
	ubicacion varchar(255)
);

--14 Poblamos la tabla 
insert into locales
select distinct locales, ubicacion
from boleta ;

--15 Revisamos la tabla locales
select * from locales;


--16 Eliminamos la tabla producto en cosa de existir
drop table if exists producto;

--17 Creamos la entidad producto 
create table producto(
	codigo_producto int PRIMARY KEY
	, producto varchar(255)
	, existencia boolean
);

--18 Poblamos la tabla
/*
la poblamos con los datos desde boleta y transformando el valor de existencia a boolenado mediante un case
*/
insert into producto
(codigo_producto, producto, existencia)
select distinct codigo_producto, producto, (
	case existencia
		when 'TRUE' then true
		when 'Si' then true
		when '1' then true
		when 'FALSE' then false
		when 'No' then false
		when '0' then false
	end
)
from boleta;

--19 Revisamos la tabla creada
select * from producto;

--20 Eliminamos la tabla bodega en caso de existir
drop table if exists bodega;

--21 Creamos entidad bodega
CREATE TABLE bodega (
	numero_bodega int PRIMARY KEY
	, locales varchar(255) REFERENCES locales(locales)
);

--22 Insertamos datos a la tabla
insert into bodega
select distinct numero_bodega, locales
from boleta;

--23 Revisamos la tabla bodega
select * from bodega;


--24 Eliminamos la entidad producto_bodega en caso de existir 
drop table if exists producto_bodega;

--25 creamos la entidad producto_bodega
CREATE TABLE producto_bodega (
	codigo_producto int REFERENCES producto(codigo_producto)
	, numero_bodega int REFERENCES bodega(numero_bodega)
	, stock int
);

--26 Poblamos la tabla
insert into producto_bodega
select distinct codigo_producto, numero_bodega, stock
from boleta;

--27 Revisamos los cambios realizados en la tabla producto_bodega
select * from producto_bodega;


--
/*
 Modificamos la tabla boleta eliminando las columnas redundantes
 y creado las llaves foraneas
 */
--

--28 Eliminamos las columnas redundantes de la tabla boleta
alter table boleta
	drop column ubicacion
	, drop column producto
	, drop column existencia
	, drop column numero_bodega
	, drop column stock
; 

--29 Agregamos las llaves foraneas en la tabla boleta*
alter table boleta
	add foreign key (locales) references locales(locales),
    add foreign key (codigo_producto) references producto(codigo_producto)
;

--30 Revisamos
select * from boleta;

--
--
/*
Aplicando tercera forma normal (3FN) revisan que atributos tienen dependencia parcial
transitiva, y se determina que son las siguientes:

vendedor => depende transitivamente de rut_vendedor 
nombre_cliente => depende transitivamente de rut_cliente

Dicho lo anterior los atributos se trasladarán a otras entidades, a saber:

vendedor => rut_vendedor (PK), vendedor 
cliente => rut_cliente (PK), cliente

Eliminaremos las columnas redundantes y crearemos las llaves foráneas respectivas

 */
--

-- CREAMOS ENTIDADES

--31 Eliminamos la tabla vendedor en caso de que exista
drop table if exists vendedor;

--32 creamos la entidad vendedor
CREATE TABLE vendedor (
	rut_vendedor int PRIMARY KEY,
	vendedor varchar(255)
);

--33 Poblamos 
insert into vendedor
select distinct rut_vendedor, vendedor
from boleta ;

--34 Revisamos
select * from vendedor;


--35 eliminamos la tabla cliente en caso de que exista
drop table if exists cliente;
--36 Creamos la entidad cliente
CREATE TABLE cliente (
	rut_cliente int PRIMARY KEY,
	nombre_cliente varchar(255)
);

--37 Poblamos la tabla
insert into cliente
select distinct rut_cliente, nombre_cliente
from boleta;

--38 Revisamos los cambios
select * from cliente;

--39 Eliminamos las columnas redundantes de la tabla boleta 
alter table boleta
	drop column vendedor
	, drop column nombre_cliente
;

--Modificamos la tabla boleta para usar las foreign keys
--40 Productos
alter table boleta
	ADD	 FOREIGN KEY (rut_vendedor) REFERENCES vendedor(rut_vendedor)
	, ADD FOREIGN KEY (rut_cliente) REFERENCES cliente(rut_cliente)
;

--41 Revisamos
select * from boleta;

--Finalmente reordenamos las columnas--

--42 Eliminamos la tabla en caso de existir
drop table if exists tmp_boleta;

--43 Creamos una tabla boleta temporal ordenada
CREATE TABLE tmp_boleta as (
	select numero_boleta
		, locales
		, codigo_producto
		, cantidad_vendida
		, precio
		, rut_vendedor
		, rut_cliente
	from boleta
);

--44 Revisamos
select * from tmp_boleta;

--45 Eliminamos la tabla boleta original
drop table boleta;

--46 renombramos la tabla boleta temporal por la original
alter table tmp_boleta
rename to boleta;

--47 Revisamos los cambios realizados
select * from boleta;
