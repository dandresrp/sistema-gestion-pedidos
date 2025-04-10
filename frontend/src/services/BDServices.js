// Importar datos desde el JSON generado
import data from "../data.json";

const nombres = [
  ...new Set(data.pedidos_pendientes.map((pedido) => pedido.cliente)),
];
// Extrae clientes únicos desde los pedidos pendientes

const pedidosDisponibles = [
  ...new Set(data.pedidos_pendientes.map((pedido) => pedido.detalle_pedido)),
];
// Extrae pedidos únicos desde los pedidos pendientes

// Pedidos realizados por mes
export const completedOrders = async (totalRecords = 500) => {
  return new Promise((resolve) => {
    setTimeout(() => {
      const fakeData = [];

      for (let i = 1; i <= totalRecords; i++) {
        const fechaEntrega =
          data.pedidos_pendientes[i % data.pedidos_pendientes.length]
            .fecha_pedido;
        const cliente = nombres[i % nombres.length];
        const detallePedido = pedidosDisponibles[i % pedidosDisponibles.length];
        const monto =
          parseInt(
            detallePedido
              .match(/\d+/g)
              .reduce((acc, num) => acc + parseInt(num), 0)
          ) * 100;

        fakeData.push({
          fecha: fechaEntrega,
          cliente,
          producto: detallePedido,
          monto: `Lps ${monto}.00`,
          estado: "Entregado",
          metodo_envio: i % 3 === 0 ? "Cargo Express" : "N/A",
        });
      }

      resolve({
        data: fakeData,
        fecha1: "2025-03-01",
        fecha2: "2025-03-10",
      });
    }, 1000);
  });
};

// Pedidos pendientes de entrega
export const pendingOrders = async () => {
  return new Promise((resolve) => {
    setTimeout(() => {
      const formattedData = data.pedidos_pendientes.map((pedido) => ({
        fechaEntrega: pedido.fecha_pedido,
        horaEntrega: pedido.hora_entrega,
        cliente: pedido.cliente,
        producto: pedido.producto,
        cantidad: pedido.cantidad,
        estado: pedido.estado,
      }));

      resolve({ data: formattedData });
    }, 1000);
  });
};

// Reporte de inventario
export const inventoryReport = async () => {
  return new Promise((resolve) => {
    setTimeout(() => {
      const formattedData = data.inventario.map((item) => ({
        id: item.id,
        producto: item.producto,
        entradas: item.entradas,
        salidas: item.salidas,
        stockDisponible: item.stock_disponible, // Asegurar que se envía correctamente
        precio: item.precio,
        total: item.total,
      }));

      resolve({ data: formattedData });
    }, 1000);
  });
};

// Reporte de pedidos retrasados
export const delayedOrders = async () => {
  return new Promise((resolve) => {
    setTimeout(() => {
      const formattedData = data.pedidos_retrasados.map((pedido) => ({
        fechaEstimadaEntrega:
          pedido.fecha_estimada_entrega || "Fecha no disponible",
        horaEstimadaEntrega:
          pedido.hora_estimada_entrega || "Hora no disponible",
        cliente: pedido.cliente || "Cliente desconocido",
        producto: pedido.producto || "Producto no especificado",
        // cantidad: pedido.cantidad || 0,
        estado: pedido.estado || "Estado no disponible",
        tiempoRetraso: pedido.tiempo_retraso || "0 días 0 h",
      }));

      resolve({ data: formattedData });
    }, 1000);
  });
};

// Reporte de pedidos rechazados
export const rejectedOrders = async () => {
  return new Promise((resolve) => {
    setTimeout(() => {
      if (!data || !data.pedidos_rechazados) {
        console.error(
          "❌ Error: `pedidos_rechazados` no está definido en el JSON."
        );
        resolve({ data: [] }); // Evita errores devolviendo un array vacío
        return;
      }

      const formattedData = data.pedidos_rechazados.map((pedido) => ({
        fechaPedido: pedido.fecha_pedido || "Fecha no disponible",
        fechaRechazo: pedido.fecha_rechazo || "Fecha no disponible",
        cliente: pedido.cliente || "Cliente desconocido",
        producto: pedido.producto || "Producto no especificado",
        cantidad: pedido.cantidad || 0,
        motivoRechazo: pedido.motivo || "Motivo no especificado",
      }));

      resolve({ data: formattedData });
    }, 1000);
  });
};

