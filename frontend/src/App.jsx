import AppRouter from "./Router";
import AuthProvider from "./provider/authProvider";

function App() {
  return (
    <div>
      <AuthProvider>
        <AppRouter />
      </AuthProvider>
    </div>
  );
}

export default App;
