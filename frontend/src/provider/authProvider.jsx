import { useState, useEffect } from "react";
import PropTypes from "prop-types";
import AuthContext from "../contexts/authContext";
import { authController } from "../controllers/authController";

const AuthProvider = ({ children }) => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [loading, setLoading] = useState(true);
  const [user, setUser] = useState(null);
  const [error, setError] = useState(null);

  const isTokenExpired = (token) => {
    try {
      const payloadBase64 = token.split(".")[1];
      const payload = JSON.parse(atob(payloadBase64));
      return payload.exp * 1000 < Date.now() - 60000;
    } catch (e) {
      console.error("Error al analizar el token JWT:", e);
      return true;
    }
  };

  useEffect(() => {
    const checkAuth = async () => {
      const token = localStorage.getItem("token");
      const refreshToken = localStorage.getItem("refreshToken");
      const userStr = localStorage.getItem("user");

      if (!token || !refreshToken || !userStr) {
        setLoading(false);
        return;
      }

      try {
        if (isTokenExpired(token)) {
          const response = await authController.refreshToken(refreshToken);

          if (response.success) {
            localStorage.setItem("token", response.data.token);
            setUser(JSON.parse(userStr));
            setIsAuthenticated(true);
          } else {
            logout();
          }
        } else {
          setUser(JSON.parse(userStr));
          setIsAuthenticated(true);
        }
      } catch (error) {
        console.error("Error refreshing token:", error);
        logout();
      }

      setLoading(false);
    };

    checkAuth();
  }, []);

  const login = async (username, password) => {
    setError(null);
    try {
      const response = await authController.signIn(username, password);

      if (response.success) {
        const { token, refreshToken, id_usuario } = response.data;

        localStorage.setItem("token", token);
        localStorage.setItem("refreshToken", refreshToken);

        const userData = { id: id_usuario, username };
        localStorage.setItem("user", JSON.stringify(userData));

        setUser(userData);
        setIsAuthenticated(true);
        return true;
      } else {
        setError(response.message || "Credenciales inválidas");
        return false;
      }
    } catch (err) {
      console.error("Error during login:", err);
      setError("Error de conexión");
      return false;
    }
  };

  const logout = () => {
    localStorage.removeItem("token");
    localStorage.removeItem("refreshToken");
    localStorage.removeItem("user");
    setIsAuthenticated(false);
    setUser(null);
  };

  const value = {
    isAuthenticated,
    user,
    loading,
    error,
    login,
    logout,
  };

  return (
    <AuthContext.Provider value={value}>
      {!loading && children}
    </AuthContext.Provider>
  );
};

AuthProvider.propTypes = {
  children: PropTypes.node.isRequired,
};

export default AuthProvider;
