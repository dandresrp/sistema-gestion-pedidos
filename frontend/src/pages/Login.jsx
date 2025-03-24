import "../styles/Login.css";
import logo from "../assets/image 1.png";
import { useState } from "react";
import { Navigate } from "react-router-dom";
import useAuth from "../contexts/useAuth";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faEye, faEyeSlash, faUser } from "@fortawesome/free-regular-svg-icons";

const Login = () => {
  const { login, isAuthenticated, error } = useAuth();
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  const handleLogin = async (e) => {
    e.preventDefault();
    setIsLoading(true);
    await login(username, password);
    setIsLoading(false);
  };

  const togglePasswordVisibility = () => {
    setShowPassword(!showPassword);
  };

  if (isAuthenticated) {
    return <Navigate to="/home" />;
  }

  return (
    <div className="login-page">
      <div className="container">
        <div className="left-section">
          <img src={logo} alt="Logo" className="logo" />
        </div>
        <div className="login-container">
          <form className="login-form" onSubmit={handleLogin}>
            {error && <div className="error-message">{error}</div>}
            <div className="user-container">
              <input
                type="text"
                placeholder="Usuario"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
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
            <button type="submit" className="login-button" disabled={isLoading}>
              {isLoading ? "Cargando..." : "Acceder"}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};

export default Login;
