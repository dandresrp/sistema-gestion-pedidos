export const authorizeAdmin = (req, res, next) => {
    if (req.usuario?.rol !== "Administrador") {
        return res.status(403).json({ message: "No tienes permisos para realizar esta acción" });
    }
    next();
};

