import { stagesService } from "../services/stagesService.js";

export const stagesController = {
  getAllStages: async () => {
    try {
      const response = await stagesService.getAllStages();
      return {
        success: true,
        data: response.data,
        message: response.message || "Estados obtenidos con éxito",
      };
    } catch (error) {
      return {
        success: false,
        message: error.response?.data?.message || "Error al obtener estados",
      };
    }
  },
};
