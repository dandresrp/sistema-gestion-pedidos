import { useState } from "react";
import DatePicker, { registerLocale } from "react-datepicker";
import es from "date-fns/locale/es";
import "react-datepicker/dist/react-datepicker.css";
import "../styles/CreateOrder.css";

registerLocale("es", es);

function CreateOrder({ onClose, onSubmit, showToast }) {
  const [pedido, setPedido] = useState({
    id_cliente: "",
    id_usuario_recepcion: "",
    total: "",
    notas: "",
    metodo_envio: "",
    fecha_estimada_entrega: new Date(Date.now() + 86400000),
    hora_estimada_entrega: "",
  });

  const [usuarios] = useState([
    { id_usuario: 1, nombre_usuario: "Lucía Gómez" },
    { id_usuario: 2, nombre_usuario: "Carlos Ramírez" },
    { id_usuario: 3, nombre_usuario: "Ana Torres" },
    { id_usuario: 4, nombre_usuario: "Jorge Paredes" },
  ]);

  const [clientes] = useState([
    { id_usuario: 1, nombre_usuario: "Helena Rodríguez" },
    { id_usuario: 2, nombre_usuario: "Carlos Vasquez" },
    { id_usuario: 3, nombre_usuario: "Adely Tosi" },
    { id_usuario: 4, nombre_usuario: "Chiva Coquein" },
    { id_usuario: 5, nombre_usuario: "Leticia García" },
    { id_usuario: 6, nombre_usuario: "María Rodríguez" },
    { id_usuario: 7, nombre_usuario: "Juan Gómez" },
    { id_usuario: 8, nombre_usuario: "Sofía Sánchez" },
    { id_usuario: 9, nombre_usuario: "Pablo López" },
    { id_usuario: 10, nombre_usuario: "María Díaz" },
    { id_usuario: 11, nombre_usuario: "Cristina Sánchez" },
    { id_usuario: 12, nombre_usuario: "Jesús Pérez" },
    { id_usuario: 13, nombre_usuario: "María Gómez" },
    { id_usuario: 14, nombre_usuario: "Juan Carlos Sánchez" },
    { id_usuario: 15, nombre_usuario: "María Elena Rodríguez" },
    { id_usuario: 16, nombre_usuario: "Jorge Luis Gómez" },
    { id_usuario: 17, nombre_usuario: "María del Carmen López" },
    { id_usuario: 18, nombre_usuario: "Juan Antonio Díaz" },
    { id_usuario: 19, nombre_usuario: "María de los Ángeles Sánchez" },
    { id_usuario: 20, nombre_usuario: "Jorge Alberto Gómez" },
  ]);

  const [productosPedido, setProductosPedido] = useState([]);
  const [productoActual, setProductoActual] = useState({
    producto: "Camisa",
    cantidad: "1",
  });

  const [productoEsp, setProductoEsp] = useState({
    talla: "S",
    color: "Verde",
    estilo: "Normal",
    forma: "Corazon",
    material: "Metal",
  });

  const handleChange = (e) => {
    const { name, value } = e.target;
    setPedido({ ...pedido, [name]: value });
  };

  const handleProductoChange = (e) => {
    const { name, value } = e.target;
    setProductoActual({ ...productoActual, [name]: value });

    setProductoEsp({
      talla: "S",
      color: "Verde",
      estilo: "Normal",
      forma: "Corazon",
      material: "Metal",
    });
  };

  const handleEspChange = (e) => {
    const { name, value } = e.target;
    setProductoEsp({ ...productoEsp, [name]: value });
  };

  const agregarProducto = () => {
    const cantidadNum = Number(productoActual.cantidad);

    if (
      !productoActual.producto ||
      !productoActual.cantidad ||
      isNaN(cantidadNum) ||
      cantidadNum <= 0
    ) {
      showToast(
        "Debe ingresar un producto válido y cantidad numérica",
        "error"
      );
      return;
    }

    setProductosPedido([
      ...productosPedido,
      {
        producto: productoActual.producto,
        cantidad: cantidadNum,
        esp: productoEsp,
      },
    ]);

    setProductoEsp({
      talla: "S",
      color: "Verde",
      estilo: "Normal",
      forma: "Corazon",
      material: "Metal",
    });

    setProductoActual({ producto: "Camisa", cantidad: "1" });
  };

  const handleSubmit = (e) => {
    e.preventDefault();

    const hayProductosEnLista = productosPedido.length > 0;

    if (!hayProductosEnLista) {
      showToast("Debe agregar al menos un producto al pedido", "error");
      return;
    }

    if (!hayProductosEnLista) {
      showToast(
        "Hay un producto en los campos que no fue agregado. Presiona + o limpia los campos.",
        "error"
      );
      return;
    }

    if (pedido.notas && pedido.notas.length > 140) {
      showToast("Las notas no pueden superar los 140 caracteres.", "error");
      return;
    }

    const now = new Date();
    const isoFecha = now.toISOString();
    const hoy = now.toISOString().split("T")[0];

    const pedidoCompleto = {
      ...pedido,
      productos: productosPedido,
      fecha_creacion: isoFecha,
      fecha_modificacion: isoFecha,
      fecha_finalizacion: null,
      estado: "creado",
      fecha_estimada_entrega: pedido.fecha_estimada_entrega
        ? pedido.fecha_estimada_entrega.toISOString().split("T")[0]
        : hoy,
      hora_estimada_entrega: pedido.hora_estimada_entrega,
    };

    onSubmit(pedidoCompleto);
    onClose();

    setProductoActual({ producto: "", cantidad: "" });
    setProductosPedido([]);
  };

  const validTime = () => {
    const horas = [];
    for (let h = 8; h < 17; h++) {
      ["00", "30"].forEach((min) => {
        const hora = `${h.toString().padStart(2, "0")}:${min}`;
        horas.push(hora);
      });
    }
    horas.push("17:00");
    return horas;
  };

  return (
    <div className="modal-overlay">
      <div className="create-order-modal">
        <div className="modal-header">
          <h2>Agregar Pedido</h2>

          <form className="create-order-form" onSubmit={handleSubmit}>
            <div className="form-sections">
              <div className="form-info-1">
                <div className="form-row">
                  <label>Nombre del Cliente: </label>
                  <select
                    name="id_cliente"
                    value={pedido.id_cliente}
                    onChange={handleChange}
                    required
                  >
                    {clientes.map((cliente) => (
                      <option
                        key={cliente.id_cliente}
                        value={cliente.id_usuario}
                      >
                        {cliente.nombre_usuario}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="form-row">
                  <label>Recepción a cargo de: </label>
                  <select
                    name="id_usuario_recepcion"
                    value={pedido.id_usuario_recepcion}
                    onChange={handleChange}
                    required
                  >
                    {usuarios.map((usuario) => (
                      <option
                        key={usuario.id_usuario}
                        value={usuario.id_usuario}
                      >
                        {usuario.nombre_usuario}
                      </option>
                    ))}
                  </select>
                </div>

                <div
                  style={{
                    display: "flex",
                    flexDirection: "column",
                    alignItems: "end",
                  }}
                >
                  <div className="form-row">
                    <label>Notas: </label>
                    <textarea
                      name="notas"
                      value={pedido.notas}
                      onChange={handleChange}
                      maxLength={100}
                    ></textarea>
                  </div>
                  <div
                    className={`char-counter ${
                      pedido.notas.length > 100 ? "over-limit" : ""
                    }`}
                  >
                    {pedido.notas.length}/100 caracteres
                  </div>
                </div>

                <div className="form-row">
                  <label>Método de Envío: </label>
                  <select
                    name="metodo_envio"
                    value={pedido.metodo_envio}
                    onChange={handleChange}
                    required
                  >
                    <option value="Cargo Express">Cargo Express</option>
                    <option value="N/A">N/A</option>
                  </select>
                </div>

                <div className="form-row">
                  <label>Fecha estimada de entrega: </label>
                  <DatePicker
                    selected={pedido.fecha_estimada_entrega}
                    onChange={(date) =>
                      setPedido({ ...pedido, fecha_estimada_entrega: date })
                    }
                    dateFormat="dd/MM/yy"
                    locale="es"
                    placeholderText=""
                    className="datepicker"
                    required
                    shouldCloseOnSelect={true}
                  />
                </div>

                <div className="form-row">
                  <label>Hora estimada de entrega: </label>
                  <select
                    name="hora_estimada_entrega"
                    value={pedido.hora_estimada_entrega}
                    onChange={handleChange}
                    required
                  >
                    {validTime().map((hora) => (
                      <option key={hora} value={hora}>
                        {hora}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="form-info">
                <div className="form-row">
                  <label>Producto: </label>
                  <select
                    name="producto"
                    value={productoActual.producto}
                    onChange={handleProductoChange}
                  >
                    {["Camisa", "Gorra", "Llavero", "Taza"].map((item) => (
                      <option key={item} value={item}>
                        {item}
                      </option>
                    ))}
                  </select>
                </div>
                <div className="form-row">
                  <label>Cantidad: </label>
                  <input
                    type="number"
                    name="cantidad"
                    value={productoActual.cantidad}
                    onChange={handleProductoChange}
                    onKeyDown={(e) => {
                      const isLetter =
                        e.key.length === 1 &&
                        !/[0-9]/.test(e.key) &&
                        !e.ctrlKey &&
                        !e.metaKey;
                      if (isLetter) {
                        e.preventDefault();
                        showToast("Solo se permiten números", "error");
                      }
                    }}
                    min="1"
                    step="1"
                  />
                </div>
                {/*----------------------------------------------------------- */}
                {productoActual.producto === "Camisa" ||
                productoActual.producto === "Gorra" ? (
                  <div style={{ display: "flex", width: "55%", gap: "1rem" }}>
                    {productoActual.producto === "Camisa" ? (
                      <div className="form-row">
                        <label>Talla </label>
                        <select
                          name="talla"
                          value={productoEsp.talla}
                          onChange={handleEspChange}
                        >
                          <option disabled>Seleccione una talla</option>
                          {["S", "M", "X", "L", "XXL"].map((item) => (
                            <option key={item} value={item}>
                              {item}
                            </option>
                          ))}
                        </select>
                      </div>
                    ) : null}

                    <div className="form-row">
                      <label>Color </label>
                      <select
                        name="color"
                        value={productoEsp.color}
                        onChange={handleEspChange}
                      >
                        {["Verde", "Azul", "Negro", "Blanco", "Rojo"].map(
                          (item) => (
                            <option key={item} value={item}>
                              {item}
                            </option>
                          )
                        )}
                      </select>
                    </div>
                  </div>
                ) : null}
                {productoActual.producto === "Taza" ? (
                  <div className="form-row">
                    <label>Estilo </label>
                    <select
                      name="Estilo"
                      value={productoEsp.estilo}
                      onChange={handleEspChange}
                    >
                      {["Normal", "Magico"].map((item) => (
                        <option key={item} value={item}>
                          {item}
                        </option>
                      ))}
                    </select>
                  </div>
                ) : null}
                {productoActual.producto === "Llavero" ? (
                  <div style={{ display: "flex", width: "55%", gap: "1rem" }}>
                    <div className="form-row">
                      <label>Forma </label>
                      <select
                        name="forma"
                        value={productoEsp.forma}
                        onChange={handleEspChange}
                      >
                        {["Corazon", "Circular", "Rectangular"].map((item) => (
                          <option key={item} value={item}>
                            {item}
                          </option>
                        ))}
                      </select>
                    </div>
                    <div className="form-row">
                      <label>Material </label>
                      <select
                        name="material"
                        value={productoEsp.material}
                        onChange={handleEspChange}
                      >
                        {["Metal", "Plastico", "Madera"].map((item) => (
                          <option key={item} value={item}>
                            {item}
                          </option>
                        ))}
                      </select>
                    </div>
                  </div>
                ) : null}

                {/*----------------------------------------------------------- */}
                <div className="add-item-container">
                  <button
                    type="button"
                    onClick={agregarProducto}
                    className="add-item-button"
                  >
                    +
                  </button>
                </div>
                <div className="product-list">
                  {productosPedido.length > 0 && (
                    <ul>
                      {productosPedido.map((item, index) => (
                        <li key={index}>
                          {item.producto} - {item.cantidad} -{" "}
                          {Object.entries(item.esp)
                            .filter(([key, value]) => {
                              // Solo mostrar las especificaciones que sean relevantes para el producto
                              if (item.producto === "Gorra" && key === "talla")
                                return false;
                              if (
                                item.producto === "Camisa" &&
                                (key === "estilo" ||
                                  key === "forma" ||
                                  key === "material")
                              )
                                return false;
                              if (
                                item.producto === "Taza" &&
                                (key === "talla" ||
                                  key === "color" ||
                                  key === "forma" ||
                                  key === "material")
                              )
                                return false;
                              if (
                                item.producto === "Llavero" &&
                                (key === "talla" ||
                                  key === "color" ||
                                  key === "estilo")
                              )
                                return false;

                              // Mostrar solo especificaciones que no estén vacías
                              return value !== "";
                            })
                            .map(([key, value]) => `${key}: ${value}`)
                            .join(", ")}
                        </li>
                      ))}
                    </ul>
                  )}
                </div>
              </div>
            </div>
            <div className="modal-actions">
              <button type="submit" className="guardar-button">
                Guardar Pedido
              </button>

              <button
                type="button"
                onClick={onClose}
                className="cancelar-button"
              >
                Cancelar
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}

export default CreateOrder;
