import apiClient from "../config/apiClient";

export const orderService = {
  getAllOrders: async (estado, nombre_cliente, pedido_id) => {
    return await apiClient.get("/pedidos", {
      params: { estado, nombre_cliente, pedido_id },
    });
  },
};
