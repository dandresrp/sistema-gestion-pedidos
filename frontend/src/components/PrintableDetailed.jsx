import React, { forwardRef } from "react";

const PrintableDetailedReport = forwardRef(
  ({ data, columns, title, date1, date2 }, ref) => {
    return (
      <div ref={ref} className="printable-report">
        <h2 style={{ textAlign: "center", marginBottom: "1rem" }}>{title}</h2>

        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            marginBottom: "1rem",
          }}
        >
          <span>
            <strong>Desde:</strong> {date1}
          </span>
          <span>
            <strong>Hasta:</strong> {date2}
          </span>
        </div>

        <table style={{ width: "100%", borderCollapse: "collapse" }}>
          <thead>
            <tr>
              {columns.map((col) => (
                <th
                  key={col.id}
                  style={{
                    borderBottom: "1px solid #000",
                    textAlign: "left",
                    padding: "8px",
                  }}
                >
                  {col.header}
                </th>
              ))}
            </tr>
          </thead>
          <tbody>
            {data.map((row, i) => (
              <tr key={i}>
                {columns.map((col) => (
                  <td
                    key={col.id}
                    style={{
                      padding: "8px",
                      borderBottom: "1px solid #ccc",
                    }}
                  >
                    {row[col.id]}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    );
  }
);

export default PrintableDetailedReport;
