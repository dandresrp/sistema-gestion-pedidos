import apiClient from "../config/apiClient";

export const reportService = {
  getOrdersByMonth: async (month) => {
    return await apiClient.get(`/reportes/orders/${month}`);
  },
};
