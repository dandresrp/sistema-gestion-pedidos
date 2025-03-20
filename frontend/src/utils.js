class ReportColumns {
  constructor(reportName) {
    this.reportName = reportName;
    this.columns = {
      "completed-orders": [
        { id: "fecha", header: "Fecha" },
        { id: "cliente", header: "Cliente" },
        { id: "producto", header: "Producto" },
        { id: "monto", header: "Monto" },
        { id: "estado", header: "Estado" },
        {
          id: "metodo_envio",
          header: "Método de Envío",
        },
      ],
      inventory: [
        { id: "id", header: "ID" },
        { id: "producto", header: "Producto" },
        { id: "entradas", header: "Entradas" },
        { id: "salidas", header: "Salidas" },
        { id: "stockDisponible", header: "Stock Disponible" },
        { id: "precio", header: "Precio" },
        { id: "total", header: "Total" },
      ],
      "pending-orders": [
        { id: "fechaEntrega", header: "Fecha de Entrega" },
        { id: "horaEntrega", header: "Hora de Entrega" },
        { id: "cliente", header: "Cliente" },
        { id: "estado", header: "Estado" },
        { id: "producto", header: "Producto" },
        { id: "cantidad", header: "Cantidad" },
      ],
      "delayed-orders": [
        { id: "fechaEstimadaEntrega", header: "Fecha estimada de Entrega" },
        { id: "horaEstimadaEntrega", header: "Hora estimada de Entrega" },
        { id: "cliente", header: "Cliente" },
        { id: "producto", header: "Producto" },
        // { id: "cantidad", header: "Cantidad" },
        { id: "estado", header: "Estado" },
        { id: "tiempoRetraso", header: "Tiempo de retraso" },
      ],
      "rejected-orders": [
        { id: "fechaPedido", header: "Fecha del Pedido" },
        { id: "fechaRechazo", header: "Fecha del Rechazo" },
        { id: "cliente", header: "Cliente" },
        { id: "producto", header: "Producto" },
        { id: "cantidad", header: "Cantidad" },
        { id: "motivoRechazo", header: "Motivo de rechazo" },
      ],
      "monthly-income": [
        { id: "semana", header: "Semana del mes" },
        { id: "marzo", header: "MARZO" },
        { id: "febrero", header: "FEBRERO" },
        { id: "enero", header: "ENERO" },
      ],
      "best-selling-products": [
        { id: "producto", header: "Producto" },
        { id: "cantidad", header: "Cantidad" },
      ],
      "production-capacity": [
        { id: "mes", header: "Mes" },
        { id: "pedidosEsteMes", header: "Pedidos Finalizados Este Mes" },
        {
          id: "pedidosMesAnterior",
          header: "Pedidos Finalizados Mes Anterior",
        },
        { id: "variacionUtilizacion", header: "% de Variación de Utilización" },
      ],
    };
  }

  getColumns() {
    return this.columns[this.reportName] || [];
  }
}

export default ReportColumns;

export const ReportTitles = {
  "completed-orders": "PEDIDOS REALIZADOS EN EL MES",
  "pending-orders": "PEDIDOS PENDIENTES",
  inventory: "REPORTE DE INVENTARIO",
  "delayed-orders": "PEDIDOS QUE EXCEDIERON EL TIEMPO DE ENTREGA",
  "monthly-income": "INGRESOS POR MES",
  "rejected-orders": "PEDIDOS RECHAZADOS",
  "best-selling-products": "PRODUCTOS MÁS VENDIDOS",
  "production-capacity": "CAPACIDAD DE PRODUCCIÓN",
};
