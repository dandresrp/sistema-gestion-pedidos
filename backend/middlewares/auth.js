import jwt from 'jsonwebtoken';

export const authenticateJWT = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (authHeader) {
    const token = authHeader.split(' ')[1];

    jwt.verify(token, process.env.JWT_SECRET, (err, usuario) => {
      if (err) {
        return res.sendStatus(403);
      }

      req.usuario = usuario;
      next();
    });
  } else {
    res.sendStatus(401);
  }
};

export const authorizeAdmin = (req, res, next) => {
  if (req.usuario?.rol !== '1') {
    return res
      .status(403)
      .json({ message: 'No tienes permisos para realizar esta acción' });
  }
  next();
};
