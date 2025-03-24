import React from "react";
import {
  PieChart,
  Pie,
  Cell,
  Tooltip,
  Legend,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  ComposedChart,
  Bar,
  ResponsiveContainer,
} from "recharts";
import "../styles/ChartComponent.css";

const COLORS = ["#173154", "#2B558C", "#2e63ab", "#4E6AA8", "#6181AFFF"];

const ReportChart = ({ type, data, dataKey, lines, barKey, lineKey }) => {
  return (
    <div className="chart-container">
      {type === "pie" ? (
        <ResponsiveContainer>
          <PieChart>
            <Pie
              data={data}
              dataKey={dataKey}
              nameKey="name"
              cx="50%"
              cy="50%"
              outerRadius="70%"
              fill="#8884d8"
              label
            >
              {data.map((_, index) => (
                <Cell
                  key={`cell-${index}`}
                  fill={COLORS[index % COLORS.length]}
                />
              ))}
            </Pie>
            <Tooltip />
            <Legend />
          </PieChart>
        </ResponsiveContainer>
      ) : type === "line" ? (
        <ResponsiveContainer>
          <LineChart data={data}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="name" />
            <YAxis />
            <Tooltip />
            <Legend />
            {lines.map((key, index) => (
              <Line
                key={index}
                type="monotone"
                dataKey={key}
                stroke={COLORS[index % COLORS.length]}
                strokeWidth={2}
              />
            ))}
          </LineChart>
        </ResponsiveContainer>
      ) : type === "bar-line" ? (
        <ResponsiveContainer>
          <ComposedChart data={data}>
            <CartesianGrid strokeDasharray="3 3" />
            <YAxis yAxisId="left" />
            <YAxis yAxisId="right" orientation="right" />
            <Tooltip />
            <Legend />
            {barKey.map((key, index) => (
              <Bar
                key={index}
                yAxisId="left"
                dataKey={key}
                name={index == 0 ? "Pedidos Este Mes" : "Pedidos Mes Anterior"}
                fill={COLORS[index % COLORS.length]}
              />
            ))}
            <Line
              yAxisId="right"
              type="monotone"
              dataKey={lineKey}
              name="% Variación de Utilización"
              stroke="#000"
              strokeWidth={2}
            />
          </ComposedChart>
        </ResponsiveContainer>
      ) : null}
    </div>
  );
};

export default ReportChart;
