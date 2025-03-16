export const responseHandler = (req, res, next) => {
  res.success = (data, message, statusCode = 200) => {
    res.status(statusCode).json({
      success: true,
      data,
      message,
    });
  };

  res.error = (message, statusCode = 500) => {
    res.status(statusCode).json({
      success: false,
      message,
    });
  };

  next();
};
