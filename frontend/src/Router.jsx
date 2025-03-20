import { useState } from "react";
import {
  BrowserRouter as Router,
  Routes,
  Route,
  Navigate,
  Outlet,
} from "react-router-dom";
import useAuth from "./contexts/useAuth";
import Login from "./pages/Login";
import Home from "./pages/Home";
import Dashboard from "./pages/subpages/Dashboard";
import Orders from "./pages/subpages/Orders";
import Reports from "./pages/subpages/Reports";
import Inventory from "./pages/subpages/Inventory";

const ProtectedRoute = () => {
  const { isAuthenticated, loading } = useAuth();

  if (loading) {
    return <div>Loading...</div>;
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" />;
  }

  return <Outlet />;
};

const AppRouter = () => {
  const [sidebarExpanded, setSidebarExpanded] = useState(false);

  return (
    <Router>
      <Routes>
        <Route path="/" element={<ProtectedRoute />}>
          <Route
            element={
              <Home
                sidebarExpanded={sidebarExpanded}
                setSidebarExpanded={setSidebarExpanded}
              />
            }
          >
            <Route index element={<Navigate to="home" />} />
            <Route path="home" element={<Dashboard />} />
            <Route path="orders" element={<Orders />} />
            <Route
              path="reports/:reportName/:reportType"
              element={<Reports />}
            />
            <Route path="inventory" element={<Inventory />} />
          </Route>
        </Route>
        <Route path="/login" element={<Login />} />
      </Routes>
    </Router>
  );
};

export default AppRouter;
