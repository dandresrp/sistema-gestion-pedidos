import apiClient from "../config/apiClient";

export const reportService = {
  getOrdersByMonth: async (startDate, endDate, offset, limit) => {
    return await apiClient.get(
      `/reportes/orders-by-month?startDate=${startDate}&endDate=${endDate}&offset=${offset}&limit=${limit}`
    );
  },

  getIncomeByMonth: async (startDate, endDate, offset, limit) => {
    return await apiClient.get(
      `/reportes/income-by-month?startDate=${startDate}&endDate=${endDate}&offset=${offset}&limit=${limit}`
    );
  },

  getPendingOrders: async (startDate, endDate, offset, limit) => {
    return await apiClient.get(
      `/reportes/pending-orders?startDate=${startDate}&endDate=${endDate}&offset=${offset}&limit=${limit}`
    );
  },

  getRejectedOrders: async (startDate, endDate, offset, limit) => {
    return await apiClient.get(
      `/reportes/rejected-orders?startDate=${startDate}&endDate=${endDate}&offset=${offset}&limit=${limit}`
    );
  },

  getOrdersOutOfTime: async (startDate, endDate, offset, limit) => {
    return await apiClient.get(
      `/reportes/orders-out-of-time?startDate=${startDate}&endDate=${endDate}&offset=${offset}&limit=${limit}`
    );
  },

  getBestSellingProductsHistory: async (startDate, endDate, offset, limit) => {
    return await apiClient.get(
      `/reportes/best-selling-products-history?startDate=${startDate}&endDate=${endDate}&offset=${offset}&limit=${limit}`
    );
  },

  getInventoy: async () => {
    return await apiClient.get(`/reportes/inventory`);
  },

  getProductionCapacity: async (startDate, endDate) => {
    return await apiClient.get(
      `/reportes/production-capacity?startDate=${startDate}&endDate=${endDate}`
    );
  },
};
