import apiClient from "../config/apiClient";

export const clientService = {
  getAllClients: async () => {
    return await apiClient.get("/clientes");
  },

  getClientById: async (clientId) => {
    return await apiClient.get(`/clientes/${clientId}`);
  },

  createClient: async (clientData) => {
    return await apiClient.post("/clientes", clientData);
  },

  updateClient: async (clientId, clientData) => {
    return await apiClient.put(`/clientes/${clientId}`, clientData);
  },

  deleteClient: async (clientId) => {
    return await apiClient.delete(`/clientes/${clientId}`);
  },
};
