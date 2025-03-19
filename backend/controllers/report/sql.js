export const SQL_GET_ORDERS_BY_MONTH = `
    SELECT
        p.fecha_finalizacion as fecha,
        c.nombre AS nombre_cliente,
        STRING_AGG(
            CONCAT(prod.nombre, ' (', dp.cantidad, ')'), ', '
        ) AS productos,
        p.total,
        p.estado,
        p.metodo_envio
    FROM
        public.pedidos p
    JOIN
        public.clientes c ON p.id_cliente = c.id_cliente
    JOIN
        public.detallespedido dp ON p.id_pedido = dp.id_pedido
    JOIN
        public.productos prod ON dp.id_producto = prod.id_producto
    WHERE
        (
            ($1::date IS NULL OR p.fecha_finalizacion >= $1::date) AND
            ($2::date IS NULL OR p.fecha_finalizacion <= $2::date)
        ) AND
        p.estado = 'Entregado'
    GROUP BY
        p.id_pedido, c.nombre, p.fecha_finalizacion, p.total, p.estado, p.metodo_envio
    ORDER BY
        p.fecha_finalizacion ASC
    OFFSET COALESCE($3, 0) LIMIT $4;
    `;
