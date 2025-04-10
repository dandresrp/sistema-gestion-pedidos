export const SQL_GET_ALL_ORDERS = `
  SELECT p.pedido_id, c.nombre AS cliente, e.nombre AS estado, p.total, p.fecha_creacion, p.fecha_estimada_entrega
  FROM pedidos p
          JOIN clientes c ON p.cliente_id = c.cliente_id
          JOIN public.estados e ON e.estado_id = p.estado_id
  WHERE e.nombre = COALESCE($1, e.nombre)
    AND ($2::text IS NULL OR c.nombre ILIKE '%' || $2 || '%')
    AND ($3::text IS NULL OR CAST(p.pedido_id AS TEXT) LIKE '%' || $3 || '%');
`;
