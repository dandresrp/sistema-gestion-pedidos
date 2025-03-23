export const SQL_GET_ORDERS_BY_MONTH = `
SELECT
  p.fecha_finalizacion as fecha,
  c.nombre AS nombre_cliente,
  STRING_AGG(CONCAT(prod.nombre, ' (', dp.cantidad, ')'), ', ') AS productos,
  p.total,
  p.estado,
  p.metodo_envio
FROM
  public.pedidos p
  JOIN public.clientes c ON p.id_cliente = c.id_cliente
  JOIN public.detallespedido dp ON p.id_pedido = dp.id_pedido
  JOIN public.productos prod ON dp.id_producto = prod.id_producto
WHERE
  ($1::date IS NULL OR p.fecha_finalizacion >= $1::date)
  AND ($2::date IS NULL OR p.fecha_finalizacion <= $2::date)
  AND p.estado = 'Entregado'
GROUP BY
  p.id_pedido,
  c.nombre,
  p.fecha_finalizacion,
  p.total,
  p.estado,
  p.metodo_envio
ORDER BY
  p.fecha_finalizacion ASC
OFFSET COALESCE($3, 0)
LIMIT $4;
`;

export const SQL_GET_INCOME_BY_MONTH = `
WITH ingresos_por_semana AS (
    SELECT
        CASE
            WHEN EXTRACT(DAY FROM fecha_finalizacion) BETWEEN 1 AND 7 THEN 'Día (1-7)'
            WHEN EXTRACT(DAY FROM fecha_finalizacion) BETWEEN 8 AND 14 THEN 'Día (8-14)'
            WHEN EXTRACT(DAY FROM fecha_finalizacion) BETWEEN 15 AND 21 THEN 'Día (15-21)'
            WHEN EXTRACT(DAY FROM fecha_finalizacion) >= 22 THEN 'Día (22-fin)'
        END AS semana,
        TO_CHAR(fecha_finalizacion, 'Month') AS mes,
        SUM(total) AS ingresos
    FROM
        public.pedidos
    WHERE
        estado = 'Entregado'
        AND fecha_finalizacion >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '2 months'
    GROUP BY
        semana, mes
),
ingresos_totales AS (
    SELECT
        'Total' AS semana,
        TO_CHAR(fecha_finalizacion, 'Month') AS mes,
        SUM(total) AS ingresos
    FROM
        public.pedidos
    WHERE
        estado = 'Entregado'
        AND fecha_finalizacion >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '2 months'
    GROUP BY
        mes
)
SELECT
    semana,
    COALESCE(SUM(CASE WHEN mes = TO_CHAR(CURRENT_DATE, 'Month') THEN ingresos END), 0) AS mes_actual,
    COALESCE(SUM(CASE WHEN mes = TO_CHAR(CURRENT_DATE - INTERVAL '1 month', 'Month') THEN ingresos END), 0) AS mes_pasado,
    COALESCE(SUM(CASE WHEN mes = TO_CHAR(CURRENT_DATE - INTERVAL '2 months', 'Month') THEN ingresos END), 0) AS mes_antepasado
FROM (
    SELECT * FROM ingresos_por_semana
    UNION ALL
    SELECT * FROM ingresos_totales
) ingresos
GROUP BY
    semana
ORDER BY
    CASE
        WHEN semana = 'Día (1-7)' THEN 1
        WHEN semana = 'Día (8-14)' THEN 2
        WHEN semana = 'Día (15-21)' THEN 3
        WHEN semana = 'Día (22-fin)' THEN 4
        WHEN semana = 'Total' THEN 5
    END
`;

export const SQL_GET_PENDING_ORDERS = `
  SELECT
    p.fecha_estimada_entrega,
    p.hora_estimada_entrega,
    c.nombre AS nombre_cliente,
    p.estado,
    STRING_AGG(
        CONCAT(prod.nombre, ' (', dp.cantidad, ')'), ', '
    ) AS productos,
    SUM(dp.cantidad) AS cantidad_total_productos
FROM
    public.pedidos p
JOIN
    public.clientes c ON p.id_cliente = c.id_cliente
JOIN
    public.detallespedido dp ON p.id_pedido = dp.id_pedido
JOIN
    public.productos prod ON dp.id_producto = prod.id_producto
WHERE
  ($1::date IS NULL OR p.fecha_finalizacion >= $1::date)
  AND ($2::date IS NULL OR p.fecha_finalizacion <= $2::date)
  AND p.estado IN ('Creado', 'En produccion', 'En espera')
GROUP BY
    p.id_pedido, p.fecha_estimada_entrega, p.hora_estimada_entrega, c.nombre, p.estado
ORDER BY
    p.fecha_estimada_entrega ASC,
    p.hora_estimada_entrega ASC
OFFSET COALESCE($3, 0)
LIMIT $4;
`;

