import {
    Navigate,
    Route,
    Routes
} from "react-router";

import AttendancePage
    from "./pages/attendance/AttendancePage";


function App() {

    return (
        <Routes>

            <Route
                path="/"
                element={
                    <Navigate
                        to="/attendance"
                        replace
                    />
                }
            />

            <Route
                path="/attendance"
                element={<AttendancePage />}
            />

        </Routes>
    );
}


export default App;