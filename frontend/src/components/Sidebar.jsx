import { useState } from "react";
// import { motion } from "framer-motion";
import "../styles/Sidebar.css";
import {
  LiaHomeSolid,
  LiaBoxesSolid,
  LiaClipboardListSolid,
  LiaChartBarSolid,
  LiaSignOutAltSolid,
  LiaUserCircleSolid,
} from "react-icons/lia";

const Sidebar = () => {
  const [isExpanded, setIsExpanded] = useState(false);

  return (
    <div
      className={isExpanded ? "sidebar expanded" : "sidebar"}
      onMouseEnter={() => {
        setIsExpanded(true);
      }}
      onMouseLeave={() => {
        setIsExpanded(false);
      }}
    >
      {/* Icono de usuario y nombre */}
      <div className="user-info">
        <div className="avatar">
          <LiaUserCircleSolid />
        </div>
        {isExpanded && <span className="user-name">Usuario</span>}
      </div>
      {/* Menú */}
      <nav className="menu">
        <a href={"/dashboard"} className="menu-item">
          <div className="menu-icon">
            <LiaHomeSolid />
          </div>
          <span className={isExpanded ? "menu-text expanded" : "menu-text"}>
            {"Inicio"}
          </span>
        </a>
        <a href={"/pedidos"} className="menu-item">
          <div className="menu-icon">
            <LiaClipboardListSolid />
          </div>
          <span className={isExpanded ? "menu-text expanded" : "menu-text"}>
            {"Pedidos"}
          </span>
        </a>
        <a href={"/inventario"} className="menu-item">
          <div className="menu-icon">
            <LiaBoxesSolid />
          </div>
          <span className={isExpanded ? "menu-text expanded" : "menu-text"}>
            {"Inventario"}
          </span>
        </a>
        <a href={"/reportes"} className="menu-item">
          <div className="menu-icon">
            <LiaChartBarSolid />
          </div>
          <span className={isExpanded ? "menu-text expanded" : "menu-text"}>
            {"Reportes"}
          </span>
        </a>
      </nav>
      {/* Cerrar sesión */}
      <div className="logout">
        <a href="/logout" className="menu-item logout-item">
          <div className="menu-icon">
            <LiaSignOutAltSolid />
          </div>
          <span className={isExpanded ? "menu-text expanded" : "menu-text"}>
            SALIR
          </span>
        </a>
      </div>
    </div>
  );
};

export default Sidebar;