export const SQL_GET_REJECTED_ORDERS = `
SELECT
    p.fecha_creacion as fecha_del_pedido,
    p.fecha_modificacion as fecha_de_rechazo,
    c.nombre AS cliente,
    STRING_AGG(
        CONCAT(prod.nombre, ' (', dp.cantidad, ')'), ', '
    ) AS productos,
    SUM(dp.cantidad) AS cantidad,
    p.notas
FROM
    public.pedidos p
JOIN
    public.clientes c ON p.id_cliente = c.id_cliente
JOIN
    public.detallespedido dp ON p.id_pedido = dp.id_pedido
JOIN
    public.productos prod ON dp.id_producto = prod.id_producto
WHERE
  ($1::date IS NULL OR p.fecha_finalizacion >= $1::date)
  AND ($2::date IS NULL OR p.fecha_finalizacion <= $2::date)
  AND p.estado = 'Rechazado'
GROUP BY
    p.id_pedido, p.fecha_creacion, p.fecha_modificacion, c.nombre, p.notas
OFFSET COALESCE($3, 0)
LIMIT $4
`;

export const SQL_GET_ORDERS_OUT_OF_TIME = `
  SELECT
    p.fecha_estimada_entrega,
    p.hora_estimada_entrega,
    c.nombre AS cliente,
    STRING_AGG(CONCAT(pr.nombre, ' (', dp.cantidad, ')'), ', ') AS productos,
    SUM(dp.cantidad) AS cantidad,
    p.estado,
    ROUND(EXTRACT(EPOCH FROM (p.fecha_finalizacion - (p.fecha_estimada_entrega + p.hora_estimada_entrega))) / 3600, 2) AS tiempo_retraso
FROM pedidos p
JOIN clientes c ON p.id_cliente = c.id_cliente
JOIN detallespedido dp ON p.id_pedido = dp.id_pedido
JOIN productos pr ON dp.id_producto = pr.id_producto
WHERE
  ($1::date IS NULL OR p.fecha_finalizacion >= $1::date)
  AND ($2::date IS NULL OR p.fecha_finalizacion <= $2::date)
GROUP BY p.id_pedido, p.fecha_estimada_entrega, p.hora_estimada_entrega, c.nombre, p.estado, p.fecha_finalizacion
HAVING ROUND(EXTRACT(EPOCH FROM (p.fecha_finalizacion - (p.fecha_estimada_entrega + p.hora_estimada_entrega))) / 3600, 2) >= 1
OFFSET COALESCE($3, 0)
LIMIT $4
`;

export const SQL_GET_BEST_SELLING_PRODUCTS_HISTORY = `
WITH ventas_totales AS (
    SELECT
        dp.id_producto,
        SUM(dp.cantidad) AS total_vendido
    FROM
        public.detallespedido dp
    JOIN
        public.pedidos p ON dp.id_pedido = p.id_pedido
    WHERE
        p.fecha_finalizacion IS NOT NULL
        AND p.estado = 'Entregado'
        AND (
            CASE
                WHEN $1::date IS NOT NULL AND $2::date IS NOT NULL THEN
                    p.fecha_finalizacion BETWEEN $1::date AND $2::date
                WHEN $1::date IS NOT NULL THEN
                    p.fecha_finalizacion >= $1::date
                WHEN $2::date IS NOT NULL THEN
                    p.fecha_finalizacion <= $2::date
                ELSE TRUE
            END
        )
    GROUP BY
        dp.id_producto
),
total_general AS (
    SELECT COALESCE(SUM(total_vendido), 0) as suma_total
    FROM ventas_totales
),
productos_ordenados AS (
    SELECT
        p.nombre AS producto,
        vt.total_vendido,
        CASE
            WHEN (SELECT suma_total FROM total_general) > 0
            THEN vt.total_vendido * 100.0 / (SELECT suma_total FROM total_general)
            ELSE 0
        END AS porcentaje
    FROM
        ventas_totales vt
    JOIN
        public.productos p ON vt.id_producto = p.id_producto
    ORDER BY
        vt.total_vendido DESC
),
top_productos AS (
    SELECT
        producto,
        total_vendido,
        porcentaje
    FROM
        productos_ordenados
    LIMIT 4
),
otros AS (
    SELECT
        'Otros' AS producto,
        COALESCE(SUM(total_vendido), 0) AS total_vendido,
        COALESCE(SUM(porcentaje), 0) AS porcentaje
    FROM
        productos_ordenados
    WHERE
        producto NOT IN (SELECT producto FROM top_productos)
        AND (SELECT COUNT(*) FROM top_productos) > 0
)
SELECT
    producto,
    total_vendido,
    ROUND(porcentaje, 2) AS porcentaje
FROM
    top_productos

UNION ALL

SELECT
    producto,
    total_vendido,
    ROUND(porcentaje, 2) AS porcentaje
FROM
    otros
WHERE
    (SELECT COUNT(*) FROM productos_ordenados) > 4
`;
