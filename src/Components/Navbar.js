import React from 'react'
import PropTypes from 'prop-types'
import Clock from './Clock'
import {Link} from 'react-router-dom'

export default function Navbar(props) {
 
  return (
    <>
<nav className={`navbar navbar-expand-lg navbar-${props.mode==="light"?"light":"dark"} bg-${props.mode==="light"?"light":"dark"}`}>
  <div className="container-fluid">
    <Link className="navbar-brand" to="/">{props.title}</Link>
    <button className="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
      <span className="navbar-toggler-icon"></span>
    </button>
    <div className="collapse navbar-collapse" id="navbarNav">
    <ul className="navbar-nav me-auto mb-2 mb-lg-0">
        <li className="nav-item">
          <Link className="nav-link active" aria-current="page" to="/">Home</Link>
        </li>
        <li className="nav-item">
          <Link className="nav-link" to="/about">Description</Link>
        </li>
      </ul>
<Clock mode={props.mode}/>
      <div className={`form-check form-switch mx-4 text-${props.mode==='light'?"dark":"light"}`}>
 <input className="form-check-input" type="checkbox" role="switch" onClick={props.toggleMode} id="flexSwitchCheckDefault"/>
 <label className="form-check-label" htmlFor="flexSwitchCheckChecked">{props.mode==="dark"?"Disable Dark Mode":"Enable Dark Mode"}</label>
</div>
  </div>
    </div>
</nav>
</>
  )
}
Navbar.propTypes={title:PropTypes.string};
Navbar.defaultProps={
    title:"set title here"
};
export{}
