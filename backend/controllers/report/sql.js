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
  WITH weekly_income AS (
    SELECT
      DATE_TRUNC('month', fecha_finalizacion)::timestamp AS month,
      SUM(CASE WHEN EXTRACT(DAY FROM fecha_finalizacion) BETWEEN 1 AND 7 THEN total ELSE 0 END) AS first_week,
      SUM(CASE WHEN EXTRACT(DAY FROM fecha_finalizacion) BETWEEN 8 AND 14 THEN total ELSE 0 END) AS second_week,
      SUM(CASE WHEN EXTRACT(DAY FROM fecha_finalizacion) BETWEEN 15 AND 21 THEN total ELSE 0 END) AS third_week,
      SUM(CASE WHEN EXTRACT(DAY FROM fecha_finalizacion) >= 22 THEN total ELSE 0 END) AS fourth_week,
      SUM(total) AS total
    FROM public.pedidos
    WHERE estado_id = 5
    AND ($1::DATE IS NULL OR fecha_finalizacion >= $1::DATE)
    AND ($2::DATE IS NULL OR fecha_finalizacion <= $2::DATE)
    GROUP BY DATE_TRUNC('month', fecha_finalizacion)
  )
  SELECT
    month,
    first_week,
    second_week,
    third_week,
    fourth_week,
    total
  FROM weekly_income
  ORDER BY month ASC;
