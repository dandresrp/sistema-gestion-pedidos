
import React from "react";
import Sidebar from "../components/Sidebar";

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
    <div className="content">
      <Sidebar />
      <div className="titulo">
        <h1>Dashboard</h1>
        <p>Este es el dashboard</p>
      </div>
    </div>
  );
};

export default Dashboard;