// Reporte de ingresos por mes
export const monthlyIncome = async () => {
  return new Promise((resolve) => {
    setTimeout(() => {
      if (!data || !data.ingresos_mensuales) {
        console.error(
          "❌ Error: `ingresos_mensuales` no está definido en el JSON."
        );
        resolve({ tableData: [], chartData: [], lines: [] }); // Evita fallos devolviendo arrays vacíos
        return;
      }

      // Convertir los datos del JSON en el formato requerido
      const tableData = data.ingresos_mensuales.map((row) => ({
        semana: row.semana || "Semana no disponible",
        marzo: row.marzo || "Lps 0.00",
        febrero: row.febrero || "Lps 0.00",
        enero: row.enero || "Lps 0.00",
      }));

      // Convertir los montos de texto ("Lps 2000.00") a números para el gráfico
      const chartData = tableData
        .filter((row) => row.semana !== "TOTAL") // No incluir la fila TOTAL en el gráfico
        .map((row) => ({
          name: row.semana,
          marzo: parseFloat(row.marzo.replace("Lps ", "").replace(".00", "")),
          febrero: parseFloat(
            row.febrero.replace("Lps ", "").replace(".00", "")
          ),
          enero: parseFloat(row.enero.replace("Lps ", "").replace(".00", "")),
        }));

      // Obtener las claves de los valores numéricos para las líneas del gráfico
      const lineKeys = Object.keys(tableData[0]).filter(
        (key) => key !== "semana"
      );

      // Enviar datos formateados correctamente
      resolve({
        tableData,
        chartData,
        lines: lineKeys,
        fechaReporte: new Date().toISOString().split("T")[0],
      });
    }, 1000);
  });
};

// Reporte de capacidad de producción por mes
export const productionCapacity = async () => {
  return new Promise((resolve) => {
    setTimeout(() => {
      if (!data || !data.capacidad_produccion) {
        console.error(
          "❌ Error: `capacidad_produccion` no está definido en el JSON."
        );
        resolve({ tableData: [], chartData: [], labels: [] }); // Evita fallos devolviendo arrays vacíos
        return;
      }

      // Convertir los datos del JSON en el formato requerido
      const tableData = data.capacidad_produccion.map((row) => ({
        mes: row.mes || "Mes no disponible",
        pedidosEsteMes: row.pedidos_finalizados_este_mes || 0,
        pedidosMesAnterior: row.pedidos_finalizados_mes_anterior || 0,
        variacionUtilizacion:
          parseFloat(row.variacion_utilizacion.replace("%", "")) || 0,
      }));

      // Formatear datos para la gráfica
      const chartData = tableData.map((row) => ({
        name: row.mes,
        pedidosEsteMes: row.pedidosEsteMes,
        pedidosMesAnterior: row.pedidosMesAnterior,
        variacionUtilizacion: row.variacionUtilizacion,
      }));

      const labels = tableData.map((row) => row.mes);

      // Enviar datos formateados correctamente
      resolve({
        tableData,
        chartData,
        labels,
        fechaReporte: new Date().toISOString().split("T")[0],
      });
    }, 1000);
  });
};

// Historial de productos más vendidos
export const fetchTopProductosVendidos = async () => {
  return new Promise((resolve) => {
    setTimeout(() => {
      const productosTop = [
        "Tazas personalizadas",
        "Camisetas sublimadas",
        "Termos personalizados",
        "Llaveros sublimados",
      ];
      const productosOtros = [
        "Fundas para celular",
        "Gorras sublimadas",
        "Mousepads personalizados",
        "Botellas térmicas",
        "Plumas grabadas",
        "Cuadernos personalizados",
      ];

      const fakeData = [];
      let totalOtros = 0;

      // Generar ventas para los 4 productos más vendidos
      productosTop.forEach((producto) => {
        const cantidad = Math.floor(Math.random() * 500) + 500; // Entre 500 y 1000
        fakeData.push({ producto, cantidadVendida: cantidad });
      });

      // Agrupar los otros productos en "Otros"
      productosOtros.forEach(() => {
        totalOtros += Math.floor(Math.random() * 100) + 50; // Entre 100 y 150 cada uno
      });

      // Agregar "Otros" a la lista
      fakeData.push({ producto: "Otros", cantidadVendida: totalOtros });

      // Estructura adecuada para el gráfico de barras
      const chartData = fakeData.map((row) => ({
        name: row.producto,
        cantidadVendida: row.cantidadVendida,
      }));

      // Devolver ambos: tabla y gráfico en un solo resolve()
      resolve({
        tableData: fakeData,
        chartData,
        labels: fakeData.map((row) => {
          row.producto, row.cantidadVendida;
        }), // Etiquetas del eje X
        fechaReporte: new Date().toISOString().split("T")[0],
      });
    }, 1000); // Simula 1s de espera
  });
};
