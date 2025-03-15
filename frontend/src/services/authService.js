import api from './api';

const login = async (nombre_usuario, contrasena) => {
  const response = await fetch(`${api.API_URL}/auth/sign-in`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ nombre_usuario, contrasena }),
  });
  
  return api.handleResponse(response);
};

const register = async (userData) => {
  const response = await fetch(`${api.API_URL}/auth/sign-up`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(userData),
  });
  
  return api.handleResponse(response);
};

export default {
  login,
  register
};