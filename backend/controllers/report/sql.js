export const SQL_GET_ORDERS_BY_MONTH = `
  SELECT p.fecha_finalizacion                                          AS fecha,
        c.nombre                                                      AS nombre_cliente,
        STRING_AGG(CONCAT(prod.nombre, ' (', dp.cantidad, ')'), ', ') AS productos,
        p.total,
        s.nombre                                                      AS estado,
        m.nombre                                                      AS metodo_envio
  FROM public.pedidos p
          JOIN public.clientes c ON p.cliente_id = c.cliente_id
          JOIN public.detalle_pedido dp ON p.pedido_id = dp.pedido_id
          JOIN public.productos prod ON dp.producto_id = prod.producto_id
          JOIN public.estados s ON p.estado_id = s.estado_id
          JOIN public.metodo_envio m ON p.metodo_id = m.metodo_id
  WHERE ($1::DATE IS NULL OR p.fecha_finalizacion >= $1::DATE)
    AND ($2::DATE IS NULL OR p.fecha_finalizacion <= $2::DATE)
    AND p.estado_id = 5
  GROUP BY p.pedido_id,
          c.nombre,
          p.fecha_finalizacion,
          p.total,
          s.nombre,
          m.nombre
  ORDER BY p.fecha_finalizacion
  OFFSET COALESCE($3, 0) LIMIT $4;
`;

export const SQL_GET_INCOME_BY_MONTH = `
  WITH ingresos_por_semana AS (SELECT CASE
                                          WHEN EXTRACT(DAY FROM fecha_finalizacion) BETWEEN 1 AND 7 THEN 'Día (1-7)'
                                          WHEN EXTRACT(DAY FROM fecha_finalizacion) BETWEEN 8 AND 14 THEN 'Día (8-14)'
                                          WHEN EXTRACT(DAY FROM fecha_finalizacion) BETWEEN 15 AND 21 THEN 'Día (15-21)'
                                          WHEN EXTRACT(DAY FROM fecha_finalizacion) >= 22 THEN 'Día (22-fin)'
                                          END                              AS semana,
                                      TO_CHAR(fecha_finalizacion, 'Month') AS mes,
                                      SUM(total)                           AS ingresos
                              FROM public.pedidos
                              WHERE estado_id = 5
                                AND fecha_finalizacion >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '2 months'
                              GROUP BY semana, mes),
      ingresos_totales AS (SELECT 'Total'                              AS semana,
                                  TO_CHAR(fecha_finalizacion, 'Month') AS mes,
                                  SUM(total)                           AS ingresos
                            FROM public.pedidos
                            WHERE estado_id = 5
                              AND fecha_finalizacion >= DATE_TRUNC('month', CURRENT_DATE) - INTERVAL '2 months'
                            GROUP BY mes)
  SELECT semana,
        COALESCE(SUM(CASE WHEN mes = TO_CHAR(CURRENT_DATE, 'Month') THEN ingresos END), 0)                       AS mes_actual,
        COALESCE(SUM(CASE WHEN mes = TO_CHAR(CURRENT_DATE - INTERVAL '1 month', 'Month') THEN ingresos END),
                  0)                                                                                              AS mes_pasado,
        COALESCE(SUM(CASE WHEN mes = TO_CHAR(CURRENT_DATE - INTERVAL '2 months', 'Month') THEN ingresos END),
                  0)                                                                                              AS mes_antepasado
  FROM (SELECT *
        FROM ingresos_por_semana
        UNION ALL
        SELECT *
        FROM ingresos_totales) ingresos
  GROUP BY semana
  ORDER BY CASE
              WHEN semana = 'Día (1-7)' THEN 1
              WHEN semana = 'Día (8-14)' THEN 2
              WHEN semana = 'Día (15-21)' THEN 3
              WHEN semana = 'Día (22-fin)' THEN 4
              WHEN semana = 'Total' THEN 5
              END;
`;

