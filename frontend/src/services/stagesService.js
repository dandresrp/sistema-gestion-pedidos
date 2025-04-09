import apiClient from "../config/apiClient";

export const stagesService = {
  getAllStages: async () => {
    return await apiClient.get("/estados");
  },
};
