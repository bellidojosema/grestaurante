-- Obtener el ranking de sucursales según sus ventas en el último mes disponible en la base de datos.
select s.nombre as sucursal, 
       date_format(p.fecha_pedido, '%Y-%m') as mes, 
       sum(p.total) as total_ventas, 
       rank() over (partition by date_format(p.fecha_pedido, '%Y-%m') order by sum(p.total) desc) as ranking
from pedidos p
join sucursales s on p.id_sucursal = s.id_sucursal
where p.fecha_pedido >= date_sub((select max(fecha_pedido) from pedidos), interval 1 month)
group by s.nombre, mes
order by mes desc, total_ventas desc;



-- Determinar qué producto ha sido el más vendido en cada sucursal.
with ventas_producto as (
    select s.nombre as sucursal, 
           pr.nombre as producto, 
           sum(dp.cantidad) as cantidad_vendida,
           rank() over (partition by s.nombre order by sum(dp.cantidad) desc) as ranking
    from detallepedidos dp
    join productos pr on dp.id_producto = pr.id_producto
    join pedidos p on dp.id_pedido = p.id_pedido
    join sucursales s on p.id_sucursal = s.id_sucursal
    group by s.nombre, pr.nombre
)
select sucursal, producto, cantidad_vendida
from ventas_producto
where ranking = 1;

-- Obtener un informe detallado de cada empleado 
with ventas_empleados as (
    select e.id_empleado,
           e.nombre as empleado,
           e.puesto,
           count(p.id_pedido) as total_pedidos,
           sum(p.total) as total_ventas,
           sum(p.total) * 0.10 as comision
    from empleados e
    left join pedidos p on e.id_empleado = p.id_empleado
    group by e.id_empleado, e.nombre, e.puesto
),
salario_empleados as (
    select n.id_empleado, 
           n.salario,
           AVG(n.salario) over (partition by e.puesto) as salario_promedio_puesto
    from nomina n
    join empleados e on n.id_empleado = e.id_empleado
)
select ve.empleado,
       ve.puesto,
       ve.total_pedidos,
       ve.total_ventas,
       se.salario,
       ve.comision,
       se.salario_promedio_puesto,
       (se.salario - se.salario_promedio_puesto) as diferencia_salarial,
       rank() over (order by ve.total_ventas desc) as ranking_ventas
from ventas_empleados ve
join salario_empleados se on ve.id_empleado = se.id_empleado
order by ranking_ventas;

--  Muestra un resumen de los pedidos pagados
SELECT 
    c.nombre AS nombre_cliente,
    pr.nombre AS nombre_producto,
    dp.cantidad AS cantidad_pedida,
    pg.metodo_pago,
    s.nombre AS nombre_sucursal
FROM 
    pedidos p
    INNER JOIN clientes c ON p.id_cliente = c.id_cliente
    INNER JOIN detallepedidos dp ON p.id_pedido = dp.id_pedido
    INNER JOIN productos pr ON dp.id_producto = pr.id_producto
    INNER JOIN pagos pg ON p.id_pedido = pg.id_pedido
    INNER JOIN sucursales s ON p.id_sucursal = s.id_sucursal
WHERE 
    p.id_sucursal = 1
ORDER BY 
    c.nombre, pr.nombre;

-- Obtener el total de ventas por sucursal en cada mes y calcular el crecimiento porcentual 
-- con respecto al mes anterior, sin usar LAG ni CASE
with ventas_mensuales as (
    select 
        s.nombre as sucursal, 
        date_format(p.fecha_pedido, '%Y-%m') as mes, 
        sum(p.total) as total_ventas
    from 
        pedidos p
        join sucursales s on p.id_sucursal = s.id_sucursal
    group by 
        s.nombre, mes
),
ventas_con_anterior as (
    select 
        vm1.sucursal,
        vm1.mes,
        vm1.total_ventas,
        vm2.total_ventas AS ventas_mes_anterior
    from 
        ventas_mensuales vm1
        left join ventas_mensuales vm2 
            on vm1.sucursal = vm2.sucursal 
            and vm2.mes = date_format(
                date_sub(STR_TO_DATE(concat(vm1.mes, '-01'), '%Y-%m-%d'), interval 1 month), 
                '%Y-%m'
            )
)
select 
    sucursal,
    mes,
    total_ventas,
    ventas_mes_anterior,
    ((total_ventas - ventas_mes_anterior) / nullif(ventas_mes_anterior, 0)) * 100 as crecimiento_porcentual
from 
    ventas_con_anterior
where 
    ventas_mes_anterior is not null
order by 
    sucursal, mes desc;

-- Vista 1: Muestra las ventas totales por sucursal en el último mes, con el mes y el total ordenado por fecha y ventas.
create view VentasMensuales as
select 
    s.nombre as sucursal,
    date_format(p.fecha_pedido, '%Y-%m') as mes,
    sum(p.total) as total_ventas
from 
    pedidos p
join 
    sucursales s on p.id_sucursal = s.id_sucursal
where 
    p.fecha_pedido >= date_sub((select max(fecha_pedido) from pedidos), interval 1 month)
group by
    s.nombre, mes
order by 
    mes desc, total_ventas desc;