export const SQL_GET_PENDING_ORDERS = `
  SELECT p.fecha_estimada_entrega,
        c.nombre         AS nombre_cliente,
        e.nombre         AS estado,
        STRING_AGG(
                CONCAT(prod.nombre, ' (', dp.cantidad, ')'), ', '
        )                AS productos,
        SUM(dp.cantidad) AS cantidad_total_productos
  FROM public.pedidos p
          JOIN
      public.clientes c ON p.cliente_id = c.cliente_id
          JOIN
      public.detalle_pedido dp ON p.pedido_id = dp.pedido_id
          JOIN
      public.productos prod ON dp.producto_id = prod.producto_id
          JOIN public.estados e ON p.estado_id = e.estado_id
  WHERE ($1::DATE IS NULL OR p.fecha_finalizacion >= $1::DATE)
    AND ($2::DATE IS NULL OR p.fecha_finalizacion <= $2::DATE)
    AND e.estado_id IN (1, 2, 3)
  GROUP BY p.pedido_id, p.fecha_estimada_entrega, c.nombre, e.nombre
  ORDER BY p.fecha_estimada_entrega
  OFFSET COALESCE($3, 0) LIMIT $4;
`;

export const SQL_GET_REJECTED_ORDERS = `
  SELECT p.fecha_creacion     AS fecha_del_pedido,
        p.fecha_modificacion AS fecha_de_rechazo,
        c.nombre             AS cliente,
        STRING_AGG(
                CONCAT(prod.nombre, ' (', dp.cantidad, ')'), ', '
        )                    AS productos,
        SUM(dp.cantidad)     AS cantidad,
        p.notas
  FROM public.pedidos p
          JOIN
      public.clientes c ON p.cliente_id = c.cliente_id
          JOIN
      public.detalle_pedido dp ON p.pedido_id = dp.pedido_id
          JOIN
      public.productos prod ON dp.producto_id = prod.producto_id
          JOIN public.estados e ON e.estado_id = p.estado_id
  WHERE ($1::DATE IS NULL OR p.fecha_finalizacion >= $1::DATE)
    AND ($2::DATE IS NULL OR p.fecha_finalizacion <= $2::DATE)
    AND e.estado_id = 6
  GROUP BY p.pedido_id, p.fecha_creacion, p.fecha_modificacion, c.nombre, p.notas
  OFFSET COALESCE($3, 0) LIMIT $4;
`;

export const SQL_GET_ORDERS_OUT_OF_TIME = `
  SELECT p.fecha_estimada_entrega,
        c.nombre                                                                               AS cliente,
        STRING_AGG(CONCAT(pr.nombre, ' (', dp.cantidad, ')'), ', ')                            AS productos,
        SUM(dp.cantidad)                                                                       AS cantidad,
        e.nombre                                                                               AS estado,
        ROUND(EXTRACT(EPOCH FROM (p.fecha_finalizacion - p.fecha_estimada_entrega)) / 3600, 2) AS tiempo_retraso
  FROM pedidos p
          JOIN clientes c ON p.cliente_id = c.cliente_id
          JOIN detalle_pedido dp ON p.pedido_id = dp.pedido_id
          JOIN productos pr ON dp.producto_id = pr.producto_id
          JOIN estados e ON p.estado_id = e.estado_id
  WHERE ($1::DATE IS NULL OR p.fecha_finalizacion >= $1::DATE)
    AND ($2::DATE IS NULL OR p.fecha_finalizacion <= $2::DATE)
  GROUP BY p.pedido_id, p.fecha_estimada_entrega, c.nombre, e.nombre, p.fecha_finalizacion
  HAVING ROUND(EXTRACT(EPOCH FROM (p.fecha_finalizacion - p.fecha_estimada_entrega)) / 3600, 2) >= 1
  OFFSET COALESCE($3, 0) LIMIT $4
`;

