import { useContext } from "react";
import AuthContext from "./authContext";

const useAuth = () => {
  return useContext(AuthContext);
};

export default useAuth;
