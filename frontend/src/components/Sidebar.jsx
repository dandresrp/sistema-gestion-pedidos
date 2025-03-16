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
import { Link, useNavigate } from "react-router-dom";
import generateReportData from "../provider/reportsProvider";

const Sidebar = ({
  setReportData,
  setTitle,
  sidebarExpanded,
  setSidebarExpanded,
}) => {
  const [isReportesOpen, setIsReportesOpen] = useState(false);
  const navigate = useNavigate();

  const reportFetchers = {
    "completed-orders": () => generateReportData(1097),
    reporte2: generateReportData(50),
  };

  const reportTitles = {
    "completed-orders": `PEDIDOS REALIZADOS EL MES DE ${
      new Date().getMonth() + 1
    }`,
    reporte2: generateReportData(50),
  };

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

  const handleReportClick = async (reportName) => {
    const fetchFunction = reportFetchers[reportName];
    if (fetchFunction) {
      const data = await fetchFunction();
      setReportData(data);
      setTitle(reportTitles[reportName]);
    }
    navigate(`/reports/${reportName}`);
  };

  return (
    <div
      className={sidebarExpanded ? "sidebar expanded" : "sidebar"}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
    >
      {/* Icono de usuario y nombre */}
      <div className="user-info">
        <div className="avatar">
          <LiaUserCircleSolid />
        </div>
        <span className={sidebarExpanded ? "user-name expanded" : "user-name"}>
          Usuario
        </span>
      </div>

      {/* Menú */}
      <nav className="menu">
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
        <div
          className="menu-item reportes"
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
        </div>
        {sidebarExpanded && (
          <div className={`submenu ${isReportesOpen ? "open" : ""}`}>
            <Link
              onClick={() => handleReportClick("completed-orders")}
              className="submenu-item"
            >
              Pedidos realizados (mes)
            </Link>
            <Link href="/reports/2" className="submenu-item">
              Reporte 2
            </Link>
            <Link href="/reports/2" className="submenu-item">
              Reporte 3
            </Link>
            <Link href="/reports/2" className="submenu-item">
              Reporte 4
            </Link>
            <Link href="/reports/2" className="submenu-item">
              Reporte 5
            </Link>
            <Link href="/reports/2" className="submenu-item">
              Reporte 6
            </Link>
            <Link href="/reports/2" className="submenu-item">
              Reporte 7
            </Link>
            <Link href="/reports/2" className="submenu-item">
              Reporte 8
            </Link>
          </div>
        )}
      </nav>

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
