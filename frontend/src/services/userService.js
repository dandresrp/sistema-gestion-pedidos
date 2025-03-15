import api from './api';

const getAll = async (token) => {
  const response = await fetch(`${api.API_URL}/usuarios`, {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  
  return api.handleResponse(response);
};

const getById = async (id, token) => {
  const response = await fetch(`${api.API_URL}/usuarios/${id}`, {
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  
  return api.handleResponse(response);
};

const updateUser = async (id, userData, token) => {
  const response = await fetch(`${api.API_URL}/usuarios/${id}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify(userData),
  });
  
  return api.handleResponse(response);
};

const deleteUser = async (id, token) => {
  const response = await fetch(`${api.API_URL}/usuarios/${id}`, {
    method: 'DELETE',
    headers: {
      'Authorization': `Bearer ${token}`
    }
  });
  
  return api.handleResponse(response);
};

export default {
  getAll,
  getById,
  updateUser,
  deleteUser
};