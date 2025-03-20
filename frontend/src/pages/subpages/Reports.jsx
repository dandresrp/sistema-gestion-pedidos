import { useParams } from "react-router-dom";
import { useEffect, useState } from "react";
import {
  completedOrders,
  pendingOrders,
  inventoryReport,
  delayedOrders,
  rejectedOrders,
  monthlyIncome,
  fetchTopProductosVendidos,
  productionCapacity,
} from "../../services/BDServices";
import DetailedReports from "../../components/DetailedReports";
import SynthetizedReports from "../../components/SynthetizedReports";
import ReportColumns, { ReportTitles } from "../../utils";
import ChartComponent from "../../components/ChartComponent";
import TableComponent from "../../components/tableComponent";

const Reports = () => {
  const { reportName, reportType } = useParams();
  const [reportData, setReportData] = useState(null);
  const [chartData, setChartData] = useState(null);
  // const [labels, setLabels] = useState(null);
  const [lines, setLines] = useState(null);
  const [type, setType] = useState(null);
  const [barKey, setBarKey] = useState(null);
  const [ReportsColumns, setReportColumns] = useState(null);
  const [lineKey, setLineKey] = useState(null);
  const [ReportsTitles, setReportTitles] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    setLoading(true);
    setError(null);

    const fetchReportData = async () => {
      try {
        let type;
        let data;
        let columns = new ReportColumns(reportName).getColumns();
        let title = ReportTitles[reportName];
        if (reportType === "detailed") {
          switch (reportName) {
            case "completed-orders":
              data = await completedOrders();
              break;
            case "pending-orders":
              data = await pendingOrders();
              break;
            case "inventory":
              data = await inventoryReport();
              break;
            case "delayed-orders":
              data = await delayedOrders();
              break;
            case "rejected-orders":
              data = await rejectedOrders();
              break;
            default:
              throw new Error("Reporte detallado no encontrado");
          }
          setReportData(data["data"]);
          setReportColumns(columns);
          setReportTitles(title);
        } else if (reportType === "synthetized") {
          switch (reportName) {
            case "monthly-income":
              type = "line";
              data = await monthlyIncome();
              setChartData(data["chartData"]);
              setLines(data["lines"]);
              setBarKey(null); // No hay barras en este gráfico

              setType(type);
              break;
            case "best-selling-products":
              type = "pie";
              data = await fetchTopProductosVendidos();

              setChartData(data["chartData"]);
              setLines(null); // No hay líneas en este gráfico
              setBarKey(null); // No hay barras en este gráfico

              setType(type);
              break;
            case "production-capacity":
              type = "bar-line";
              data = await productionCapacity();

              setChartData(data["chartData"]);
              setLines(null); // No se usa línea en otros reportes
              setBarKey(["pedidosEsteMes", "pedidosMesAnterior"]); // Barras para producción
              setLineKey("variacionUtilizacion"); // Línea negra para producción

              setType(type);
              break;
            default:
              throw new Error("Reporte sintetizado no encontrado");
          }
          setReportData(data["tableData"]);
          setReportColumns(columns);
          setReportTitles(title);
        } else {
          throw new Error("Tipo de reporte inválido");
        }
        // console.log(data["data"][1]);
      } catch (err) {
        setError(`Error al obtener el reporte: ${err.message}`);
      } finally {
        setLoading(false);
      }
    };

    fetchReportData();
  }, [reportName, reportType]);

  // Si está cargando, mostramos un indicador de carga
  if (loading) {
    return (
      <div className="loading-container">
        <p>Cargando reportes...</p>
      </div>
    );
  }

  // Si hay un error, mostramos el mensaje
  if (error) {
    return (
      <div className="error-container">
        <p>{error}</p>
      </div>
    );
  }

  // Si no hay datos después de la carga, mostramos un mensaje de error
  if (!reportData) {
    return (
      <div className="error-container">
        <p>No hay datos disponibles para este reporte.</p>
      </div>
    );
  }

  return (
    <div className="container-reports">
      {reportType === "detailed" ? (
        <DetailedReports
          data={reportData}
          columns={ReportsColumns}
          title={ReportsTitles}
        />
      ) : (
        <SynthetizedReports
          title={ReportsTitles}
          startDate="01 de marzo de 2025"
          endDate="19 de marzo de 2025"
        >
          {(type == "line" || type == "bar-line") && (
            <TableComponent data={reportData} columns={ReportsColumns} />
          )}
          <ChartComponent
            type={type}
            data={chartData}
            dataKey={type === "bar-line" ? "pedidosEsteMes" : "cantidadVendida"}
            barKey={barKey} // Se pasa barKey correctamente
            lineKey={lineKey} // Se pasa lineKey correctamente
            lines={lines} // Se pasa lines correctamente para gráficos de línea
            title={ReportsTitles}
          />
        </SynthetizedReports>
      )}
    </div>
  );
};

export default Reports;
