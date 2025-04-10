import { reportService } from "../services/reportService";

export const reportController = {
  getOrdersByMonth: async (startDate, endDate, offset, limit) => {
    try {
      const response = await reportService.getOrdersByMonth(
        startDate,
        endDate,
        offset,
        limit
      );
      return {
        success: true,
        data: response.data,
        message: response.message,
      };
    } catch (error) {
      return {
        success: false,
        message: error.response?.data?.message || "Error al obtener reporte",
      };
    }
  },

  getIncomeByMonth: async (startDate, endDate) => {
    try {
      const response = await reportService.getIncomeByMonth(startDate, endDate);
      return {
        success: true,
        data: response.data,
        message: response.message,
      };
    } catch (error) {
      return {
        success: false,
        message: error.response?.data?.message || "Error al obtener reporte",
      };
    }
  },

  getPendingOrders: async (startDate, endDate, offset, limit) => {
    try {
      const response = await reportService.getPendingOrders(
        startDate,
        endDate,
        offset,
        limit
      );
      return {
        success: true,
        data: response.data,
        message: response.message,
      };
    } catch (error) {
      return {
        success: false,
        message: error.response?.data?.message || "Error al obtener reporte",
      };
    }
  },

  getRejectedOrders: async (startDate, endDate, offset, limit) => {
    try {
      const response = await reportService.getRejectedOrders(
        startDate,
        endDate,
        offset,
        limit
      );
      return {
        success: true,
        data: response.data,
        message: response.message,
      };
    } catch (error) {
      return {
        success: false,
        message: error.response?.data?.message || "Error al obtener reporte",
      };
    }
  },

  getOrdersOutOfTime: async (startDate, endDate, offset, limit) => {
    try {
      const response = await reportService.getOrdersOutOfTime(
        startDate,
        endDate,
        offset,
        limit
      );
      return {
        success: true,
        data: response.data,
        message: response.message,
      };
    } catch (error) {
      return {
        success: false,
        message: error.response?.data?.message || "Error al obtener reporte",
      };
    }
  },

  getBestSellingProductsHistory: async (startDate, endDate, offset, limit) => {
    try {
      const response = await reportService.getBestSellingProductsHistory(
        startDate,
        endDate,
        offset,
        limit
      );
      return {
        success: true,
        data: response.data,
        message: response.message,
      };
    } catch (error) {
      return {
        success: false,
        message: error.response?.data?.message || "Error al obtener reporte",
      };
    }
  },

  getInventory: async () => {
    try {
      const response = await reportService.getInventory();
      return {
        success: true,
        data: response.data,
        message: response.message,
      };
    } catch (error) {
      return {
        success: false,
        message: error.response?.data?.message || "Error al obtener reporte",
      };
    }
  },

  getProductionCapacity: async (startDate, endDate) => {
    try {
      const response = await reportService.getProductionCapacity(
        startDate,
        endDate
      );
      return {
        success: true,
        data: response.data,
        message: response.message,
      };
    } catch (error) {
      return {
        success: false,
        message: error.response?.data?.message || "Error al obtener reporte",
      };
    }
  },
};
