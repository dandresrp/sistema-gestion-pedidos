import React, { useState, useEffect } from "react";
import "../../styles/orders.css";
import CreateOrder from "../../components/CreateOrder";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faMagnifyingGlass, faTrash } from "@fortawesome/free-solid-svg-icons";

export default function Orders() {
  const [orders, setOrders] = useState([]);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("todos");
  const [selectedOrder, setSelectedOrder] = useState(null);
  const [editedStatus, setEditedStatus] = useState("");
  const [editedProducts, setEditedProducts] = useState([]);
  const [editedMetodoEnvio, setEditedMetodoEnvio] = useState("");

  const [toastMessage, setToastMessage] = useState("");
  const [toastTipo, setToastTipo] = useState("exito");
  const [isToastVisible, setIsToastVisible] = useState(false);
  const [orderToDelete, setOrderToDelete] = useState(null);

  const [showModal, setShowModal] = useState(false);

  const [currentPage, setCurrentPage] = useState(1);
  const recordsPerPage = 10;

  const statuses = ["en espera", "creado", "en proceso", "enviado"];
  const metodoEnvioOptions = ["Cargo Express", "N/A"];

  useEffect(() => {
    const baseOrders = [
      {
        client: "Juan Pérez",
        total: 100,
        status: "en espera",
        date: "2025-04-01T10:00:00Z",
        entrega: "2025-04-08",
        usuario: "Lucía Gómez",
        metodo_envio: "Cargo Express",
        details: [
          { name: "Mousepad RGB", quantity: 2, price: 30 },
          { name: "Cable USB-C", quantity: 1, price: 40 },
        ],
      },
      {
        client: "Laura Gómez",
        total: 200,
        status: "en proceso",
        date: "2025-04-03T16:30:00Z",
        entrega: "2025-04-10",
        usuario: "Carlos Ramírez",
        metodo_envio: "N/A",
        details: [{ name: "Teclado Mecánico", quantity: 1, price: 200 }],
      },
    ];

    const generated = [];
    for (let i = 0; i < 25; i++) {
      const base = baseOrders[i % baseOrders.length];
      generated.push({
        ...base,
        id: i + 1,
        client: `${base.client} ${i + 1}`,
        date: new Date(2025, 3, 1 + (i % 10)).toISOString(),
        entrega: new Date(2025, 3, 8 + (i % 10)).toISOString(),
      });
    }

    setOrders(generated);
  }, []);

  const showToast = (text, tipo = "exito") => {
    setToastMessage(text);
    setToastTipo(tipo);
    setIsToastVisible(true);
    setTimeout(() => {
      setIsToastVisible(false);
      setToastMessage("");
    }, 3000);
  };

  const handleCreateOrder = (newOrder) => {
    showToast("Pedido guardado exitosamente", "exito");
    setShowModal(false);
  };

  const filteredOrders = orders.filter((order) => {
    const matchesSearch =
      order.client.toLowerCase().includes(search.toLowerCase()) ||
      order.id.toString().includes(search);
    const matchesStatus =
      statusFilter === "todos" || order.status === statusFilter;
    return matchesSearch && matchesStatus;
  });

  const totalPages = Math.ceil(filteredOrders.length / recordsPerPage);
  const startIndex = (currentPage - 1) * recordsPerPage;
  const endIndex = startIndex + recordsPerPage;
  const paginatedOrders = filteredOrders.slice(startIndex, endIndex);

  const handlePageChange = (page) => {
    setCurrentPage(page);
  };

  const getPageNumbers = () => {
    const pageNumbers = [];
    const maxPageButtons = 5;

    let startPage = Math.max(1, currentPage - Math.floor(maxPageButtons / 2));
    let endPage = startPage + maxPageButtons - 1;

    if (endPage > totalPages) {
      endPage = totalPages;
      startPage = Math.max(1, endPage - maxPageButtons + 1);
    }

    for (let i = startPage; i <= endPage; i++) {
      pageNumbers.push(i);
    }

    return pageNumbers;
  };

  const isValidTransition = (from, to) => {
    if (from === to) return true;
    if (from === "creado" && to === "en proceso") return true;
    if (from === "en proceso" && to === "enviado") return true;
    if (from === "en espera" && to === "en proceso") return true;
    if (from === "creado" && ["en espera", "en proceso"].includes(to))
      return true;
    return false;
  };

  const openModal = (order) => {
    setSelectedOrder(order);
    setEditedStatus(order.status);
    setEditedProducts(order.details.map((p) => ({ ...p })));
    setEditedMetodoEnvio(order.metodo_envio);
  };

  const handleQuantityChange = (index, value) => {
    const updated = [...editedProducts];
    updated[index].quantity = value === "" ? "" : Number(value);
    setEditedProducts(updated);
  };

  const handleDeleteOrder = (id) => {
    setOrderToDelete(orders.find((order) => order.id === id));
  };

  const confirmDelete = () => {
    const updatedOrders = orders.filter(
      (order) => order.id !== orderToDelete.id
    );
    setOrders(updatedOrders);
    setOrderToDelete(null);
    showToast("Pedido eliminado con éxito", "exito");
  };

  const cancelDelete = () => {
    setOrderToDelete(null);
  };

  const productsAreEqual = (a, b) => {
    if (a.length !== b.length) return false;
    return a.every((item, i) => {
      const quantityA = Number(item.quantity);
      const quantityB = Number(b[i].quantity);
      return (
        item.name === b[i].name &&
        item.price === b[i].price &&
        quantityA === quantityB
      );
    });
  };

  const saveChanges = () => {
    // Validar cantidades vacías o inválidas
    if (
      editedProducts.some(
        (item) =>
          item.quantity === "" ||
          isNaN(item.quantity) ||
          Number(item.quantity) < 1
      )
    ) {
      showToast("Cantidad inválida en algún producto", "error");
      return;
    }

    const newDetails = editedProducts.map((item) => ({
      ...item,
      quantity: Number(item.quantity),
    }));

    const updatedOrder = {
      ...selectedOrder,
      status: editedStatus,
      metodo_envio: editedMetodoEnvio,
      details: newDetails,
      total: newDetails.reduce(
        (sum, item) => sum + item.quantity * item.price,
        0
      ),
    };

    const isSameStatus = editedStatus === selectedOrder.status;
    const isSameMetodo = editedMetodoEnvio === selectedOrder.metodo_envio;
    const isSameProducts = productsAreEqual(newDetails, selectedOrder.details);

    if (isSameStatus && isSameMetodo && isSameProducts) {
      showToast("No hay cambios para guardar", "error");
      return;
    }

    if (!isValidTransition(selectedOrder.status, editedStatus)) {
      showToast("Transición de estado no permitida", "error");
      return;
    }

    const updatedOrders = orders.map((o) =>
      o.id === updatedOrder.id ? updatedOrder : o
    );

    setOrders(updatedOrders);
    showToast("Pedido actualizado con éxito", "exito");
    setTimeout(() => {
      setSelectedOrder(null);
    }, 300);
  };

  return (
    <div className="orders-container">
      <div className="orders-header">
        <h1 className="orders-title">Pedidos</h1>
        <div className="orders-controls">
          <div className="search-input-wrapper">
            <FontAwesomeIcon icon={faMagnifyingGlass} className="search-icon" />
            <input
              type="text"
              placeholder="Buscar cliente o ID"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="search-input"
            />
          </div>
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="estado-select"
          >
            <option value="todos">Todos los estados</option>
            {statuses.map((status) => (
              <option key={status} value={status}>
                {status}
              </option>
            ))}
          </select>
          <button className="agregar-button" onClick={() => setShowModal(true)}>
            Agregar Pedido
          </button>
        </div>
        {showModal && (
          <CreateOrder
            onClose={() => setShowModal(false)}
            onSubmit={handleCreateOrder}
            showToast={showToast}
          />
        )}
      </div>
      <div className="order-table-container">
        <table className="orders-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Cliente</th>
              <th>Estado</th>
              <th>Total</th>
              <th>Creación</th>
              <th>Entrega</th>
              <th>Acciones</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {paginatedOrders.map((order) => (
              <tr key={order.id}>
                <td>{order.id}</td>
                <td>{order.client}</td>
                <td>{order.status}</td>
                <td>${order.total}</td>
                <td>{new Date(order.date).toLocaleDateString()}</td>
                <td>{new Date(order.entrega).toLocaleDateString()}</td>
                <td className="acciones-cell">
                  <button
                    className="ver-button"
                    onClick={() => openModal(order)}
                  >
                    Ver Detalles
                  </button>
                  <button
                    className="delete-button"
                    onClick={() => handleDeleteOrder(order.id)}
                    title="Eliminar Pedido"
                  >
                    <FontAwesomeIcon icon={faTrash} />
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {filteredOrders.length > recordsPerPage && (
        <div className="pagination">
          <button
            className="pagination-button"
            onClick={() => handlePageChange(1)}
            disabled={currentPage === 1}
          >
            &laquo;
          </button>
          <button
            className="pagination-button"
            onClick={() => handlePageChange(currentPage - 1)}
            disabled={currentPage === 1}
          >
            &lt;
          </button>
          {getPageNumbers().map((number) => (
            <button
              key={number}
              className={`pagination-button ${
                currentPage === number ? "active" : ""
              }`}
              onClick={() => handlePageChange(number)}
            >
              {number}
            </button>
          ))}
          <button
            className="pagination-button"
            onClick={() => handlePageChange(currentPage + 1)}
            disabled={currentPage === totalPages}
          >
            &gt;
          </button>
          <button
            className="pagination-button"
            onClick={() => handlePageChange(totalPages)}
            disabled={currentPage === totalPages}
          >
            &raquo;
          </button>
          <span className="pagination-info">
            Página {currentPage} de {totalPages}
          </span>
        </div>
      )}

      {selectedOrder && (
        <div className="modal-overlay">
          <div className="modal-order">
            <div className="modal-order-header">
              <h2>Pedido {selectedOrder.id}</h2>
              <div className="modal-details">
                <div className="modal-order-info">
                  <div className="info-pair">
                    <strong>Cliente:</strong> {selectedOrder.client}
                  </div>
                  <div className="info-pair">
                    <strong>Registrado por:</strong>{" "}
                    {selectedOrder.usuario || "—"}
                  </div>
                  <div className="info-pair">
                    <strong>Método de envío:</strong>
                    <select
                      value={editedMetodoEnvio}
                      onChange={(e) => setEditedMetodoEnvio(e.target.value)}
                      className="option-select"
                    >
                      {metodoEnvioOptions.map((op) => (
                        <option key={op} value={op}>
                          {op}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div className="info-pair">
                    <strong>Estado:</strong>
                    <select
                      value={editedStatus}
                      onChange={(e) => setEditedStatus(e.target.value)}
                      className="option-select"
                    >
                      {statuses.map((s) => (
                        <option key={s} value={s}>
                          {s}
                        </option>
                      ))}
                    </select>
                  </div>
                </div>
                <div className="modal-order-info-1">
                  <strong>Productos:</strong>
                  <ul className="productos-lista">
                    {editedProducts.map((item, i) => (
                      <li key={i}>
                        {item.name} -
                        <input
                          type="number"
                          value={item.quantity}
                          min={1}
                          onChange={(e) =>
                            handleQuantityChange(i, e.target.value)
                          }
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
                          className="input-editable"
                        />
                        x ${item.price} = $
                        {item.quantity && !isNaN(item.quantity)
                          ? item.quantity * item.price
                          : 0}
                      </li>
                    ))}
                    <p>
                      <strong>Total:</strong> $
                      {editedProducts.reduce(
                        (sum, item) =>
                          sum +
                          (item.quantity && !isNaN(item.quantity)
                            ? item.quantity * item.price
                            : 0),
                        0
                      )}
                    </p>
                  </ul>
                </div>
              </div>
              <div className="modal-buttons">
                <button onClick={saveChanges} className="guardar-button">
                  Guardar
                </button>
                <button
                  onClick={() => setSelectedOrder(null)}
                  className="cancelar-button"
                >
                  Cerrar
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
      {orderToDelete && (
        <div className="modal-overlay">
          <div className="modal-confirm">
            <p>
              ¿Deseás eliminar el pedido <strong>{orderToDelete.id}</strong> de{" "}
              <strong>{orderToDelete.client}</strong>?
            </p>
            <div className="modal-actions">
              <button className="guardar-button" onClick={confirmDelete}>
                Sí, eliminar
              </button>
              <button className="cancelar-button" onClick={cancelDelete}>
                Cancelar
              </button>
            </div>
          </div>
        </div>
      )}

      {isToastVisible && (
        <div className={`toast ${toastTipo}`}>{toastMessage}</div>
      )}
    </div>
  );
}
