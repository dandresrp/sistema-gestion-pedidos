import React, { useEffect, useState } from "react";
// import { reportController } from "../../controllers/reportController";
import "../../styles/Inventory.css";
import ProductCard from "../../components/ProductCard";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faMagnifyingGlass } from "@fortawesome/free-solid-svg-icons";
import prodImg from "../../assets/prod_258_popup.jpg";
import Llavero from "../../assets/llavero.jpeg";
import Gorra from "../../assets/products_sublimacion_gorra_01.jpg";
import Taza from "../../assets/TS-01.jpg";
import Termo from "../../assets/0008202_38536-termo-moka-marcado-serigrafia_550.jpg";

export default function Inventory() {
  const [search, setSearch] = useState("");
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [suggestion, setSuggestion] = useState("");

  const [selectedProduct, setSelectedProduct] = useState(null);
  const [editProduct, setEditProduct] = useState(null);
  const [stockError, setStockError] = useState("");
  const [addStockError, setAddStockError] = useState("");

  const [showAddModal, setShowAddModal] = useState(false);
  const [newProduct, setNewProduct] = useState({
    nombre: "",
    stock: "",
    imagen: "",
  });
  const [previewImage, setPreviewImage] = useState(null);

  const [toastMessage, setToastMessage] = useState("");
  const [toastType, setToastType] = useState("exito");
  const [isToastVisible, setIsToastVisible] = useState(false);

  const handleAddProduct = () => {
    if (
      !newProduct.nombre ||
      newProduct.stock === "" ||
      isNaN(newProduct.stock) ||
      newProduct.stock < 0
    ) {
      showToast("Por favor complete correctamente los campos", "error");
      return;
    }

    const imagenFinal = newProduct.imagen
      ? URL.createObjectURL(newProduct.imagen)
      : prodImg;

    const nuevo = {
      id: Date.now(),
      nombre: newProduct.nombre,
      stock: Number(newProduct.stock),
      imagen: imagenFinal,
      precio: newProduct.precio || null,
      descripcion: newProduct.descripcion || null,
    };

    setProducts([...products, nuevo]);
    setShowAddModal(false);
    setNewProduct({
      nombre: "",
      stock: "",
      precio: "",
      descripcion: "",
    });
    setPreviewImage(null);
    showToast("Producto agregado exitosamente");
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

  useEffect(() => {
    // const fetchInventory = async () => {
    //   try {
    //     setLoading(true);
    //     const res = await reportController.getInventory();
    //     if (!res.success) throw new Error(res.message);
    //     const data = res.data.map((item) => {
    //       let imagenFinal =
    //         item.imagen_url && item.imagen_url.trim() !== ""
    //           ? item.imagen_url
    //           : prodImg;
    //       if (item.nombre_producto === "Mouspad") {
    //         imagenFinal = prodImg,;
    //       }
    //       return {
    //         id: item.id,
    //         nombre: item.nombre_producto,
    //         stock: item.stock_disponible,
    //         imagen: imagenFinal,
    //       };
    //     });
    //     setProducts(data);
    //   } catch (err) {
    //     setError("No se pudo cargar el inventario: " + err.message);
    //   } finally {
    //     setLoading(false);
    //   }
    // };
    // fetchInventory();

    const mockData = [
      {
        id: 1,
        nombre: "Camisa XL",
        stock: 10,
        imagen: prodImg,
        precio: "Lps 200.00",
        descripcion: "Camisa sublimable",
      },
      {
        id: 1,
        nombre: "Camisa L",
        stock: 15,
        imagen: prodImg,
        precio: "Lps 200.00",
        descripcion: "Camisa sublimable",
      },
      {
        id: 1,
        nombre: "Camisa S",
        stock: 12,
        imagen: prodImg,
        precio: "Lps 200.00",
        descripcion: "Camisa sublimable",
      },
      {
        id: 1,
        nombre: "Camisa M",
        stock: 8,
        imagen: prodImg,
        precio: "Lps 200.00",
        descripcion: "Camisa sublimable",
      },
      {
        id: 2,
        nombre: "Gorra S Negra",
        stock: 4,
        imagen: Gorra,
        precio: "Lps 200.00",
        descripcion: "Gorra sublimable",
      },
      {
        id: 2,
        nombre: "Gorra M Blanca",
        stock: 9,
        imagen: Gorra,
        precio: "Lps 200.00",
        descripcion: "Gorra sublimable",
      },
      {
        id: 2,
        nombre: "Gorra L Verde",
        stock: 7,
        imagen: Gorra,
        precio: "Lps 200.00",
        descripcion: "Gorra sublimable",
      },
      {
        id: 2,
        nombre: "Gorra XL Azul",
        stock: 3,
        imagen: Gorra,
        precio: "Lps 200.00",
        descripcion: "Gorra sublimable",
      },
      {
        id: 3,
        nombre: "Llavero Rectangular",
        stock: 11,
        imagen: Llavero,
        precio: "Lps 100.00",
        descripcion: "Llavero sublimable",
      },
      {
        id: 3,
        nombre: "Llavero Circular",
        stock: 5,
        imagen: Llavero,
        precio: "Lps 120.00",
        descripcion: "Llavero sublimable",
      },
      {
        id: 3,
        nombre: "Termo Plástico",
        stock: 10,
        imagen: Termo,
        precio: "Lps 170.00",
        descripcion: "Termo sublimable",
      },
      {
        id: 3,
        nombre: "Termo Aluminio",
        stock: 7,
        imagen: Termo,
        precio: "Lps 290.00",
        descripcion: "Termo sublimable",
      },
      {
        id: 3,
        nombre: "Taza Mágica",
        stock: 12,
        imagen: Taza,
        precio: "Lps 200.00",
        descripcion: "Taza sublimable",
      },
      {
        id: 3,
        nombre: "Taza",
        stock: 9,
        imagen: Taza,
        precio: "Lps 150.00",
        descripcion: "Taza sublimable",
      },
    ];

    setProducts(mockData);
    setLoading(false);
  }, []);

  const handleSearchChange = (value) => {
    setSearch(value);

    const words = value.trim().split(" ");
    const lastWord = words[words.length - 1].toLowerCase();

    if (lastWord.length >= 2) {
      const match = products.find((p) => {
        const nombreWords = p.nombre.toLowerCase().split(" ");
        return nombreWords.some((word) => word.startsWith(lastWord));
      });

      if (match) {
        const matchWord = match.nombre
          .split(" ")
          .find((w) => w.toLowerCase().startsWith(lastWord));
        if (matchWord) {
          const completedWords = [...words];
          completedWords[words.length - 1] = matchWord;
          setSuggestion(completedWords.join(" "));
        } else {
          setSuggestion("");
        }
      } else {
        setSuggestion("");
      }
    } else {
      setSuggestion("");
    }
  };

  const clean = (text) =>
    text
      .replace(/^"(.*)"$/, "$1")
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .toLowerCase()
      .trim();

  const filteredProducts = products.filter((p) =>
    clean(p.nombre).includes(clean(search))
  );

  const openEditModal = (product) => {
    setSelectedProduct(product);
    setEditProduct({ ...product });
  };

  const closeModal = () => {
    setSelectedProduct(null);
    setEditProduct(null);
  };

  const handleUpdateProduct = () => {
    if (
      !editProduct.nombre ||
      editProduct.stock === "" ||
      isNaN(editProduct.stock) ||
      editProduct.stock < 0
    ) {
      showToast("Error al actualizar el producto", "error");
      return;
    }

    const updatedProducts = products.map((p) =>
      p.id === selectedProduct.id
        ? { ...editProduct, stock: Number(editProduct.stock) }
        : p
    );

    setProducts(updatedProducts);
    closeModal();
    showToast("Producto actualizado con éxito");
  };

  return (
    <div className="inventory-container">
      <div className="inventory-header">
        <h1>Inventario</h1>
        <div className="search-wrapper">
          <FontAwesomeIcon icon={faMagnifyingGlass} className="search-icon" />
          <input
            className="search-input"
            type="text"
            placeholder="Buscar producto..."
            value={search}
            onChange={(e) => handleSearchChange(e.target.value)}
            onKeyDown={(e) => {
              if ((e.key === "Tab" || e.key === "Enter") && suggestion) {
                e.preventDefault();
                setSearch(suggestion);
                setSuggestion("");
              }
            }}
          />
          {suggestion && suggestion.toLowerCase() !== search.toLowerCase() && (
            <div className="suggestion-overlay">
              <span className="suggestion-text">
                {search}
                <span className="suggestion-light">
                  {suggestion.slice(search.length)}
                </span>
              </span>
            </div>
          )}
        </div>

        <button className="add-button" onClick={() => setShowAddModal(true)}>
          Crear Nuevo Producto
        </button>
      </div>

      {loading ? (
        <p className="info-text">Cargando productos...</p>
      ) : error ? (
        <p className="error-text">{error}</p>
      ) : filteredProducts.length === 0 ? (
        <p className="info-text">No se encontraron productos.</p>
      ) : (
        <div className="product-scroll-container">
          <div className="product-grid">
            {filteredProducts.map((product) => (
              <ProductCard
                key={product.id}
                product={product}
                onEdit={openEditModal}
              />
            ))}
          </div>
        </div>
      )}

      {/* Modal de edición */}
      {selectedProduct && editProduct && (
        <div className="modal-overlay">
          <div className="modal">
            <div className="modal-description">
              <h2>Editar Producto</h2>

              <label>
                Nombre del producto:
                <input
                  type="text"
                  value={editProduct.nombre}
                  onChange={(e) =>
                    setEditProduct({ ...editProduct, nombre: e.target.value })
                  }
                />
              </label>

              <div
                style={{ display: "flex", gap: "2rem", marginBottom: "1rem" }}
              >
                <label style={{ flex: 1 }}>
                  Stock:
                  <input
                    type="text"
                    value={editProduct.stock}
                    onChange={(e) => {
                      const val = e.target.value;
                      if (/^\d*$/.test(val)) {
                        setEditProduct({ ...editProduct, stock: val });
                        setStockError("");
                      } else {
                        showToast("Solo se permiten números", "error");
                      }
                    }}
                  />
                </label>

                <label style={{ flex: 1 }}>
                  Precio:
                  <input
                    type="text"
                    value={editProduct.precio || ""}
                    onChange={(e) =>
                      setEditProduct({ ...editProduct, precio: e.target.value })
                    }
                  />
                </label>
              </div>

              <label style={{ flex: 1 }}>
                Descripción:
                <input
                  type="text"
                  value={editProduct.descripcion}
                  onChange={(e) =>
                    setNewProduct({
                      ...newProduct,
                      descripcion: e.target.value,
                    })
                  }
                  required
                />
              </label>

              {/* <div
                style={{ display: "flex", gap: "2rem", marginBottom: "1rem" }}
              >
                <label style={{ flex: 1 }}>
                  Color:
                  <input
                    type="text"
                    value={editProduct.color || ""}
                    onChange={(e) =>
                      setEditProduct({ ...editProduct, color: e.target.value })
                    }
                  />
                </label>

                <label style={{ flex: 1 }}>
                  Tipo:
                  <input
                    type="text"
                    value={editProduct.tipo || ""}
                    onChange={(e) =>
                      setEditProduct({ ...editProduct, tipo: e.target.value })
                    }
                  />
                </label>
              </div> */}

              {stockError && <p className="error-text">{stockError}</p>}

              <div className="modal-buttons">
                <button onClick={handleUpdateProduct} className="save-button">
                  Guardar
                </button>
                <button onClick={closeModal} className="cancel-button">
                  Cancelar
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Modal de agregar producto */}
      {showAddModal && (
        <div className="modal-overlay">
          <div className="modal">
            <div className="modal-description">
              <h2>Crear Nuevo Producto</h2>
              <label>
                Nombre del producto:
                <input
                  type="text"
                  value={newProduct.nombre}
                  onChange={(e) =>
                    setNewProduct({ ...newProduct, nombre: e.target.value })
                  }
                  required
                />
              </label>

              {/* Primera fila: Stock + precio */}
              <div
                style={{ display: "flex", gap: "2rem", marginBottom: "1rem" }}
              >
                <label style={{ flex: 1 }}>
                  Stock inicial:
                  <input
                    type="text"
                    value={newProduct.stock}
                    onChange={(e) => {
                      const val = e.target.value;
                      if (/^\d*$/.test(val)) {
                        setNewProduct({ ...newProduct, stock: val });
                        setAddStockError("");
                      } else {
                        showToast("Solo se permiten números", "error");
                      }
                    }}
                    required
                    min="0"
                    pattern="\\d+"
                  />
                </label>

                <label style={{ flex: 1 }}>
                  Precio:
                  <input
                    type="text"
                    value={newProduct.precio}
                    onChange={(e) =>
                      setNewProduct({ ...newProduct, precio: e.target.value })
                    }
                    required
                  />
                </label>
              </div>

              <label style={{ flex: 1 }}>
                Descripción:
                <input
                  type="text"
                  value={newProduct.descripcion}
                  onChange={(e) =>
                    setNewProduct({
                      ...newProduct,
                      descripcion: e.target.value,
                    })
                  }
                  required
                />
              </label>

              {/* Segunda fila: Color + Tipo
              <div
                style={{ display: "flex", gap: "2rem", marginBottom: "1rem" }}
              >
                <label style={{ flex: 1 }}>
                  Color:
                  <input
                    type="text"
                    value={newProduct.color}
                    onChange={(e) =>
                      setNewProduct({ ...newProduct, color: e.target.value })
                    }
                    required
                  />
                </label>

                <label style={{ flex: 1 }}>
                  Tipo:
                  <input
                    type="text"
                    value={newProduct.tipo}
                    onChange={(e) =>
                      setNewProduct({ ...newProduct, tipo: e.target.value })
                    }
                  />
                </label>
              </div> */}
              <div className="modal-buttons">
                <button onClick={handleAddProduct} className="save-button">
                  Guardar
                </button>
                <button
                  onClick={() => {
                    setShowAddModal(false);
                    setPreviewImage(null);
                  }}
                  className="cancel-button"
                >
                  Cancelar
                </button>
              </div>
            </div>

            <label htmlFor="fileInput" className="image-upload-box">
              {previewImage ? (
                <>
                  <p className="preview-text">Vista previa:</p>
                  <img
                    src={previewImage}
                    alt="Vista previa del producto"
                    className="preview-image"
                  />
                </>
              ) : (
                <p>Haz clic aquí para seleccionar una imagen del producto</p>
              )}

              <input
                id="fileInput"
                type="file"
                accept="image/*"
                onChange={(e) => {
                  const file = e.target.files[0];
                  setNewProduct({ ...newProduct, imagen: file });

                  if (file) {
                    const imageUrl = URL.createObjectURL(file);
                    setPreviewImage(imageUrl);
                  } else {
                    setPreviewImage(null);
                  }
                }}
                style={{ display: "none" }}
              />
            </label>
          </div>
        </div>
      )}
      {isToastVisible && (
        <div className={`toast ${toastType}`}>{toastMessage}</div>
      )}
    </div>
  );
}
