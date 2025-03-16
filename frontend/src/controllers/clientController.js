import { clientService } from "../services/clientService";

export const clientController = {
  getAllClients: async () => {
    try {
      const response = await clientService.getAllClients();
      return {
        success: true,
        data: response.data,
        message: response.message,
      };
    } catch (error) {
      return {
        success: false,
        message: error.response?.data?.message || "Error al obtener clientes",
      };
    }
  },

  getClientById: async (clientId) => {
    try {
      const response = await clientService.getClientById(clientId);
      return {
        success: true,
        data: response.data,
        message: response.message,
      };
    } catch (error) {
      return {
        success: false,
        message: error.response?.data?.message || "Error al obtener cliente",
      };
    }
  },

  createClient: async (clientData) => {
    try {
      const response = await clientService.createClient(clientData);
      return {
        success: true,
        data: response.data,
        message: response.message,
      };
    } catch (error) {
      return {
        success: false,
        message: error.response?.data?.message || "Error al crear cliente",
      };
    }
  },

  updateClient: async (clientId, clientData) => {
    try {
      const response = await clientService.updateClient(clientId, clientData);
      return {
        success: true,
        data: response.data,
        message: response.message,
      };
    } catch (error) {
      return {
        success: false,
        message: error.response?.data?.message || "Error al actualizar cliente",
      };
    }
  },

  deleteClient: async (clientId) => {
    try {
      const response = await clientService.deleteClient(clientId);
      return {
        success: true,
        data: response.data,
        message: response.message,
      };
    } catch (error) {
      return {
        success: false,
        message: error.response?.data?.message || "Error al eliminar cliente",
      };
    }
  },
};
