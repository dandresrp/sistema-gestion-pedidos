import logo from "../assets/image 1.png";
import { useState, useEffect } from "react";
import "../styles/DetailedReport.css";

const Footer = () => {
  const fecha = new Date().toLocaleDateString();
  return (
    <div className="report-footer">
      <p>Fecha de emisión: {fecha}</p>
    </div>
  );
};

const DetailedReports = ({
  title = "Reporte",
  data = [],
  columns = [],
  recordsPerPage = 20,
  date1 = "01/03/2025",
  date2 = new Date().toLocaleDateString(),
}) => {
  const [currentPage, setCurrentPage] = useState(1);
  const [paginatedData, setPaginatedData] = useState([]);
  const [totalPages, setTotalPages] = useState(1);

  // Si no se proporcionan columnas, se generan automáticamente de la primera fila de la data
  const tableColumns =
    columns.length > 0
      ? columns
      : data.length > 0
      ? Object.keys(data[0]).map((key) => ({
          id: key,
          header: key.charAt(0).toUpperCase() + key.slice(1),
        }))
      : [];

  // Actualizar paginación
  useEffect(() => {
    if (!Array.isArray(data)) {
      console.error("Error: data no es un array", data);
      return;
    }

    const totalPages = Math.ceil(data.length / recordsPerPage);
    setTotalPages(totalPages || 1);

    if (currentPage > totalPages) {
      setCurrentPage(totalPages || 1);
    }

    const startIndex = (currentPage - 1) * recordsPerPage;
    const endIndex = startIndex + recordsPerPage;
    setPaginatedData(data.slice(startIndex, endIndex));
  }, [data, currentPage, recordsPerPage]);

  // Manejar el cambio de página
  const handlePageChange = (page) => {
    setCurrentPage(page);
  };

  // Generar números de página
  const getPageNumbers = () => {
    const pageNumbers = [];
    const maxPageButtons = 5; // Mostrar como maximo 5 botones

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

  return (
    <div className="reports-container">
      <div className="reports-header">
        <div className="header-row">
          <div className="company-logo">
            <img src={logo} alt="Logo de la empresa" />
          </div>
          <div className="report-title">
            <h2>{title}</h2>
          </div>
          <div className="report-period">
            <span>
              Desde: <strong>{date1}</strong>
            </span>
            <br />
            <span>
              Hasta: <strong>{date2}</strong>
            </span>
          </div>
        </div>
      </div>

      <div className="table-container">
        <table className="reports-table">
          <thead>
            <tr>
              {tableColumns.map((column) => (
                <th key={column.id}>{column.header}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {paginatedData.length > 0 ? (
              paginatedData.map((row, rowIndex) => (
                <tr key={rowIndex}>
                  {tableColumns.map((column) => (
                    <td key={`${rowIndex}-${column.id}`}>
                      {column.isCurrency ? (
                        <div
                          style={{
                            display: "flex",
                            justifyContent: "space-between",
                            width: "100%",
                          }}
                        >
                          <span>Lps.</span>
                          <span>
                            {parseFloat(row[column.id]).toLocaleString(
                              "es-HN",
                              {
                                minimumFractionDigits: 2,
                                maximumFractionDigits: 2,
                              }
                            )}
                          </span>
                        </div>
                      ) : (
                        row[column.id]
                      )}
                    </td>
                  ))}
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan={tableColumns.length} className="no-data">
                  No hay datos disponibles
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {data.length > recordsPerPage && (
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

      {/* Aquí agregamos el Footer */}
      <Footer />
    </div>
  );
};

export default DetailedReports;
