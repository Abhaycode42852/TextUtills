import './App.css';
import About from './Components/About';
import Navbar from './Components/Navbar';
import Alert from './Components/Alert';
import TextForm from './Components/TextForm';
import React, { useState } from 'react'
import {
  BrowserRouter as Router,
  Route,
  Routes
} from "react-router-dom";

function App() {
  const [mode,setMode]=useState('light');
  const [alert,setAlert]=useState(null);
  const showAlert=(message,type)=>{
    setAlert({
      msg:message,
      type:type
    })
    setTimeout(() => {
      setAlert(null);
    }, 1500);
  }
  const toggleMode=()=>{
    if (mode==="dark"){
      setMode('light');
      document.body.style.backgroundColor="antiquewhite";
      showAlert("Light mode enabled","success")
    }
    else{
      setMode('dark');
      document.body.style.backgroundColor="#042743";
      showAlert("Dark mode enabled","success")
    }
  }
  return (<><Router>
            <Navbar title="TextUtiles" mode={mode} toggleMode={toggleMode}/>
            <Alert alert={alert}/>
          <Routes>
          <Route exact path="/about"
            element={<About mode={mode}/>}/>
          <Route exact path="/"
            element={<TextForm heading="Enter Text " mode={mode} showAlert={showAlert}/>}/>
        </Routes>
            </Router>
            
  </>
  );
}

export default App;
