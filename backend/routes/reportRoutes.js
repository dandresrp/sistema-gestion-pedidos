import express from 'express';
import { authenticateJWT, authorizeAdmin } from '../middlewares/auth.js';
import { validateDates } from '../middlewares/validateDates.js';
import * as reportController from '../controllers/report/reportController.js';

const router = express.Router();

/**
 * @swagger
 * /api/reportes/orders-by-month:
 *   get:
 *     summary: Obtener pedidos por mes
 *     tags: [Reportes]
 *     parameters:
 *       - in: query
 *         name: startDate
 *         description: Fecha de inicio para filtrar pedidos ('2025-01-01')
 *         schema:
 *           type: string
 *       - in: query
 *         name: endDate
 *         description: Fecha final para filtrar pedidos ('2025-01-31')
 *         schema:
 *           type: string
 *       - in: query
 *         name: offset
 *         description: Número de registros a omitir para la paginación
 *         schema:
 *           type: integer
 *       - in: query
 *         name: limit
 *         description: Número máximo de resultados a devolver
 *         schema:
 *           type: integer
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de pedidos filtrados por mes
 *       401:
 *         description: No autorizado
 *       500:
 *         description: Error del servidor
 */
router.get(
  '/orders-by-month',
  [authenticateJWT, validateDates],
  reportController.getOrdersByMonth,
);

/**
 * @swagger
 * /api/reportes/income-by-month:
 *   get:
 *     summary: Obtener ingresos por mes
 *     tags: [Reportes]
 *     parameters:
 *       - in: query
 *         name: startDate
 *         description: Fecha de inicio para filtrar ingresos ('2025-01-01')
 *         schema:
 *           type: string
 *       - in: query
 *         name: endDate
 *         description: Fecha final para filtrar ingresos ('2025-01-31')
 *         schema:
 *           type: string
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de ingresos filtrados por mes
 *       401:
 *         description: No autorizado
 *       500:
 *         description: Error del servidor
 */
router.get(
  '/income-by-month',
  [authenticateJWT, validateDates],
  reportController.getIncomeByMonth,
);

/**
 * @swagger
 * /api/reportes/pending-orders:
 *   get:
 *     summary: Obtener pedidos pendientes
 *     tags: [Reportes]
 *     parameters:
 *       - in: query
 *         name: startDate
 *         description: Fecha de inicio para filtrar pedidos ('2025-01-01')
 *         schema:
 *           type: string
 *       - in: query
 *         name: endDate
 *         description: Fecha final para filtrar pedidos ('2025-01-31')
 *         schema:
 *           type: string
 *       - in: query
 *         name: offset
 *         description: Número de registros a omitir para la paginación
 *         schema:
 *           type: integer
 *       - in: query
 *         name: limit
 *         description: Número máximo de resultados a devolver
 *         schema:
 *           type: integer
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de pedidos filtrados por mes
 *       401:
 *         description: No autorizado
 *       500:
 *         description: Error del servidor
 */
router.get(
  '/pending-orders',
  [authenticateJWT, validateDates],
  reportController.getPendingOrders,
);

/**
 * @swagger
 * /api/reportes/rejected-orders:
 *   get:
 *     summary: Obtener pedidos rechazados
 *     tags: [Reportes]
 *     parameters:
 *       - in: query
 *         name: startDate
 *         description: Fecha de inicio para filtrar pedidos ('2025-01-01')
 *         schema:
 *           type: string
 *       - in: query
 *         name: endDate
 *         description: Fecha final para filtrar pedidos ('2025-01-31')
 *         schema:
 *           type: string
 *       - in: query
 *         name: offset
 *         description: Número de registros a omitir para la paginación
 *         schema:
 *           type: integer
 *       - in: query
 *         name: limit
 *         description: Número máximo de resultados a devolver
 *         schema:
 *           type: integer
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de pedidos filtrados por mes
 *       401:
 *         description: No autorizado
 *       500:
 *         description: Error del servidor
 */
router.get(
  '/rejected-orders',
  [authenticateJWT, validateDates],
  reportController.getRejectedOrders,
);

/**
 * @swagger
 * /api/reportes/orders-out-of-time:
 *   get:
 *     summary: Obtener pedidos fuera de tiempo
 *     tags: [Reportes]
 *     parameters:
 *       - in: query
 *         name: startDate
 *         description: Fecha de inicio para filtrar pedidos ('2025-01-01')
 *         schema:
 *           type: string
 *       - in: query
 *         name: endDate
 *         description: Fecha final para filtrar pedidos ('2025-01-31')
 *         schema:
 *           type: string
 *       - in: query
 *         name: offset
 *         description: Número de registros a omitir para la paginación
 *         schema:
 *           type: integer
 *       - in: query
 *         name: limit
 *         description: Número máximo de resultados a devolver
 *         schema:
 *           type: integer
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de pedidos filtrados por mes
 *       401:
 *         description: No autorizado
 *       500:
 *         description: Error del servidor
 */
router.get(
  '/orders-out-of-time',
  [authenticateJWT, validateDates],
  reportController.getOrdersOutOfTime,
);

/**
 * @swagger
 * /api/reportes/best-selling-products-history:
 *   get:
 *     summary: Obtener historial de productos más vendidos
 *     tags: [Reportes]
 *     parameters:
 *       - in: query
 *         name: startDate
 *         description: Fecha de inicio para filtrar productos ('2025-01-01')
 *         schema:
 *           type: string
 *       - in: query
 *         name: endDate
 *         description: Fecha final para filtrar productos ('2025-01-31')
 *         schema:
 *           type: string
 *       - in: query
 *         name: offset
 *         description: Número de registros a omitir para la paginación
 *         schema:
 *           type: integer
 *       - in: query
 *         name: limit
 *         description: Número máximo de resultados a devolver
 *         schema:
 *           type: integer
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de productos más vendidos
 *       401:
 *         description: No autorizado
 *       500:
 *         description: Error del servidor
 */
router.get(
  '/best-selling-products-history',
  [authenticateJWT, validateDates],
  reportController.getBestSellingProductsHistory,
);

/**
 * @swagger
 * /api/reportes/inventory:
 *   get:
 *     summary: Obtener inventario de productos
 *     tags: [Reportes]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de productos más vendidos
 *       401:
 *         description: No autorizado
 *       500:
 *         description: Error del servidor
 */
router.get('/inventory', [authenticateJWT], reportController.getInventory);

/**
 * @swagger
 * /api/reportes/production-capacity:
 *   get:
 *     summary: Obtener capacidad de producción
 *     tags: [Reportes]
 *     parameters:
 *       - in: query
 *         name: startDate
 *         description: Fecha de inicio para filtrar productos ('2025-01-01')
 *         schema:
 *           type: string
 *       - in: query
 *         name: endDate
 *         description: Fecha final para filtrar productos ('2025-01-31')
 *         schema:
 *           type: string
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de capacidad de producción
 *       401:
 *         description: No autorizado
 *       500:
 *         description: Error del servidor
 */
router.get(
  '/production-capacity',
  [authenticateJWT, validateDates],
  reportController.getProductionCapacity,
);

export default router;
