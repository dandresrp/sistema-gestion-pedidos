import { query } from '../../db.js';
import {
  SQL_GET_INCOME_BY_MONTH,
  SQL_GET_ORDERS_BY_MONTH,
  SQL_GET_PENDING_ORDERS,
  SQL_GET_REJECTED_ORDERS,
  SQL_GET_ORDERS_OUT_OF_TIME,
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
    const result = await query(SQL_GET_INCOME_BY_MONTH);
    res.success(result.rows);
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
