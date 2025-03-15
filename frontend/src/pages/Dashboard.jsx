import React from "react";
import Sidebar from "../components/Sidebar";

const Dashboard = () => {
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
