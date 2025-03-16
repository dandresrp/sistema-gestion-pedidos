import apiClient from "../config/apiClient";

export const userService = {
  getAllUsers: async () => {
    return await apiClient.get("/usuarios");
  },

  getUserById: async (userId) => {
    return await apiClient.get(`/usuarios/${userId}`);
  },

  updateUser: async (userId, userData) => {
    return await apiClient.put(`/usuarios/${userId}`, userData);
  },

  deleteUser: async (userId) => {
    return await apiClient.delete(`/usuarios/${userId}`);
  },
};
