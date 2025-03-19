export const SQL_GET_ORDERS_BY_MONTH = `
      SELECT p.fecha_creacion AS fecha,
         c.nombre         AS cliente,
         pr.nombre        AS producto,
         pr.precio        AS monto,
         p.estado         AS estado,
         p.metodo_envio
      FROM pedidos AS p
      JOIN clientes AS c
      ON p.id_cliente = c.id_cliente
      JOIN detallespedido AS dp
      ON p.id_pedido = dp.id_pedido
      JOIN productos AS pr
      ON dp.id_producto = pr.id_producto
      WHERE p.fecha_creacion >= $1::date AND p.fecha_creacion <= $2::date
      ORDER BY p.fecha_creacion DESC
      OFFSET $3 LIMIT $4;
    `;
