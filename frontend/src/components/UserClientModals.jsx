import React, { useState, useEffect } from "react";
import "../styles/UserClientModals.css";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faEye, faEyeSlash } from "@fortawesome/free-regular-svg-icons";
import { userController } from "../controllers/userController";
import { clientController } from "../controllers/clientController";
import { authController } from "../controllers/authController";

export function ManageUsersModal({ onClose }) {
  const [activeTab, setActiveTab] = useState("ver");
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(false);

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

  // Cargar usuarios al montar el componente
  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      const response = await userController.getAllUsers();
      console.log(response);
      if (response.success) {
        setUsers(response.data);
      } else {
        showToast(response.message || "Error al cargar usuarios", "error");
      }
    } catch (error) {
      showToast("Error al conectar con el servidor", error);
    } finally {
      setLoading(false);
    }
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

  const handleAddUser = async () => {
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

    try {
      setLoading(true);
      // Asumimos que existe un método para crear usuarios
      const response = await authController.register(newUser);

      if (response.success) {
        setUsers([...users, response.data]);
        setNewUser({
          nombre: "",
          correo: "",
          contrasena: "",
          rol: "",
          nombre_usuario: "",
        });
        showToast("Usuario agregado exitosamente");
      } else {
        showToast(response.message || "Error al crear usuario", "error");
      }
    } catch (error) {
      showToast("Error al conectar con el servidor", error);
    } finally {
      setLoading(false);
    }
  };

  const confirmDeleteUser = async () => {
    try {
      setLoading(true);
      const response = await userController.deleteUser(userToDelete.usuario_id);

      if (response.success) {
        setUsers(users.filter((u) => u.usuario_id !== userToDelete.usuario_id));
        showToast("Usuario eliminado correctamente");
      } else {
        showToast(response.message || "Error al eliminar usuario", "error");
      }
    } catch (error) {
      showToast("Error al conectar con el servidor", error);
    } finally {
      setLoading(false);
      setUserToDelete(null);
    }
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
              {loading ? (
                <p className="loading-text">Cargando usuarios...</p>
              ) : users.length === 0 ? (
                <p className="empty-message">No hay usuarios registrados</p>
              ) : (
                <ul className="item-list">
                  {users.map((user) => (
                    <li key={user.usuario_id} className="list-item">
                      <div>
                        <strong>{user.nombre}</strong> ({user.rol}) -{" "}
                        {user.correo}
                      </div>
                      <button
                        onClick={() => handleDeleteUser(user)}
                        className="delete1-button"
                        disabled={loading}
                      >
                        Eliminar
                      </button>
                    </li>
                  ))}
                </ul>
              )}
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
                  disabled={loading}
                  required
                />
                <input
                  type="email"
                  placeholder="Correo"
                  value={newUser.correo}
                  onChange={(e) =>
                    setNewUser({ ...newUser, correo: e.target.value })
                  }
                  disabled={loading}
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
                    className="pass-icon"
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
                  disabled={loading}
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
                  disabled={loading}
                  required
                />
              </div>
              <div className="form-actions">
                <button
                  onClick={handleAddUser}
                  className="save-button"
                  disabled={loading}
                >
                  {loading ? "Agregando..." : "Agregar Usuario"}
                </button>
              </div>
            </>
          )}

          <div className="modal-buttons">
            <button
              onClick={onClose}
              className="cancel-button"
              disabled={loading}
            >
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
              <button
                className="guardar-button"
                onClick={confirmDeleteUser}
                disabled={loading}
              >
                {loading ? "Eliminando..." : "Sí, eliminar"}
              </button>
              <button
                className="cancelar-button"
                onClick={cancelDeleteUser}
                disabled={loading}
              >
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
  const [clients, setClients] = useState([]);
  const [loading, setLoading] = useState(false);

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

  // Cargar clientes al montar el componente
  useEffect(() => {
    fetchClients();
  }, []);

  const fetchClients = async () => {
    try {
      setLoading(true);
      const response = await clientController.getAllClients();
      if (response.success) {
        setClients(response.data);
      } else {
        showToast(response.message || "Error al cargar clientes", "error");
      }
    } catch (error) {
      showToast("Error al conectar con el servidor", error);
    } finally {
      setLoading(false);
    }
  };

  const handleAddClient = async () => {
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

    try {
      setLoading(true);
      const response = await clientController.createClient(newClient);

      if (response.success) {
        setClients([...clients, response.data]);
        setNewClient({ nombre: "", telefono: "", correo: "", direccion: "" });
        showToast("Cliente agregado correctamente");
      } else {
        showToast(response.message || "Error al crear cliente", "error");
      }
    } catch (error) {
      showToast("Error al conectar con el servidor", error);
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteClient = (client) => {
    setClientToDelete(client);
  };

  const confirmDeleteClient = async () => {
    try {
      setLoading(true);
      const response = await clientController.deleteClient(
        clientToDelete.cliente_id
      );

      if (response.success) {
        setClients(
          clients.filter((c) => c.cliente_id !== clientToDelete.cliente_id)
        );
        showToast("Cliente eliminado correctamente");
      } else {
        showToast(response.message || "Error al eliminar cliente", "error");
      }
    } catch (error) {
      showToast("Error al conectar con el servidor", error);
    } finally {
      setLoading(false);
      setClientToDelete(null);
    }
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
              {loading ? (
                <p className="loading-text">Cargando clientes...</p>
              ) : clients.length === 0 ? (
                <p className="empty-message">No hay clientes registrados</p>
              ) : (
                <ul className="item-list">
                  {clients.map((client) => (
                    <li key={client.cliente_id} className="list-item">
                      <div>
                        <strong>{client.nombre}</strong> - {client.telefono} -{" "}
                        {client.correo}
                        <br />
                        <small>{client.direccion}</small>
                      </div>
                      <button
                        onClick={() => handleDeleteClient(client)}
                        className="delete1-button"
                        disabled={loading}
                      >
                        Eliminar
                      </button>
                    </li>
                  ))}
                </ul>
              )}
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
                  disabled={loading}
                  required
                />
                <input
                  type="text"
                  placeholder="Teléfono"
                  value={newClient.telefono}
                  onChange={(e) =>
                    setNewClient({ ...newClient, telefono: e.target.value })
                  }
                  disabled={loading}
                  required
                />
                <input
                  type="email"
                  placeholder="Correo"
                  value={newClient.correo}
                  onChange={(e) =>
                    setNewClient({ ...newClient, correo: e.target.value })
                  }
                  disabled={loading}
                  required
                />
                <textarea
                  placeholder="Dirección"
                  maxLength={100}
                  value={newClient.direccion}
                  onChange={(e) =>
                    setNewClient({ ...newClient, direccion: e.target.value })
                  }
                  disabled={loading}
                  required
                />
                <div className="char-counter">
                  {newClient.direccion.length}/100 caracteres
                </div>
              </div>
              <div className="form-actions">
                <button
                  onClick={handleAddClient}
                  className="save-button"
                  disabled={loading}
                >
                  {loading ? "Agregando..." : "Agregar Cliente"}
                </button>
              </div>
            </>
          )}

          <div className="modal-buttons">
            <button
              onClick={onClose}
              className="cancel-button"
              disabled={loading}
            >
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
              <button
                className="guardar-button"
                onClick={confirmDeleteClient}
                disabled={loading}
              >
                {loading ? "Eliminando..." : "Sí, eliminar"}
              </button>
              <button
                className="cancelar-button"
                onClick={cancelDeleteClient}
                disabled={loading}
              >
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