`;

export const SQL_GET_PENDING_ORDERS = `
  SELECT p.fecha_estimada_entrega,
        p.hora_estimada_entrega,
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
    AND e.nombre IN ('Creado', 'En Produccion', 'En Espera')
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
        p.hora_estimada_entrega,
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
  WITH RankedProducts AS (
    SELECT
      v.sku,
      pr.nombre,
      CASE
        WHEN POSITION(' ' IN pr.nombre) > 0 THEN SUBSTRING(pr.nombre, 1, POSITION(' ' IN pr.nombre) - 1)
        ELSE pr.nombre
        END AS categoria,
      COUNT(*) AS cantidad_vendida,
      (
        SELECT STRING_AGG(esp.nombre || ': ' || val.valor, ', ' ORDER BY esp.especificacion_id)
        FROM public.variante_valores vv
            JOIN public.valor val ON vv.valor_id = val.valor_id
            JOIN public.especificacion esp ON val.especificacion_id = esp.especificacion_id
        WHERE vv.variante_id = v.variante_id
      ) AS especificaciones,
      ROW_NUMBER() OVER (
        PARTITION BY CASE
                WHEN POSITION(' ' IN pr.nombre) > 0 THEN SUBSTRING(pr.nombre, 1, POSITION(' ' IN pr.nombre) - 1)
                ELSE pr.nombre
          END
        ORDER BY COUNT(*) DESC
        ) AS rank_in_category
    FROM pedidos p
        JOIN detalle_pedido d ON p.pedido_id = d.pedido_id
        JOIN productos pr ON d.producto_id = pr.producto_id
        JOIN producto_especificaciones pe ON pr.producto_id = pe.producto_id
        JOIN variantes v ON pr.producto_id = v.producto_id AND d.producto_id = v.producto_id
    WHERE p.estado_id = 5
      AND ($1::DATE IS NULL OR p.fecha_creacion >= $1::DATE)
      AND ($2::DATE IS NULL OR p.fecha_creacion <= $2::DATE)
    GROUP BY v.sku, pr.nombre, v.variante_id
  )
  SELECT sku, nombre AS producto, cantidad_vendida AS total_vendido, especificaciones
  FROM RankedProducts
  WHERE rank_in_category = 1
  ORDER BY cantidad_vendida DESC
  LIMIT 10;
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
  WITH fecha_filtro AS (SELECT $1::DATE AS fecha_inicio,
                              $2::DATE AS fecha_fin),
      fecha_extendida AS (SELECT CASE
                                      WHEN (SELECT fecha_inicio FROM fecha_filtro) IS NULL
                                          THEN DATE_TRUNC('month', CURRENT_DATE - INTERVAL '3 month')
                                      ELSE DATE_TRUNC('month', (SELECT fecha_inicio FROM fecha_filtro)) -
                                          INTERVAL '1 month'
                                      END AS fecha_inicio_extendida,
                                  CASE
                                      WHEN (SELECT fecha_fin FROM fecha_filtro) IS NULL THEN CURRENT_DATE
                                      ELSE (SELECT fecha_fin FROM fecha_filtro)
                                      END AS fecha_fin_extendida),
      pedidos_datos AS (SELECT DATE_TRUNC('month', fecha_creacion)     AS mes_creacion,
                                DATE_TRUNC('month', fecha_finalizacion) AS mes_finalizacion,
                                fecha_creacion,
                                fecha_finalizacion,
                                estado_id
                        FROM public.pedidos
                        WHERE (fecha_finalizacion >= (SELECT fecha_inicio_extendida FROM fecha_extendida) OR
                                fecha_finalizacion IS NULL)
                          AND (fecha_finalizacion <= (SELECT fecha_fin_extendida FROM fecha_extendida) OR
                                fecha_finalizacion IS NULL)),
      metricas_mensuales AS (SELECT mes_finalizacion                                                      AS mes,
                                    COUNT(*) FILTER (WHERE estado_id = 5)                                 AS pedidos_finalizados,
                                    AVG(EXTRACT(EPOCH FROM (fecha_finalizacion - fecha_creacion)) / 3600)
                                    FILTER (WHERE estado_id = 5)                                          AS tiempo_promedio_horas,
                                    CASE
                                        WHEN COUNT(*) > 0 THEN
                                            (COUNT(*) FILTER (WHERE estado_id = 5) * 100.0) / COUNT(*)
                                        ELSE 0
                                        END                                                               AS tasa_cumplimiento,
                                    COUNT(DISTINCT fecha_finalizacion::DATE) FILTER (WHERE estado_id = 5) AS dias_laborales,
                                    CASE
                                        WHEN COUNT(DISTINCT fecha_finalizacion::DATE) FILTER (WHERE estado_id = 5) > 0
                                            THEN
                                                    COUNT(*) FILTER (WHERE estado_id = 5) /
                                                    COUNT(DISTINCT fecha_finalizacion::DATE) FILTER (WHERE estado_id = 5)::FLOAT
                                        ELSE 0
                                        END                                                               AS productividad_diaria
                              FROM pedidos_datos
                              WHERE mes_finalizacion IS NOT NULL
                              GROUP BY mes_finalizacion),
      backlog_mensual AS (SELECT DATE_TRUNC('month', fecha_actual)::TIMESTAMP AS mes,
                                  COUNT(*) FILTER (WHERE estado_id != 5)       AS pedidos_pendientes
                          FROM (SELECT DISTINCT DATE_TRUNC('month', dd)::TIMESTAMP AS fecha_actual,
                                                p.estado_id
                                FROM GENERATE_SERIES(
                                              (SELECT fecha_inicio_extendida FROM fecha_extendida),
                                              (SELECT COALESCE(MAX(fecha_finalizacion), CURRENT_DATE) FROM pedidos_datos),
                                              '1 month'
                                      ) AS dd
                                          CROSS JOIN pedidos_datos p
                                WHERE p.fecha_creacion <= dd
                                  AND (p.fecha_finalizacion > dd OR p.fecha_finalizacion IS NULL)) AS backlog
                          GROUP BY fecha_actual),
      meses_ordenados AS (SELECT m.mes,
                                  m.pedidos_finalizados,
                                  LAG(m.pedidos_finalizados) OVER (ORDER BY m.mes) AS pedidos_mes_anterior,
                                  m.tiempo_promedio_horas,
                                  m.tasa_cumplimiento,
                                  m.dias_laborales,
                                  m.productividad_diaria,
                                  COALESCE(b.pedidos_pendientes, 0)                AS pedidos_pendientes
                          FROM metricas_mensuales m
                                    LEFT JOIN backlog_mensual b ON m.mes = b.mes)
  SELECT mes,
        pedidos_finalizados                   AS pedidos_mes_actual,
        pedidos_mes_anterior,
        CASE
            WHEN pedidos_mes_anterior > 0 THEN
                ((pedidos_finalizados - pedidos_mes_anterior) * 100.0 / pedidos_mes_anterior)::NUMERIC(10, 2)
            END                               AS porcentaje_variacion,
        tiempo_promedio_horas::NUMERIC(10, 2) AS tiempo_promedio_finalizacion_horas,
        tasa_cumplimiento::NUMERIC(10, 2)     AS porcentaje_cumplimiento,
        dias_laborales,
        productividad_diaria::NUMERIC(10, 2)  AS productividad_por_dia,
        pedidos_pendientes                    AS backlog_fin_mes
  FROM meses_ordenados
  WHERE mes IS NOT NULL
    AND (($1::DATE IS NULL) OR mes >= DATE_TRUNC('month', $1::DATE))
    AND (($2::DATE IS NULL) OR mes <= DATE_TRUNC('month', $2::DATE))
  ORDER BY mes;
`;
