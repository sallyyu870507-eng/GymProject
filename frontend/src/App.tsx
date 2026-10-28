import {
    Navigate,
    Route,
    Routes
} from "react-router";

import AttendancePage
    from "./pages/attendance/AttendancePage";
import AppLayout
    from "./components/layout/AppLayout";
import RenewalWorkbenchPage
    from "./pages/renewal/RenewalWorkbenchPage";
import RenewalOverviewPage
    from "./pages/renewal/RenewalOverviewPage";
import RenewalFollowupCreatePage
    from "./pages/renewal/RenewalFollowupCreatePage";
import RenewalFollowupEditPage
    from "./pages/renewal/RenewalFollowupEditPage";
import RenewalCreatePage
    from "./pages/renewal/RenewalCreatePage";


function App() {

    return (
        <Routes>

            <Route element={<AppLayout />}>

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

            <Route
                path="/renewal"
                element={<RenewalWorkbenchPage />}
            />

            <Route
                path="/renewal/:memberCourseId"
                element={<RenewalOverviewPage />}
            />

            <Route
                path="/renewal/:memberCourseId/followups/new"
                element={<RenewalFollowupCreatePage />}
            />

            <Route
                path="/renewal/:memberCourseId/followups/:followupId/edit"
                element={<RenewalFollowupEditPage />}
            />

            <Route
                path="/renewal/:memberCourseId/renewals/new"
                element={<RenewalCreatePage />}
            />

            </Route>

        </Routes>
    );
}


export default App;
