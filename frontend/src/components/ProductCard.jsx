import React from "react";
import "../styles/ProductCard.css";

export default function ProductCard({ product, onEdit }) {
  return (
    <div className="product-card" key={product.id}>
      <div className="product-image-container">
        <img
          src={product.imagen}
          alt={product.nombre}
          className="product-image"
        />
      </div>
      <div className="product-info">
        <h3>{product.nombre}</h3>
        <p>
          <strong>Stock:</strong>{" "}
          <span
            className={`stock-count ${product.stock <= 5 ? "low-stock" : ""}`}
          >
            {product.stock}
          </span>
        </p>
        <button className="edit-button" onClick={() => onEdit(product)}>
          Editar
        </button>
      </div>
    </div>
  );
}
