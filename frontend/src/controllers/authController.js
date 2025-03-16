import { authService } from "../services/authService";

export const authController = {
  login: async (nombre_usuario, contrasena) => {
    try {
      const response = await authService.login(nombre_usuario, contrasena);
      return {
        success: true,
        data: response.data,
        message: response.message,
      };
    } catch (error) {
      return {
        success: false,
        message: error.response?.data?.message || "Error al iniciar sesión",
      };
    }
  },

  register: async (userData) => {
    try {
      const response = await authService.register(userData);
      return {
        success: true,
        data: response.data,
        message: response.message,
      };
    } catch (error) {
      return {
        success: false,
        message: error.response?.data?.message || "Error al registrar usuario",
      };
    }
  },

  logout: () => {
    authService.logout();
    return {
      success: true,
      message: "Sesión cerrada correctamente",
    };
  },
};
