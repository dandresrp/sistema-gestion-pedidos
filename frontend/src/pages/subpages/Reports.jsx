import { useParams } from "react-router-dom";
import { useEffect, useState, useCallback } from "react";
import { reportController } from "../../controllers/reportController";
import DetailedReports from "../../components/DetailedReports";
import SynthetizedReports from "../../components/SynthetizedReports";
import ReportColumns, { ReportTitles } from "../../utils";
import ChartComponent from "../../components/ChartComponent";
import TableComponent from "../../components/TableComponent";
import DatePicker, { registerLocale } from "react-datepicker";
import { monthlyIncome } from "../../services/BDServices";
import es from "date-fns/locale/es";
import "react-datepicker/dist/react-datepicker.css";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faChevronDown, faChevronUp } from "@fortawesome/free-solid-svg-icons";
import { forwardRef } from "react";

const CustomDateInput = forwardRef(({ value, onClick, isOpen }, ref) => (
  <button className="custom-date-button" onClick={onClick} ref={ref}>
    {value}
    <FontAwesomeIcon
      icon={isOpen ? faChevronUp : faChevronDown}
      className="calendar-icon"
    />
  </button>
));

registerLocale("es", es);

const getFirstDayOfMonth = () => {
  const date = new Date();
  return new Date(date.getFullYear(), date.getMonth(), 1);
};

const getToday = () => new Date();

// const formatDisplayDate = (date) => {
//   return date.toLocaleDateString("es-ES", {
//     day: "2-digit",
//     month: "long",
//     year: "numeric",
//   });
// };

const getMonthYear = (date) => {
  const mes = date.toLocaleDateString("es-ES", { month: "long" });
  const año = date.getFullYear();
  return `${mes.toUpperCase()} DE ${año}`;
};

const getFormattedDateLong = (date) => {
  return date.toLocaleDateString("es-ES", {
    day: "numeric",
    month: "long",
    year: "numeric",
  });
};

