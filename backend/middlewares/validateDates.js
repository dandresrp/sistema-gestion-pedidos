export const validateDates = (req, res, next) => {
  const { startDate, endDate } = req.query;

  const isValidDate = dateString => {
    const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
    return dateRegex.test(dateString);
  };

  if (startDate && !isValidDate(startDate)) {
    return res.error('Fecha de inicio inválida. Formato correcto: YYYY-MM-DD');
  }

  if (endDate && !isValidDate(endDate)) {
    return res.error('Fecha de fin inválida. Formato correcto: YYYY-MM-DD');
  }

  next();
};
