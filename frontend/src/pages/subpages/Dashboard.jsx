import React, { useState } from "react";
import "../../styles/Dashboard.css";
import {
  ManageUsersModal,
  ManageClientsModal,
} from "../../components/UserClientModals";

export default function Dashboard() {
  // const resumen = {
  //   totalPedidos: 120,
  //   pedidosHoy: 8,
  //   totalClientes: 57,
  //   totalUsuarios: 12,
  // };

  const [showUsersModal, setShowUsersModal] = useState(false);
  const [showClientsModal, setShowClientsModal] = useState(false);

  return (
    <div className="dashboard">
      <h1>Inicio</h1>

      {/* <div className="resumen-cards">
        <div className="card">
          <h3>Pedidos Hoy</h3>
          <p>{resumen.pedidosHoy}</p>
        </div>
        <div className="card">
          <h3>Total Clientes</h3>
          <p>{resumen.totalClientes}</p>
        </div>
        <div className="card">
          <h3>Total Usuarios</h3>
          <p>{resumen.totalUsuarios}</p>
        </div>
      </div> */}

      <div className="gestion-section">
        <div className="gestion-card" onClick={() => setShowUsersModal(true)}>
          <h2>Gestionar Usuarios</h2>
          <p>Ver, agregar o editar usuarios del sistema</p>
        </div>
        <div className="gestion-card" onClick={() => setShowClientsModal(true)}>
          <h2>Gestionar Clientes</h2>
          <p>Ver, agregar o editar clientes registrados</p>
        </div>
      </div>

      {showUsersModal && (
        <ManageUsersModal onClose={() => setShowUsersModal(false)} />
      )}
      {showClientsModal && (
        <ManageClientsModal onClose={() => setShowClientsModal(false)} />
      )}
    </div>
  );
}
