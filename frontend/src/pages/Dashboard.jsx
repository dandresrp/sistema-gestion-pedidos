import { useEffect, useState } from "react";
import userService from "../services/userService";
import useAuth from "../contexts/useAuth";

const Dashboard = () => {
  const { user, token, logout } = useAuth();
  const [userData, setUserData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchUserData = async () => {
      try {
        if (user && token) {
          const data = await userService.getById(user.id, token);
          setUserData(data);
        }
      } catch (error) {
        console.error("Error fetching user data:", error);
        
        if (error.message.includes('403') || error.message.includes('401')) {
          logout();
        }
      } finally {
        setLoading(false);
      }
    };

    fetchUserData();
  }, [user, token, logout]);

  if (loading) {
    return <div>Cargando datos del usuario...</div>;
  }

  return (
    <div className="welcome-container">
      <h1>Bienvenido a nuestra aplicación</h1>
      {userData && (
        <p>
          ¡Hola, {userData.nombre_usuario}! Nos alegra tenerte aquí. Explora las funcionalidades y disfruta de la
          experiencia.
        </p>
      )}
      <button onClick={logout}>Cerrar sesión</button>
    </div>
  );
};

export default Dashboard;