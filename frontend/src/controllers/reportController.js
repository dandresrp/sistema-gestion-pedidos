import { reportService } from "../services/reportService";

export const reportController = {
  getOrdersByMonth: async (month) => {
    try {
      const response = await reportService.getOrdersByMonth(month);
      return {
        success: true,
        data: response.data,
        message: response.message,
      };
    } catch (error) {
      return {
        success: false,
        message: error.response?.data?.message || "Error al obtener reportes",
      };
    }
  },
};
