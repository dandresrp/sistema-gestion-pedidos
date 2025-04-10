import { query } from '../../config/database/db.js';
import {
  SQL_GET_INCOME_BY_MONTH,
  SQL_GET_ORDERS_BY_MONTH,
  SQL_GET_PENDING_ORDERS,
  SQL_GET_REJECTED_ORDERS,
  SQL_GET_ORDERS_OUT_OF_TIME,
  SQL_GET_BEST_SELLING_PRODUCTS_HISTORY,
  SQL_GET_INVENTORY,
  SQL_GET_PRODUCTION_CAPACITY,
} from './sql.js';

export const getOrdersByMonth = async (req, res) => {
  try {
    const { startDate, endDate, offset, limit } = req.query;

    const result = await query(SQL_GET_ORDERS_BY_MONTH, [
      startDate || null,
      endDate || null,
      offset || null,
      limit || null,
    ]);
    res.success(result.rows);
  } catch (error) {
    console.error('Error fetching orders by month:', error);
    res.error('Error al obtener pedidos realizados por mes');
  }
};

export const getIncomeByMonth = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    const result = await query(SQL_GET_INCOME_BY_MONTH, [
      startDate || null,
      endDate || null,
    ]);

    const resultFormatted = result.rows.map(row => {
      const date = new Date(row.month);

      const monthNames = [
        'Enero',
        'Febrero',
        'Marzo',
        'Abril',
        'Mayo',
        'Junio',
        'Julio',
        'Agosto',
        'Septiembre',
        'Octubre',
        'Noviembre',
        'Diciembre',
      ];

      const formattedDate = `${monthNames[date.getMonth()]} ${date.getFullYear()}`;

      return {
        ...row,
        month: formattedDate,
      };
    });

    res.success(resultFormatted);
  } catch (error) {
    console.error('Error fetching income by month:', error);
    res.error('Error al obtener ingresos por mes');
  }
};

export const getPendingOrders = async (req, res) => {
  try {
    const { startDate, endDate, offset, limit } = req.query;

    const result = await query(SQL_GET_PENDING_ORDERS, [
      startDate || null,
      endDate || null,
      offset || null,
      limit || null,
    ]);
    res.success(result.rows);
  } catch (error) {
    console.error('Error fetching pending orders:', error);
    res.error('Error al obtener pedidos pendientes');
  }
};

export const getRejectedOrders = async (req, res) => {
  try {
    const { startDate, endDate, offset, limit } = req.query;

    const result = await query(SQL_GET_REJECTED_ORDERS, [
      startDate || null,
      endDate || null,
      offset || null,
      limit || null,
    ]);
    res.success(result.rows);
  } catch (error) {
    console.error('Error fetching rejected orders:', error);
    res.error('Error al obtener pedidos rechazados');
  }
};

export const getOrdersOutOfTime = async (req, res) => {
  try {
    const { startDate, endDate, offset, limit } = req.query;

    const result = await query(SQL_GET_ORDERS_OUT_OF_TIME, [
      startDate || null,
      endDate || null,
      offset || null,
      limit || null,
    ]);
    res.success(result.rows);
  } catch (error) {
    console.error('Error fetching orders out of time:', error);
    res.error('Error al obtener pedidos fuera de tiempo');
  }
};

export const getBestSellingProductsHistory = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;

    const result = await query(SQL_GET_BEST_SELLING_PRODUCTS_HISTORY, [
      startDate || null,
      endDate || null,
    ]);

    if (!result.rows || result.rows.length === 0) {
      return res.success(
        'No se encontraron productos vendidos en el rango de fechas seleccionado',
      );
    }

    res.success(result.rows);
  } catch (error) {
    console.error('Error fetching best selling products history:', error);
    res.error('Error al obtener historial de productos más vendidos');
  }
};

export const getInventory = async (req, res) => {
  try {
    const result = await query(SQL_GET_INVENTORY);
    res.success(result.rows);
  } catch (error) {
    console.error('Error fetching inventory:', error);
    res.error('Error al obtener el inventario');
  }
};

export const getProductionCapacity = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    const result = await query(SQL_GET_PRODUCTION_CAPACITY, [
      startDate || null,
      endDate || null,
    ]);

    const formattedResult = result.rows.map(row => {
      const date = new Date(row.mes);

      const monthNames = [
        'Enero',
        'Febrero',
        'Marzo',
        'Abril',
        'Mayo',
        'Junio',
        'Julio',
        'Agosto',
        'Septiembre',
        'Octubre',
        'Noviembre',
        'Diciembre',
      ];

      const formattedDate = `${monthNames[date.getMonth()]} ${date.getFullYear()}`;

      return {
        ...row,
        mes: formattedDate,
      };
    });

    res.success(formattedResult);
  } catch (error) {
    console.error('Error fetching production capacity:', error);
    res.error('Error al obtener la capacidad de producción');
  }
};
