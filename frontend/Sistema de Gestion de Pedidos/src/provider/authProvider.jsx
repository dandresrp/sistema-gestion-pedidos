import { useState, useEffect } from "react";
import PropTypes from "prop-types";
import AuthContext from "../contexts/authContext";

const AuthProvider = ({ children }) => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [loading, setLoading] = useState(true);
  const [user, setUser] = useState(null);

  useEffect(() => {
    const storedUser = sessionStorage.getItem("user");
    if (storedUser) {
      setUser(JSON.parse(storedUser));
      setIsAuthenticated(true);
    }
    setLoading(false);
  }, []);

  const login = (user, password) => {
    if (user === "user" && password === "pass") {
      const userData = { user };
      setUser(userData);
      setIsAuthenticated(true);
      sessionStorage.setItem("user", JSON.stringify(userData));
    } else {
      alert("Credenciales incorrectas");
    }
  };

  const logout = () => {
    setIsAuthenticated(false);
    setUser(null);
    sessionStorage.removeItem("user");
  };

  const value = {
    isAuthenticated,
    user,
    loading,
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
