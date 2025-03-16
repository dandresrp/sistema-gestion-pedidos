import { userService } from "../services/userService";

export const userController = {
  getAllUsers: async () => {
    try {
      const response = await userService.getAllUsers();
      return {
        success: true,
        data: response.data,
        message: response.message,
      };
    } catch (error) {
      return {
        success: false,
        message: error.response?.data?.message || "Error al obtener usuarios",
      };
    }
  },

  getUserById: async (userId) => {
    try {
      const response = await userService.getUserById(userId);
      return {
        success: true,
        data: response.data,
        message: response.message,
      };
    } catch (error) {
      return {
        success: false,
        message: error.response?.data?.message || "Error al obtener usuario",
      };
    }
  },

  updateUser: async (userId, userData) => {
    try {
      const response = await userService.updateUser(userId, userData);
      return {
        success: true,
        data: response.data,
        message: response.message,
      };
    } catch (error) {
      return {
        success: false,
        message: error.response?.data?.message || "Error al actualizar usuario",
      };
    }
  },

  deleteUser: async (userId) => {
    try {
      const response = await userService.deleteUser(userId);
      return {
        success: true,
        data: response.data,
        message: response.message,
      };
    } catch (error) {
      return {
        success: false,
        message: error.response?.data?.message || "Error al eliminar usuario",
      };
    }
  },
};
