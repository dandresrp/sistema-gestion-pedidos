import { orderService } from "../services/orderService.js";

export const orderController = {
  getAllOrders: async (estado, nombre_cliente, pedido_id) => {
    try {
      const response = await orderService.getAllOrders(
        estado,
        nombre_cliente,
        pedido_id
      );

      return {
        success: true,
        data: response.data,
        message: response.message || "Pedidos obtenidos con éxito",
      };
    } catch (error) {
      return {
        success: false,
        message: error.response?.data?.message || "Error al obtener pedidos",
      };
    }
  },
};
