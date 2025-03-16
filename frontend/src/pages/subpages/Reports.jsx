import DetailedReports from "../../components/DetailedReports";
import { useOutletContext } from "react-router-dom";
const Reportes = () => {
  const { reportData, title } = useOutletContext();

  return (
    <div className="container-reports">
      {reportData ? (
        <DetailedReports title={title} data={reportData} recordsPerPage={20} />
      ) : (
        <p>Cargando reporte...</p>
      )}
    </div>
  );
};
export default Reportes;
