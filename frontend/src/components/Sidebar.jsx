import { useState, useEffect } from "react";
import useAuth from "../contexts/useAuth";
import "../styles/Sidebar.css";
import {
  LiaHomeSolid,
  LiaBoxesSolid,
  LiaClipboardListSolid,
  LiaChartBarSolid,
  LiaSignOutAltSolid,
  LiaUserCircleSolid,
} from "react-icons/lia";
import { Link, useLocation } from "react-router-dom";

const Sidebar = ({ sidebarExpanded, setSidebarExpanded }) => {
  const { logout } = useAuth();
  const [isReportesOpen, setIsReportesOpen] = useState(false);
  const location = useLocation();
  const isReportsSection = location.pathname.startsWith("/reports");

  const handleMouseEnter = () => {
    setSidebarExpanded(true);
  };

  const handleMouseLeave = () => {
    setSidebarExpanded(false);
  };

  const handleLogout = (e) => {
    e.preventDefault();
    logout();
  };

  useEffect(() => {
    if (!sidebarExpanded) {
      setIsReportesOpen(false);
    }
  }, [sidebarExpanded]);

  return (
    <div
      className={sidebarExpanded ? "sidebar expanded" : "sidebar"}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
    >
      {/* Menú */}
      <nav className="menu">
        <Link className="menu-item">
          <div className="menu-icon">
            <LiaUserCircleSolid />
          </div>
          <span
            className={sidebarExpanded ? "menu-text expanded" : "menu-text"}
          >
            {"Usuario"}
          </span>
        </Link>
        <Link
          to="/home"
          className={`menu-item ${
            sidebarExpanded && location.pathname === "/home" ? "active" : ""
          }`}
        >
          <div
            className={`menu-icon ${
              !sidebarExpanded && location.pathname === "/home" ? "active" : ""
            }`}
          >
            <LiaHomeSolid />
          </div>
          <span
            className={sidebarExpanded ? "menu-text expanded" : "menu-text"}
          >
            {"Inicio"}
          </span>
        </Link>
        <Link
          to="/orders"
          className={`menu-item ${
            sidebarExpanded && location.pathname === "/orders" ? "active" : ""
          }`}
        >
          <div
            className={`menu-icon ${
              !sidebarExpanded && location.pathname === "/orders"
                ? "active"
                : ""
            }`}
          >
            <LiaClipboardListSolid />
          </div>
          <span
            className={sidebarExpanded ? "menu-text expanded" : "menu-text"}
          >
            {"Pedidos"}
          </span>
        </Link>
        <Link
          to="/inventory"
          className={`menu-item ${
            sidebarExpanded && location.pathname === "/inventory"
              ? "active"
              : ""
          }`}
        >
          <div
            className={`menu-icon ${
              !sidebarExpanded && location.pathname === "/inventory"
                ? "active"
                : ""
            }`}
          >
            <LiaBoxesSolid />
          </div>
          <span
            className={sidebarExpanded ? "menu-text expanded" : "menu-text"}
          >
            {"Inventario"}
          </span>
        </Link>
        <Link
          className={`menu-item ${isReportsSection ? "active" : ""}`}
          onClick={() => setIsReportesOpen(!isReportesOpen)}
        >
          <div className="menu-icon">
            <LiaChartBarSolid />
          </div>
          <span
            className={sidebarExpanded ? "menu-text expanded" : "menu-text"}
          >
            {"Reportes"}
          </span>
        </Link>
      </nav>

      <div className="submenu-container">
        <div
          className={`submenu ${
            sidebarExpanded && isReportesOpen ? "open" : ""
          }`}
        >
          <Link
            to="/reports/completed-orders/detailed"
            className="submenu-item"
          >
            Pedidos Completados
          </Link>
          <Link to="/reports/pending-orders/detailed" className="submenu-item">
            Pedidos Pendientes
          </Link>
          <Link to="/reports/inventory/detailed" className="submenu-item">
            Reporte de Inventario
          </Link>
          <Link to="/reports/delayed-orders/detailed" className="submenu-item">
            Pedidos Retrasados
          </Link>
          <Link
            to="/reports/monthly-income/synthetized"
            className="submenu-item"
          >
            Ingresos por Mes
          </Link>
          <Link
            to="/reports/best-selling-products/synthetized"
            className="submenu-item"
          >
            Productos más Vendidos
          </Link>
          <Link
            to="/reports/production-capacity/synthetized"
            className="submenu-item"
          >
            Capacidad de Producción
          </Link>
          <Link to="/reports/rejected-orders/detailed" className="submenu-item">
            Pedidos Rechazados
          </Link>
        </div>
      </div>

      {/* Cerrar sesión */}
      <div className="logout">
        <a onClick={handleLogout} className="menu-item logout-item">
          <div className="menu-icon">
            <LiaSignOutAltSolid />
          </div>
          <span
            className={sidebarExpanded ? "menu-text expanded" : "menu-text"}
          >
            Cerrar sesión
          </span>
        </a>
      </div>
    </div>
  );
};

export default Sidebar;
