import React, { useState } from "react";
import "../styles/UserClientModals.css";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faEye, faEyeSlash } from "@fortawesome/free-regular-svg-icons";

export function ManageUsersModal({ onClose }) {
  const [activeTab, setActiveTab] = useState("ver");
  const [users, setUsers] = useState([
    {
      id_usuario: 1,
      nombre: "Lucía Gómez",
      correo: "lucia@example.com",
      contrasena: "",
      rol: "Administrador",
      nombre_usuario: "lgomez",
    },
    {
      id_usuario: 2,
      nombre: "Carlos Ramírez",
      correo: "carlos@example.com",
      contrasena: "",
      rol: "Vendedor",
      nombre_usuario: "cramirez",
    },
  ]);

  const [newUser, setNewUser] = useState({
    nombre: "",
    correo: "",
    contrasena: "",
    rol: "",
    nombre_usuario: "",
  });

  const [toastMessage, setToastMessage] = useState("");
  const [toastType, setToastType] = useState("exito");
  const [isToastVisible, setIsToastVisible] = useState(false);
  const [userToDelete, setUserToDelete] = useState(null);
  const [showPassword, setShowPassword] = useState(false);

  const showToast = (text, tipo = "exito") => {
    setToastMessage(text);
    setToastType(tipo);
    setIsToastVisible(true);
    setTimeout(() => {
      setIsToastVisible(false);
      setToastMessage("");
    }, 3000);
  };

  const handleAddUser = () => {
    const correoValido = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(newUser.correo);
    const contraseñaValida =
      /^(?=.*\d)(?=.*[!@#$%^&*()_+\-={}[\]|\\:;"'<>,.?/~`]).{8,}$/.test(
        newUser.contrasena
      );

    if (
      !newUser.nombre ||
      !newUser.correo ||
      !newUser.contrasena ||
      !newUser.rol ||
      !newUser.nombre_usuario
    ) {
      showToast("Todos los campos deben estar completos.", "error");
      return;
    }

    if (!correoValido) {
      showToast("El correo electrónico no es válido.", "error");
      return;
    }

    if (!contraseñaValida) {
      showToast(
        "La contraseña debe tener al menos 8 caracteres, incluir un número y un símbolo especial.",
        "error"
      );
      return;
    }

    const nombreUsuarioExiste = users.some(
      (u) =>
        u.nombre_usuario.toLowerCase() === newUser.nombre_usuario.toLowerCase()
    );

    if (nombreUsuarioExiste) {
      showToast("Ese nombre de usuario ya existe.", "error");
      return;
    }

    const updated = [...users, { ...newUser, id_usuario: Date.now() }];
    setUsers(updated);
    setNewUser({
      nombre: "",
      correo: "",
      contrasena: "",
      rol: "",
      nombre_usuario: "",
    });
    showToast("Usuario agregado exitosamente");
  };

  const confirmDeleteUser = () => {
    setUsers(users.filter((u) => u.id_usuario !== userToDelete.id_usuario));
    setUserToDelete(null);
  };

  const cancelDeleteUser = () => {
    setUserToDelete(null);
  };

  const handleDeleteUser = (user) => {
    setUserToDelete(user);
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content">
        <div className="modal-description">
          <h2>Gestionar Usuarios</h2>

          <div className="tabs">
            <button
              className={activeTab === "ver" ? "active" : ""}
              onClick={() => setActiveTab("ver")}
            >
              Ver / Eliminar
            </button>
            <button
              className={activeTab === "agregar" ? "active" : ""}
              onClick={() => setActiveTab("agregar")}
            >
              Agregar
            </button>
          </div>

          {activeTab === "ver" && (
            <div className="scrollable-list">
              <ul className="item-list">
                {users.map((user) => (
                  <li key={user.id_usuario} className="list-item">
                    <div>
                      <strong>{user.nombre_usuario}</strong> ({user.rol}) -{" "}
                      {user.correo}
                    </div>
                    <button
                      onClick={() => handleDeleteUser(user)}
                      className="delete-button"
                    >
                      Eliminar
                    </button>
                  </li>
                ))}
              </ul>
            </div>
          )}

          {activeTab === "agregar" && (
            <>
              <div className="form-container">
                <input
                  type="text"
                  placeholder="Nombre"
                  value={newUser.nombre}
                  onChange={(e) =>
                    setNewUser({ ...newUser, nombre: e.target.value })
                  }
                  required
                />
                <input
                  type="email"
                  placeholder="Correo"
                  value={newUser.correo}
                  onChange={(e) =>
                    setNewUser({ ...newUser, correo: e.target.value })
                  }
                  required
                />
                <div className="password-container">
                  <input
                    type={showPassword ? "text" : "password"}
                    placeholder="Contraseña"
                    value={newUser.contrasena}
                    onChange={(e) =>
                      setNewUser({ ...newUser, contrasena: e.target.value })
                    }
                    required
                  />
                  <FontAwesomeIcon
                    icon={showPassword ? faEyeSlash : faEye}
                    className="password-icon"
                    onClick={() => setShowPassword(!showPassword)}
                  />
                </div>

                <input
                  type="text"
                  placeholder="Rol"
                  value={newUser.rol}
                  onChange={(e) =>
                    setNewUser({ ...newUser, rol: e.target.value })
                  }
                  required
                />
                <input
                  type="text"
                  placeholder="Nombre de usuario"
                  value={newUser.nombre_usuario}
                  onChange={(e) =>
                    setNewUser({
                      ...newUser,
                      nombre_usuario: e.target.value,
                    })
                  }
                  required
                />
              </div>
              <div className="form-actions">
                <button onClick={handleAddUser} className="save-button">
                  Agregar Usuario
                </button>
              </div>
            </>
          )}

          <div className="modal-buttons">
            <button onClick={onClose} className="cancel-button">
              Cerrar
            </button>
          </div>
        </div>
      </div>

      {userToDelete && (
        <div className="modal-overlay">
          <div className="modal-confirm">
            <p>
              ¿Desea eliminar al usuario{" "}
              <strong>{userToDelete.nombre_usuario}</strong>?
            </p>
            <div className="modal-actions">
              <button className="guardar-button" onClick={confirmDeleteUser}>
                Sí, eliminar
              </button>
              <button className="cancelar-button" onClick={cancelDeleteUser}>
                Cancelar
              </button>
            </div>
          </div>
        </div>
      )}

      {isToastVisible && (
        <div className={`toast ${toastType}`}>{toastMessage}</div>
      )}
    </div>
  );
}

export function ManageClientsModal({ onClose }) {
  const [activeTab, setActiveTab] = useState("ver");
  const [clients, setClients] = useState([
    {
      id_cliente: 1,
      nombre: "Pedro López",
      telefono: "98765432",
      correo: "pedro@example.com",
      direccion: "Barrio Centro, Tegucigalpa",
    },
    {
      id_cliente: 2,
      nombre: "Ana Torres",
      telefono: "99887766",
      correo: "ana@example.com",
      direccion: "Colonia Kennedy, Tegucigalpa",
    },
  ]);

  const [newClient, setNewClient] = useState({
    nombre: "",
    telefono: "",
    correo: "",
    direccion: "",
  });

  const [toastMessage, setToastMessage] = useState("");
  const [toastType, setToastType] = useState("exito");
  const [isToastVisible, setIsToastVisible] = useState(false);
  const [clientToDelete, setClientToDelete] = useState(null);

  const handleAddClient = () => {
    const telefonoValido = /^[983]\d{7}$/.test(newClient.telefono);
    const correoValido = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(newClient.correo);

    if (
      !newClient.nombre ||
      !newClient.telefono ||
      !newClient.correo ||
      !newClient.direccion
    ) {
      showToast("Por favor complete los campos.", "error");
      return;
    }

    if (!telefonoValido) {
      showToast(
        "El número debe tener 8 dígitos y comenzar con 9, 8, 3 o 2.",
        "error"
      );
      return;
    }

    if (!correoValido) {
      showToast("El correo electrónico no es válido.", "error");
      return;
    }

    const updated = [...clients, { ...newClient, id_cliente: Date.now() }];
    setClients(updated);
    setNewClient({ nombre: "", telefono: "", correo: "", direccion: "" });
  };

  const handleDeleteClient = (client) => {
    setClientToDelete(client);
  };

  const confirmDeleteClient = () => {
    setClients(
      clients.filter((c) => c.id_cliente !== clientToDelete.id_cliente)
    );
    setClientToDelete(null);
    showToast("Cliente eliminado correctamente");
  };

  const cancelDeleteClient = () => {
    setClientToDelete(null);
  };

  const showToast = (text, tipo = "exito") => {
    setToastMessage(text);
    setToastType(tipo);
    setIsToastVisible(true);
    setTimeout(() => {
      setIsToastVisible(false);
      setToastMessage("");
    }, 3000);
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content">
        <div className="modal-description">
          <h2>Gestionar Clientes</h2>

          <div className="tabs">
            <button
              className={activeTab === "ver" ? "active" : ""}
              onClick={() => setActiveTab("ver")}
            >
              Ver / Eliminar
            </button>
            <button
              className={activeTab === "agregar" ? "active" : ""}
              onClick={() => setActiveTab("agregar")}
            >
              Agregar
            </button>
          </div>

          {activeTab === "ver" && (
            <div className="scrollable-list">
              <ul className="item-list">
                {clients.map((client) => (
                  <li key={client.id_cliente} className="list-item">
                    <div>
                      <strong>{client.nombre}</strong> - {client.telefono} -{" "}
                      {client.correo}
                      <br />
                      <small>{client.direccion}</small>
                    </div>
                    <button
                      onClick={() => handleDeleteClient(client)}
                      className="delete-button"
                    >
                      Eliminar
                    </button>
                  </li>
                ))}
              </ul>
            </div>
          )}

          {activeTab === "agregar" && (
            <>
              <div className="form-container">
                <input
                  type="text"
                  placeholder="Nombre"
                  value={newClient.nombre}
                  onChange={(e) =>
                    setNewClient({ ...newClient, nombre: e.target.value })
                  }
                  required
                />
                <input
                  type="text"
                  placeholder="Teléfono"
                  value={newClient.telefono}
                  onChange={(e) =>
                    setNewClient({ ...newClient, telefono: e.target.value })
                  }
                  required
                />
                <input
                  type="email"
                  placeholder="Correo"
                  value={newClient.correo}
                  onChange={(e) =>
                    setNewClient({ ...newClient, correo: e.target.value })
                  }
                  required
                />
                <textarea
                  placeholder="Dirección"
                  maxLength={100}
                  value={newClient.direccion}
                  onChange={(e) =>
                    setNewClient({ ...newClient, direccion: e.target.value })
                  }
                  required
                />
                <div className="char-counter">
                  {newClient.direccion.length}/100 caracteres
                </div>
              </div>
              <div className="form-actions">
                <button onClick={handleAddClient} className="save-button">
                  Agregar Cliente
                </button>
              </div>
            </>
          )}

          <div className="modal-buttons">
            <button onClick={onClose} className="cancel-button">
              Cerrar
            </button>
          </div>
        </div>
      </div>

      {clientToDelete && (
        <div className="modal-overlay">
          <div className="modal-confirm">
            <p>
              ¿Deseás eliminar al cliente{" "}
              <strong>{clientToDelete.nombre}</strong>?
            </p>
            <div className="modal-actions">
              <button className="guardar-button" onClick={confirmDeleteClient}>
                Sí, eliminar
              </button>
              <button className="cancelar-button" onClick={cancelDeleteClient}>
                Cancelar
              </button>
            </div>
          </div>
        </div>
      )}

      {isToastVisible && (
        <div className={`toast ${toastType}`}>{toastMessage}</div>
      )}
    </div>
  );
}
