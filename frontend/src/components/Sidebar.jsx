import { useState, useEffect } from "react";
import "../styles/Sidebar.css";
import {
  LiaHomeSolid,
  LiaBoxesSolid,
  LiaClipboardListSolid,
  LiaChartBarSolid,
  LiaSignOutAltSolid,
  LiaUserCircleSolid,
} from "react-icons/lia";
import { Link } from "react-router-dom";

const Sidebar = ({ sidebarExpanded, setSidebarExpanded }) => {
  const [isReportesOpen, setIsReportesOpen] = useState(false);

  const handleMouseEnter = () => {
    setSidebarExpanded(true);
  };

  const handleMouseLeave = () => {
    setSidebarExpanded(false);
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
        <Link to={"/home"} className="menu-item">
          <div className="menu-icon">
            <LiaHomeSolid />
          </div>
          <span
            className={sidebarExpanded ? "menu-text expanded" : "menu-text"}
          >
            {"Inicio"}
          </span>
        </Link>
        <Link to={"/orders"} className="menu-item">
          <div className="menu-icon">
            <LiaClipboardListSolid />
          </div>
          <span
            className={sidebarExpanded ? "menu-text expanded" : "menu-text"}
          >
            {"Pedidos"}
          </span>
        </Link>
        <Link to={"/inventory"} className="menu-item">
          <div className="menu-icon">
            <LiaBoxesSolid />
          </div>
          <span
            className={sidebarExpanded ? "menu-text expanded" : "menu-text"}
          >
            {"Inventario"}
          </span>
        </Link>
        <Link
          className="menu-item"
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
            Pedidos realizados
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
            Ingresos por mes
          </Link>
          <Link
            to="/reports/best-selling-products/synthetized"
            className="submenu-item"
          >
            Productos mas vendidos
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
        <a href="/logout" className="menu-item logout-item">
          <div className="menu-icon">
            <LiaSignOutAltSolid />
          </div>
          <span
            className={sidebarExpanded ? "menu-text expanded" : "menu-text"}
          >
            SALIR
          </span>
        </a>
      </div>
    </div>
  );
};

export default Sidebar;
