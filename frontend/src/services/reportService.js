import apiClient from "../config/apiClient";

export const reportService = {
  getOrdersByMonth: async (startDate, endDate, offset, limit) => {
    return await apiClient.get("/reportes/orders-by-month", {
      params: { startDate, endDate, offset, limit },
    });
  },

  getIncomeByMonth: async (startDate, endDate) => {
    return await apiClient.get("/reportes/income-by-month", {
      params: { startDate, endDate },
    });
  },

  getPendingOrders: async (startDate, endDate, offset, limit) => {
    return await apiClient.get("/reportes/pending-orders", {
      params: { startDate, endDate, offset, limit },
    });
  },

  getRejectedOrders: async (startDate, endDate, offset, limit) => {
    return await apiClient.get("/reportes/rejected-orders", {
      params: { startDate, endDate, offset, limit },
    });
  },

  getOrdersOutOfTime: async (startDate, endDate, offset, limit) => {
    return await apiClient.get("/reportes/orders-out-of-time", {
      params: { startDate, endDate, offset, limit },
    });
  },

  getBestSellingProductsHistory: async (startDate, endDate, offset, limit) => {
    return await apiClient.get("/reportes/best-selling-products-history", {
      params: { startDate, endDate, offset, limit },
    });
  },

  getInventory: async () => {
    return await apiClient.get("/reportes/inventory");
  },

  getProductionCapacity: async (startDate, endDate) => {
    return await apiClient.get("/reportes/production-capacity", {
      params: { startDate, endDate },
    });
  },
};
