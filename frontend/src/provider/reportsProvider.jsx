const generateReportData = (count) => {
  const data = [];
  const estados = ["Completado", "Pendiente", "Cancelado", "En proceso"];
  const clientes = [
    "Empresa ABC",
    "Corporación XYZ",
    "Industrias 123",
    "Servicios Técnicos",
    "Distribuidora Nacional",
    "Comercial Express",
    "Tecnología Avanzada",
    "Consultores Asociados",
    "Manufacturas Globales",
  ];

  for (let i = 1; i <= count; i++) {
    const randomDay = Math.floor(Math.random() * 30) + 1;
    const randomMonth = Math.floor(Math.random() * 12) + 1;
    const fecha = `2023-${randomMonth.toString().padStart(2, "0")}-${randomDay
      .toString()
      .padStart(2, "0")}`;

    const randomClienteIndex = Math.floor(Math.random() * clientes.length);
    const randomEstadoIndex = Math.floor(Math.random() * estados.length);
    const randomMonto = (Math.random() * 5000 + 500).toFixed(2);

    data.push({
      fecha: fecha,
      cliente: clientes[randomClienteIndex],
      producto: "Producto " + ((i % 10) + 1),
      monto: `$${randomMonto}`,
      estado: estados[randomEstadoIndex],
      metodoDeEnvio: "Enviado",
    });
  }
  console.log(data[1]);
  return data;
};

export default generateReportData;
