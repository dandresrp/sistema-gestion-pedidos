import apiClient from "../config/apiClient";

export const authService = {
  login: async (nombre_usuario, contrasena) => {
    const response = await apiClient.post("/auth/sign-in", {
      nombre_usuario,
      contrasena,
    });
    if (response.success) {
      sessionStorage.setItem("token", response.data.token);
      sessionStorage.setItem("refreshToken", response.data.refreshToken);
      sessionStorage.setItem(
        "user",
        JSON.stringify({
          id_usuario: response.data.id_usuario,
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
      sessionStorage.setItem("token", response.data.token);
    }
    return response;
  },

  logout: () => {
    sessionStorage.removeItem("token");
    sessionStorage.removeItem("refreshToken");
    sessionStorage.removeItem("user");
  },
};
