import AppRouter from "./Router";
import AuthProvider from "./provider/AuthProvider";

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
