import apiClient from "../config/apiClient";

export const authService = {
  login: async (nombre_usuario, contrasena) => {
    const response = await apiClient.post("/auth/sign-in", {
      nombre_usuario,
      contrasena,
    });
    if (response.success) {
      localStorage.setItem("token", response.data.token);
      localStorage.setItem("refreshToken", response.data.refreshToken);
      localStorage.setItem(
        "user",
        JSON.stringify({
          id_usuario: response.data.id_usuario,
          nombre_usuario,
        })
      );
    }
    return response;
  },

  register: async (userData) => {
    return await apiClient.post("/auth/sign-up", userData);
  },

  refreshToken: async (refreshToken) => {
    const response = await apiClient.post("/auth/refresh-token", {
      refreshToken,
    });
    if (response.success) {
      localStorage.setItem("token", response.data.token);
    }
    return response;
  },

  logout: () => {
    localStorage.removeItem("token");
    localStorage.removeItem("refreshToken");
    localStorage.removeItem("user");
  },
};
