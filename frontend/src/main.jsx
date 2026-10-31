import React from 'react'
import { createRoot } from 'react-dom/client'
import App from './App.jsx'
import NotificationHost from './components/NotificationHost.jsx'
import './App.css'
import './integration.css'
import { createBrowserRouter, RouterProvider } from 'react-router'

const router = createBrowserRouter([{ path: '*', element: <App /> }])
createRoot(document.getElementById('root')).render(<><RouterProvider router={router} /><NotificationHost /></>)
