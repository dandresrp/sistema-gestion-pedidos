import React from "react";
import "../styles/SynthetizedReports.css";
import logo from "../assets/image 1.png";

const Footer = () => {
  const fecha = new Date().toLocaleDateString();
  return (
    <div className="report-footer">
      <p>Fecha de emisión: {fecha}</p>
    </div>
  );
};

const SynthetizedReport = ({
  title,
  date1 = "01/03/2025",
  date2 = new Date().toLocaleDateString(),
  children,
}) => {
  return (
    <div className="report-container">
      <div className="reports-header">
        <div className="header-row">
          <div className="company-logo">
            <img src={logo} alt="Logo de la empresa" />
          </div>
          <div className="report-title">
            <h2>{title}</h2>
          </div>
          <div className="report-period">
            <span>
              Desde: <strong>{date1}</strong>
            </span>
            <br />
            <span>
              Hasta: <strong>{date2}</strong>
            </span>
          </div>
        </div>
      </div>

      <div className="report-content">{children}</div>
      <Footer />
    </div>
  );
};

export default SynthetizedReport;