const getDynamicTitle = (reportName, endDate) => {
  if (reportName === "completed-orders") {
    return `PEDIDOS REALIZADOS EN ${getMonthYear(endDate)}`;
  }
  if (reportName === "inventory") {
    return `INVENTARIO AL ${getFormattedDateLong(endDate).toUpperCase()}`;
  }

  return ReportTitles[reportName] || "REPORTE";
};

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
  const [startDate, setStartDate] = useState(getFirstDayOfMonth());
  const [endDate, setEndDate] = useState(getToday());
  const [isStartOpen, setIsStartOpen] = useState(false);
  const [isEndOpen, setIsEndOpen] = useState(false);

  // useEffect(() => {
  //   setLoading(true);
  //   setError(null);

  const fetchReportData = useCallback(
    async (options = { skipLoading: false }) => {
      try {
        if (!options.skipLoading) setLoading(true);
        setError(null);

        // if (startDate > endDate) {
        //   throw new Error("La fecha de inicio no puede ser mayor a la fecha final");
        // }
        let type;
        let data;
        let columns = new ReportColumns(reportName).getColumns();
        let title = getDynamicTitle(reportName, endDate);

        // const startDate = getFirstDayOfMonth();
        // const endDate = getToday();
        const offset = 0;
        const limit = 1000;

        if (reportType === "detailed") {
          switch (reportName) {
            case "completed-orders": {
              const res = await reportController.getOrdersByMonth(
                startDate.toISOString().split("T")[0],
                endDate.toISOString().split("T")[0],
                offset,
                limit
              );
              if (!res.success) throw new Error(res.message);

              data = {
                data: res.data.map((order) => ({
                  fecha: new Date(order.fecha).toLocaleDateString(),
                  cliente: order.nombre_cliente,
                  producto: order.productos,
                  monto: parseFloat(order.total || 0).toFixed(2),
                  estado: order.estado,
                  metodo_envio: order.metodo_envio,
                })),
              };
              break;
            }

            case "pending-orders": {
              const res = await reportController.getPendingOrders(
                startDate.toISOString().split("T")[0],
                endDate.toISOString().split("T")[0],
                offset,
                limit
              );
              if (!res.success) throw new Error(res.message);

              data = {
                data: res.data.map((order) => ({
                  fechaEntrega: new Date(
                    order.fecha_estimada_entrega
                  ).toLocaleDateString(),
                  horaEntrega: order.hora_estimada_entrega,
                  cliente: order.nombre_cliente,
                  estado: order.estado,
                  producto: order.productos,
                  cantidad: order.cantidad_total_productos,
                })),
              };
              break;
            }

            case "inventory": {
              const res = await reportController.getInventory();
              if (!res.success) throw new Error(res.message);

              // const sorted = res.data.sort(
              //   (a, b) => a.stock_disponible - b.stock_disponible
              // );

              data = {
                data: res.data.map((item) => ({
                  producto: `${item.nombre_producto} ${item.especificaciones}`,
                  entradas: item.stock + 10,
                  salidas: item.stock - 10,
                  stockDisponible: item.stock,
                  precio: parseFloat(item.precio_total - 50 || 0).toFixed(2),
                  total: parseFloat(item.precio_total || 0).toFixed(2),
                })),
              };
              break;
            }

            case "delayed-orders": {
              const res = await reportController.getOrdersOutOfTime(
                startDate.toISOString().split("T")[0],
                endDate.toISOString().split("T")[0],
                offset,
                limit
              );
              if (!res.success) throw new Error(res.message);

              data = {
                data: res.data.map((order) => ({
                  fechaEstimadaEntrega: new Date(
                    order.fecha_estimada_entrega
                  ).toLocaleDateString(),
                  horaEstimadaEntrega: order.hora_estimada_entrega,
                  cliente: order.cliente,
                  producto: order.productos,
                  estado: order.estado,
                  tiempoRetraso: `${order.tiempo_retraso} h`,
                })),
              };
              break;
            }

            case "rejected-orders": {
              const res = await reportController.getRejectedOrders(
                startDate.toISOString().split("T")[0],
                endDate.toISOString().split("T")[0],
                offset,
                limit
              );
              if (!res.success) throw new Error(res.message);

              data = {
                data: res.data.map((order) => ({
                  fechaPedido: new Date(
                    order.fecha_del_pedido
                  ).toLocaleDateString(),
                  fechaRechazo: new Date(
                    order.fecha_de_rechazo
                  ).toLocaleDateString(),
                  cliente: order.cliente,
                  producto: order.productos,
                  cantidad: order.cantidad,
                  motivoRechazo: order.notas || "No especificado",
                })),
              };
              break;
            }

            default:
              throw new Error("Reporte no encontrado");
          }

          setReportData(data.data);
          setReportColumns(columns);
          setReportTitles(title);
        } else if (reportType === "synthetized") {
          const adjustedStart = new Date(
            startDate.getFullYear(),
            startDate.getMonth(),
            1
          );
          const adjustedEnd = new Date(
            endDate.getFullYear(),
            endDate.getMonth() + 1,
            0
          );

          switch (reportName) {
            case "monthly-income":
              type = "line";
              data = await monthlyIncome();
              setChartData(data["chartData"]);
              setLines(data["lines"]);
              setBarKey(null); // No hay barras en este gráfico

              setType(type);
              break;

            case "best-selling-products": {
              type = "pie";
              const res = await reportController.getBestSellingProductsHistory(
                adjustedStart.toISOString().split("T")[0],
                adjustedEnd.toISOString().split("T")[0]
              );
              if (!res.success) throw new Error(res.message);

              const total = res.data.reduce(
                (acc, item) => acc + parseInt(item.total_vendido),
                0
              );

              const productData = res.data.map((item) => ({
                producto: item.producto,
                cantidad: parseInt(item.total_vendido),
                porcentaje: parseFloat((item.total_vendido / total) * 100),
              }));

              setChartData(
                productData.map((item) => ({
                  name: item.producto,
                  cantidadVendida: parseFloat(item.porcentaje.toFixed(2)),
                }))
              );
              setType(type);
              data = { tableData: productData };
              break;
            }

            case "production-capacity": {
              type = "line2";
              const res = await reportController.getProductionCapacity();
              if (!res.success) throw new Error(res.message);

              const capacityData = res.data.map((item) => ({
                mes: item.mes,
                pedidosEsteMes: parseInt(item.pedidos_mes_actual),
                pedidosMesAnterior: parseInt(item.pedidos_mes_anterior),
                variacionUtilizacion: parseFloat(item.porcentaje_variacion),
              }));

              setChartData(capacityData);
              setLines(["variacionUtilizacion"]);
              setType(type);
              data = { tableData: capacityData };
              break;
            }

            default:
              throw new Error("Reporte no encontrado");
          }

          setReportData(data.tableData);
          setReportColumns(columns);
          setReportTitles(title);
        } else {
          throw new Error("Tipo de reporte inválido");
        }
      } catch (err) {
        setError(`Error al obtener el reporte: ${err.message}`);
      } finally {
        if (!options.skipLoading) setLoading(false);
      }
    },
    [reportName, reportType, startDate, endDate]
  );

  useEffect(() => {
    fetchReportData();
  }, [fetchReportData]);

  useEffect(() => {
    fetchReportData({ skipLoading: true });
  }, [fetchReportData]);

  if (loading && !reportData) {
    return (
      <div
        className="loading-container"
        style={{ textAlign: "center", padding: "2rem" }}
      >
        <div className="loader"></div>
        <p style={{ marginTop: "1rem", color: "#3498db" }}>
          Cargando reportes...
        </p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="error-container">
        <p>{error}</p>
      </div>
    );
  }

  if (!reportData) {
    return (
      <div className="error-container">
        <p>No hay datos para mostrar...</p>
      </div>
    );
  }

  return (
    <div className="container-reports">
      {reportType === "detailed" ? (
        <>
          <DetailedReports
            data={reportData}
            columns={ReportsColumns}
            title={ReportsTitles}
            date1={
              reportName !== "inventory" && (
                <DatePicker
                  selected={startDate}
                  onChange={setStartDate}
                  dateFormat="dd 'de' MMMM 'de' yyyy"
                  locale="es"
                  onCalendarOpen={() => setIsStartOpen(true)}
                  onCalendarClose={() => setIsStartOpen(false)}
                  customInput={<CustomDateInput isOpen={isStartOpen} />}
                  popperPlacement="bottom-start"
                />
              )
            }
            date2={
              reportName !== "inventory" && (
                <DatePicker
                  selected={endDate}
                  onChange={setEndDate}
                  dateFormat="dd 'de' MMMM 'de' yyyy"
                  locale="es"
                  onCalendarOpen={() => setIsEndOpen(true)}
                  onCalendarClose={() => setIsEndOpen(false)}
                  customInput={<CustomDateInput isOpen={isEndOpen} />}
                  popperPlacement="bottom-start"
                />
              )
            }
          />
        </>
      ) : (
        <SynthetizedReports
          title={ReportsTitles}
          date1={
            <DatePicker
              selected={startDate}
              onChange={setStartDate}
              dateFormat="MMMM yyyy"
              showMonthYearPicker
              locale="es"
              onCalendarOpen={() => setIsStartOpen(true)}
              onCalendarClose={() => setIsStartOpen(false)}
              customInput={<CustomDateInput isOpen={isStartOpen} />}
              popperPlacement="bottom-start"
            />
          }
          date2={
            <DatePicker
              selected={endDate}
              onChange={setEndDate}
              dateFormat="MMMM yyyy"
              showMonthYearPicker
              locale="es"
              onCalendarOpen={() => setIsEndOpen(true)}
              onCalendarClose={() => setIsEndOpen(false)}
              customInput={<CustomDateInput isOpen={isEndOpen} />}
              popperPlacement="bottom-start"
            />
          }
        >
          {["line", "line2", "pie"].includes(type) && (
            <TableComponent data={reportData} columns={ReportsColumns} />
          )}
          <ChartComponent
            type={type}
            data={chartData}
            dataKey={type === "line2" ? "pedidosEsteMes" : "cantidadVendida"}
            barKey={barKey}
            lineKey={lineKey}
            lines={lines}
            title={ReportsTitles}
          />
        </SynthetizedReports>
      )}
    </div>
  );
};

export default Reports;
