import jwt from "jsonwebtoken";

export const authenticateJWT = (req, res, next) => {
    const authHeader = req.headers.authorization;

    if (authHeader) {
        const token = authHeader.split(" ")[1];

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