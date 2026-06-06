ui_style <- "
/* body */
body {
  background-color: #FFFFFF; /* Lavender */
}

/* logo */
.skin-blue .main-header .logo {
  background-color: #8993ff; 
}

/* navbar (rest of the header) */
.skin-blue .main-header .navbar {
  background-color: #dbedff; 
}

/* --- keep default header height (safe) --- */
.skin-blue .main-header .logo {
  height: 50px;
  line-height: 50px;
}
.skin-blue .main-header .navbar {
  min-height: 50px;
  height: 50px;
}

/* --- make the header position:relative so absolute centering works --- */
.main-header .navbar {
  position: relative !important;
}

/* --- center the navbar-custom-menu by absolute centering --- */
/* this keeps the element in the header (not below it) */
.main-header .navbar .navbar-custom-menu {
  position: absolute !important;
  left: 50% !important;
  top: 0 !important;
  transform: translateX(-50%) !important;
  height: 50px !important;
  display: flex !important;
  align-items: center !important;
  padding: 0 10px !important;
  z-index: 1000 !important; /* stays above other header parts */
}

/* keep the inner UL inline and not full-width */
.main-header .navbar .navbar-custom-menu .nav {
  display: inline-flex !important;
  align-items: center !important;
  margin: 0 !important;
  padding: 0 !important;
}

/* shrink the radio form-group so it fits the 50px height */
.main-header .navbar .navbar-custom-menu .dropdown .form-group {
  margin: 0 !important;
  padding: 0 !important;
  height: auto !important;
  display: inline-flex !important;
  align-items: center !important;
}

/* small spacing and font for labels so they fit comfortably */
.main-header .navbar .dropdown .radio-inline label {
  font-weight: 600 !important;
  font-size: 14px !important;
  color: #2b2b2b !important;
  padding: 0 8px !important;
  line-height: 1 !important;
}

/* remove default top/bottom margins for radio-inline */
.main-header .navbar .dropdown .radio-inline {
  margin: 0 16px !important;
  padding: 0 !important;
}

/* keep the left sidebar toggle and logo untouched */
.main-header .navbar .sidebar-toggle {
  height: 50px !important;
  line-height: 50px !important;
}

/* responsive fallback: on very small screens, let it revert to normal flow */
@media (max-width: 700px) {
  .main-header .navbar .navbar-custom-menu {
    position: static !important;
    transform: none !important;
    width: auto !important;
  }
  .main-header .navbar .navbar-custom-menu .nav {
    display: flex !important;
    justify-content: flex-end !important;
  }
}

/* Make navbar items evenly centered */
.main-header .navbar .navbar-custom-menu {
  display: flex !important;
  align-items: center !important;
}

/* Fix sidebar toggle icon alignment */
.main-header .sidebar-toggle {
  height: 50px !important;        /* match header height */
  line-height: 50px !important;   /* vertical center */
  padding-top: 0 !important;
  padding-bottom: 0 !important;
  display: flex !important;
  align-items: center !important;
}

/* Ensure icon itself is centered */
.main-header .sidebar-toggle .fa-bars {
  margin-top: 0 !important;
  margin-bottom: 0 !important;
}

/* Adjust general legend container width and ensure content wraps */
.info.legend.leaflet-control {
  width: 130px; /* Example width */
  white-space: normal; /* Allow text to wrap */
}

/* Adjust width of the color boxes if needed */
.legend i {
  height: 100px; /* Adjust height as needed */
  width: 30px;
}
"