-- Vista 2: Identifica el producto más vendido por sucursal según la cantidad, mostrando sucursal, producto y cantidad.
create view ProductoTop as
select 
    s.nombre as sucursal,
    pr.nombre as producto,
    SUM(dp.cantidad) as cantidad_vendida
from 
    detallepedidos dp
join 
    productos pr on dp.id_producto = pr.id_producto
join 
    pedidos p on dp.id_pedido = p.id_pedido
join 
    sucursales s on p.id_sucursal = s.id_sucursal
group by 
    s.nombre, pr.nombre
having 
    sum(dp.cantidad) = (
        select max(cantidad_vendida)
        from (
            select sum(dp2.cantidad) as cantidad_vendida
            from detallepedidos dp2
            join pedidos p2 on dp2.id_pedido = p2.id_pedido
            join sucursales s2 on p2.id_sucursal = s2.id_sucursal
            where s2.nombre = s.nombre
            group by s2.nombre, dp2.id_producto
        ) as sub
    );


-- Función 1: Calcula el total gastado por un cliente en un año específico
DELIMITER //

create function CalcularTotalGastadoCliente(idCliente int, anio int)
returns decimal(10,2)
deterministic
begin
    declare total decimal(10,2);
    select sum(total) into total
    from pedidos
    where id_cliente = idCliente and year(fecha_pedido) = anio;
    return ifnull(total, 0);
end //

DELIMITER ;


-- Función 2: Devuelve el stock actual de un producto dado su ID.
DELIMITER //

create function ObtenerStockProducto(idProducto int)
return int
deterministic
begin
    declare stockActual int;
    select stock INTO stockActual
    from productos
    where id_producto = idProducto;
    return ifnull(stockActual, 0);
end //

DELIMITER ;


-- Procedimiento 1: Actualiza el stock de un producto restando una cantidad dada.
DELIMITER //

create procedure ActualizarStockProducto(in idProducto int, in cantidadRestar int)
begin
    update productos
    set stock = stock - cantidadRestar
    where id_producto = idProducto and stock >= cantidadRestar;
    if ROW_COUNT() = 0 then
        signal sqlstate '45000'
        set MESSAGE_TEXT = 'Stock insuficiente o producto no encontrado';
    end if;
end //

DELIMITER ;


-- Procedimiento 2: Registra un nuevo pedido para un cliente, usando la función CalcularTotalGastadoCliente 
-- para verificar si el cliente ha gastado más de 1000 en el año (y aplicar un descuento si es así)
DELIMITER //

create procedure RegistrarPedidoCliente(
    in idCliente int, 
    in idSucursal int, 
    in idEmpleado int, 
    in totalPedido decimal(10,2), 
    in fecha date
)
begin
    declare totalGastado decimal(10,2);
    declare descuento decimal(10,2) default 0;
    
    set totalGastado = CalcularTotalGastadoCliente(idCliente, year(fecha));
    
    if totalGastado > 1000 then
        set descuento = totalPedido * 0.10;
        set totalPedido = totalPedido - descuento;
    end if;
    
    insert into pedidos (id_cliente, id_sucursal, id_empleado, fecha_pedido, total, estado, metodo_pago)
    values (id_Cliente, id_Sucursal, id_Empleado, fecha_pedido, total, 'Pendiente', 'Efectivo');
end //

DELIMITER ;


-- Procedimiento 3: Genera un reporte de ventas totales por sucursal en un mes y año específicos.
DELIMITER //

create procedure GenerarReporteVentasSucursal(in mes int, in anio int)
begin
    select 
        s.nombre as sucursal,
        SUM(p.total) as total_ventas
    from pedidos p
    join sucursales s on p.id_sucursal = s.id_sucursal
    where 
        month(p.fecha_pedido) = mes and year(p.fecha_pedido) = anio
    group by 
        s.nombre
    order by 
        total_ventas desc;
end //

DELIMITER ;


-- Trigger 1: Actualizar el stock de productos al insertar un detalle de pedido
DELIMITER //

create trigger actualizar_stock_despues_insertar_detalle
after insert on detallepedidos
for each row
begin
    update productos
    set stock = stock - new.cantidad
    where id_producto = new.id_producto;
END //

DELIMITER ;


-- Trigger 2: Actualizar las ventas mensuales al insertar un pago
DELIMITER //

create trigger actualizar_ventas_mensuales_despues_pago
after insert on pagos
for each row
begin
    declare mes_actual VARCHAR(7); 
    declare id_sucursal_pedido INT;

    set mes_actual = date_format(new.fecha_pago, '%Y-%m');

    select id_sucursal into id_sucursal_pedido
    from pedidos
    where id_pedido = NEW.id_pedido;

    if exists (
        select 1
        from ventasMensuales
        where id_sucursal = id_sucursal_pedido and mes = mes_actual
    ) then
        update ventasMensuales
        set total_ventas = total_ventas + new.monto
        where id_sucursal = id_sucursal_pedido and mes = mes_actual;
    else        
        insert into ventasMensuales (id_sucursal, mes, total_ventas)
        values (id_sucursal_pedido, mes_actual, new.monto);
    end if;
end //

DELIMITER ;
