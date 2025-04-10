import React from "react";
import "../styles/TableComponent.css";

const TableComponent = ({ data, columns }) => {
  return (
    <div className="table-container-component">
      <table className="report-table">
        <thead>
          <tr>
            {columns.map((col) => (
              <th key={col.id}>{col.header}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {data.map((row, rowIndex) => (
            <tr key={rowIndex}>
              {columns.map((col) => (
                <td key={col.id}>{row[col.id]}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default TableComponent;
