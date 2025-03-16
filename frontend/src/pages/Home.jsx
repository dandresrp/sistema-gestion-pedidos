import { Outlet } from "react-router-dom";
import Sidebar from "../components/Sidebar";
import "../styles/Home.css";
import { useState } from "react";

const Home = ({ sidebarExpanded, setSidebarExpanded }) => {
  const [reportData, setReportData] = useState(null);
  const [title, setTitle] = useState(null);

  return (
    <div className="home-container">
      <Sidebar
        sidebarExpanded={sidebarExpanded}
        setSidebarExpanded={setSidebarExpanded}
        setReportData={setReportData}
        setTitle={setTitle}
      />
      <div className={`content ${sidebarExpanded ? "expanded" : ""}`}>
        <Outlet context={{ reportData, title }} />
      </div>
    </div>
  );
};

export default Home;