export const SQL_GET_BEST_SELLING_PRODUCTS_HISTORY = `
  WITH ventas_totales AS (SELECT dp.producto_id,
                                SUM(dp.cantidad) AS total_vendido
                          FROM public.detalle_pedido dp
                                  JOIN
                              public.pedidos p ON dp.pedido_id = p.pedido_id
                                  JOIN public.estados e ON p.estado_id = e.estado_id
                          WHERE p.fecha_finalizacion IS NOT NULL
                            AND e.estado_id = 5
                            AND (
                              CASE
                                  WHEN $1::DATE IS NOT NULL AND $2::DATE IS NOT NULL THEN
                                      p.fecha_finalizacion BETWEEN $1::DATE AND $2::DATE
                                  WHEN $1::DATE IS NOT NULL THEN
                                      p.fecha_finalizacion >= $1::DATE
                                  WHEN $2::DATE IS NOT NULL THEN
                                      p.fecha_finalizacion <= $2::DATE
                                  ELSE TRUE
                                  END
                              )
                          GROUP BY dp.producto_id),
      total_general AS (SELECT COALESCE(SUM(total_vendido), 0) AS suma_total
                        FROM ventas_totales),
      productos_ordenados AS (SELECT p.nombre AS producto,
                                      vt.total_vendido,
                                      CASE
                                          WHEN (SELECT suma_total FROM total_general) > 0
                                              THEN vt.total_vendido * 100.0 / (SELECT suma_total FROM total_general)
                                          ELSE 0
                                          END  AS porcentaje
                              FROM ventas_totales vt
                                        JOIN
                                    public.productos p ON vt.producto_id = p.producto_id
                              ORDER BY vt.total_vendido DESC),
      top_productos AS (SELECT producto,
                                total_vendido,
                                porcentaje
                        FROM productos_ordenados
                        LIMIT 4),
      otros AS (SELECT 'Otros'                         AS producto,
                        COALESCE(SUM(total_vendido), 0) AS total_vendido,
                        COALESCE(SUM(porcentaje), 0)    AS porcentaje
                FROM productos_ordenados
                WHERE producto NOT IN (SELECT producto FROM top_productos)
                  AND (SELECT COUNT(*) FROM top_productos) > 0)
  SELECT producto,
        total_vendido,
        ROUND(porcentaje, 2) AS porcentaje
  FROM top_productos

  UNION ALL

  SELECT producto,
        total_vendido,
        ROUND(porcentaje, 2) AS porcentaje
  FROM otros
  WHERE (SELECT COUNT(*) FROM productos_ordenados) > 4;
`;

export const SQL_GET_INVENTORY = `
  SELECT
      p.nombre AS nombre_producto,
      v.sku,
      v.stock,
      v.precio_total,
      STRING_AGG(val.valor, ', ' ORDER BY esp.especificacion_id) AS especificaciones
  FROM
      public.variantes v
          JOIN public.productos p ON v.producto_id = p.producto_id
          JOIN public.variante_valores vv ON v.variante_id = vv.variante_id
          JOIN public.valor val ON vv.valor_id = val.valor_id
          JOIN public.especificacion esp ON val.especificacion_id = esp.especificacion_id
  WHERE
      v.stock > 0
  GROUP BY
      p.nombre, v.sku, v.stock, v.precio_total
  ORDER BY
      p.nombre, v.sku;
`;

export const SQL_GET_PRODUCTION_CAPACITY = `
  WITH pedidos_por_mes AS (SELECT DATE_TRUNC('month', fecha_finalizacion) AS mes,
                                  COUNT(*)                                AS pedidos_finalizados
                          FROM public.pedidos
                          WHERE estado_id = 5
                            AND ($1::DATE IS NULL OR fecha_finalizacion >= $1::DATE)
                            AND ($2::DATE IS NULL OR fecha_finalizacion <= $2::DATE)
                          GROUP BY DATE_TRUNC('month', fecha_finalizacion)),
      meses_ordenados AS (SELECT mes,
                                  pedidos_finalizados,
                                  LAG(pedidos_finalizados) OVER (ORDER BY mes) AS pedidos_mes_anterior
                          FROM pedidos_por_mes)
  SELECT DATE_TRUNC('month', mes)::timestamp AS mes,
        pedidos_finalizados                                                                     AS pedidos_mes_actual,
        pedidos_mes_anterior                                                                    AS pedidos_mes_anterior,
        ROUND(((pedidos_finalizados - pedidos_mes_anterior) * 100.0) / pedidos_mes_anterior, 2) AS porcentaje_variacion
  FROM meses_ordenados
  WHERE pedidos_mes_anterior IS NOT NULL
  ORDER BY mes;
`;
