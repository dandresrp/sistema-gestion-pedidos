import { useParams } from "react-router-dom";
import { useEffect, useState } from "react";
// import {
//   completedOrders,
//   pendingOrders,
//   inventoryReport,
//   delayedOrders,
//   rejectedOrders,
//   monthlyIncome,
//   fetchTopProductosVendidos,
//   productionCapacity,
// } from "../../services/BDServices";
import { reportController } from "../../controllers/reportController";
import DetailedReports from "../../components/DetailedReports";
import SynthetizedReports from "../../components/SynthetizedReports";
import ReportColumns, { ReportTitles } from "../../utils";
import ChartComponent from "../../components/ChartComponent";
import TableComponent from "../../components/TableComponent";

const getFirstDayOfMonth = () => {
  const date = new Date();
  return new Date(date.getFullYear(), date.getMonth(), 1)
    .toISOString()
    .split("T")[0];
};

const getToday = () => {
  return new Date().toISOString().split("T")[0];
};

const formatDisplayDate = (dateStr) => {
  const date = new Date(dateStr);
  return date.toLocaleDateString("es-ES", {
    day: "2-digit",
    month: "long",
    year: "numeric",
  });
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

  useEffect(() => {
    setLoading(true);
    setError(null);

    const fetchReportData = async () => {
      try {
        let type;
        let data;
        let columns = new ReportColumns(reportName).getColumns();
        let title = ReportTitles[reportName];

        const startDate = getFirstDayOfMonth();
        const endDate = getToday();
        const offset = 0;
        const limit = 1000;

        if (reportType === "detailed") {
          switch (reportName) {
            case "completed-orders": {
              const ordersResponse = await reportController.getOrdersByMonth(
                startDate,
                endDate,
                offset,
                limit
              );
              if (!ordersResponse.success)
                throw new Error(ordersResponse.message);

              data = {
                data: ordersResponse.data.map((order) => ({
                  fecha: new Date(order.fecha).toLocaleDateString(),
                  cliente: order.nombre_cliente,
                  producto: order.productos,
                  monto: order.total,
                  estado: order.estado,
                  metodo_envio: order.metodo_envio,
                })),
              };
              break;
            }

            case "pending-orders": {
              const pendingResponse = await reportController.getPendingOrders(
                startDate,
                endDate,
                offset,
                limit
              );
              if (!pendingResponse.success)
                throw new Error(pendingResponse.message);

              data = {
                data: pendingResponse.data.map((order) => ({
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
              const inventoryResponse = await reportController.getInventory();
              if (!inventoryResponse.success)
                throw new Error(inventoryResponse.message);

              data = {
                data: inventoryResponse.data.map((item) => ({
                  id: item.id || "N/A",
                  producto: item.nombre_producto,
                  entradas: item.entradas,
                  salidas: item.salidas,
                  stockDisponible: item.stock_disponible,
                  precio: item.precio_individual,
                  total: item.total,
                })),
              };
              break;
            }

            case "delayed-orders": {
              const delayedResponse = await reportController.getOrdersOutOfTime(
                startDate,
                endDate,
                offset,
                limit
              );
              if (!delayedResponse.success)
                throw new Error(delayedResponse.message);

              data = {
                data: delayedResponse.data.map((order) => ({
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
              const rejectedResponse = await reportController.getRejectedOrders(
                startDate,
                endDate,
                offset,
                limit
              );
              if (!rejectedResponse.success)
                throw new Error(rejectedResponse.message);

              data = {
                data: rejectedResponse.data.map((order) => ({
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
              throw new Error("Reporte detallado no encontrado");
          }

          setReportData(data.data);
          setReportColumns(columns);
          setReportTitles(title);
        } else if (reportType === "synthetized") {
          switch (reportName) {
            case "monthly-income": {
              type = "line";
              const incomeResponse = await reportController.getIncomeByMonth(
                startDate,
                endDate
              );
              if (!incomeResponse.success)
                throw new Error(incomeResponse.message);

              const tableData = incomeResponse.data.map((row) => ({
                semana: row.semana,
                marzo: `Lps ${parseFloat(row.mes_actual || 0).toFixed(2)}`,
                febrero: `Lps ${parseFloat(row.mes_pasado || 0).toFixed(2)}`,
                enero: `Lps ${parseFloat(row.mes_antepasado || 0).toFixed(2)}`,
              }));

              const chartData = tableData
                .filter((row) => row.semana !== "Total")
                .map((row) => ({
                  name: row.semana,
                  marzo: parseFloat(row.marzo.replace("Lps ", "")),
                  febrero: parseFloat(row.febrero.replace("Lps ", "")),
                  enero: parseFloat(row.enero.replace("Lps ", "")),
                }));

              setChartData(chartData);
              setLines(["marzo", "febrero", "enero"]);
              setBarKey(null);
              setType(type);
              data = { tableData };
              break;
            }

            case "best-selling-products": {
              type = "pie";
              const productsResponse =
                await reportController.getBestSellingProductsHistory(
                  startDate,
                  endDate
                );
              if (!productsResponse.success)
                throw new Error(productsResponse.message);

              const productData = productsResponse.data.map((item) => ({
                producto: item.producto,
                cantidadVendida: parseInt(item.total_vendido),
                porcentaje: parseFloat(item.porcentaje),
              }));

              setChartData(
                productData.map((item) => ({
                  name: item.producto,
                  cantidadVendida: item.cantidadVendida,
                }))
              );
              setType(type);
              data = { tableData: productData };
              break;
            }

            case "production-capacity": {
              type = "bar-line";
              const capacityResponse =
                await reportController.getProductionCapacity();
              if (!capacityResponse.success)
                throw new Error(capacityResponse.message);

              const capacityData = capacityResponse.data.map((item) => ({
                mes: item.mes,
                pedidosEsteMes: parseInt(item.pedidos_mes_actual),
                pedidosMesAnterior: parseInt(item.pedidos_mes_anterior),
                variacionUtilizacion: parseFloat(item.porcentaje_variacion),
              }));

              setChartData(capacityData);
              setBarKey(["pedidosEsteMes", "pedidosMesAnterior"]);
              setLineKey("variacionUtilizacion");
              setType(type);
              data = { tableData: capacityData };
              break;
            }

            default:
              throw new Error("Reporte sintetizado no encontrado");
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
        setLoading(false);
      }
    };

    fetchReportData();
  }, [reportName, reportType]);

  if (loading) {
    return (
      <div className="loading-container">
        <p>Cargando reportes...</p>
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
          date1={formatDisplayDate(getFirstDayOfMonth())}
          date2={formatDisplayDate(getToday())}
        />
      ) : (
        <SynthetizedReports
          title={ReportsTitles}
          startDate={formatDisplayDate(getFirstDayOfMonth())}
          endDate={formatDisplayDate(getToday())}
        >
          {(type == "line" || type == "bar-line") && (
            <TableComponent data={reportData} columns={ReportsColumns} />
          )}
          <ChartComponent
            type={type}
            data={chartData}
            dataKey={type === "bar-line" ? "pedidosEsteMes" : "cantidadVendida"}
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
