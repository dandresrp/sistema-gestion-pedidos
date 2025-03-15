import "../styles/Login.css";
import logo from "../assets/image 1.png";
import { useState } from "react";
import { Navigate } from "react-router-dom";
import useAuth from "../contexts/useAuth";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faEye, faEyeSlash, faUser } from "@fortawesome/free-regular-svg-icons";

const Login = () => {
  const { login, isAuthenticated } = useAuth();
  const [nombreUsuario, setNombreUsuario] = useState("");
  const [contrasena, setContrasena] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");

  const handleLogin = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    setError("");
    
    try {
      await login(nombreUsuario, contrasena);
    } catch (error) {
      setError(error.message || "Error al iniciar sesión");
    } finally {
      setIsLoading(false);
    }
  };

  const togglePasswordVisibility = () => {
    setShowPassword(!showPassword);
  };

  if (isAuthenticated) {
    return <Navigate to="/dashboard" />;
  }

  return (

    <div className="login-page">
      <div className="container">
        <div className="left-section">
          <img src={logo} alt="Logo" className="logo" />
        </div>
        <div className="login-container">
          <form className="login-form" onSubmit={handleLogin}>
            <div className="user-container">
              <input
                type="text"
                placeholder="Usuario"
                value={user}
                onChange={(e) => setUser(e.target.value)}
                required
              />
              <FontAwesomeIcon icon={faUser} className="user-icon" />
            </div>
            <div className="password-container">
              <input
                type={showPassword ? "text" : "password"}
                placeholder="Contraseña"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
              <FontAwesomeIcon
                icon={showPassword ? faEyeSlash : faEye}
                className="password-icon"
                onClick={togglePasswordVisibility}
              />
            </div>
            <button type="submit">Acceder</button>
          </form>
        </div>
      </div>
    </div>
  );
};

export default Login;
