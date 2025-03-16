import logo from "../assets/image 1.png";
import { useState, useEffect } from "react";
import "../styles/DetailedReport.css";

const DetailedReports = ({
  title = "Reporte",
  data = [],
  columns = [],
  recordsPerPage = 20,
  date1 = "01/01/2023",
  date2 = "31/02/2023",
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
          accessor: key,
        }))
      : [];

  // Actualizar paginación
  useEffect(() => {
    const totalPages = Math.ceil(data.length / recordsPerPage);
    setTotalPages(totalPages || 1);

    // Asegurarse de que la pagina actual sea valida
    if (currentPage > totalPages) {
      setCurrentPage(totalPages || 1);
    }

    // Cortar los datos en función de la página actual
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
        <div className="header-top-row">
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
                      {row[column.accessor]}
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
    </div>
  );
};

export default DetailedReports;
