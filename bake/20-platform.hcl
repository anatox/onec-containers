target "server" {
  dockerfile = "server/Dockerfile"
  context = "."
  contexts = {
    "localhost/onec-installer:local" = "target:installer"
  }
  args = {
    ONEC_VERSION = "${ONEC_VERSION}"
  }
  secret = ["id=onec_username,env=ONEC_USERNAME", "id=onec_password,env=ONEC_PASSWORD"]
  tags = tags("onec-server", ONEC_VERSION)
  labels = labels("onec-server", "1C:Enterprise server ${ONEC_VERSION}")
  cache_from = cache_from("onec-server")
  cache_to = cache_to("onec-server")
}

target "client" {
  dockerfile = "client/Dockerfile"
  context = "."
  contexts = {
    "localhost/onec-installer:local" = "target:installer"
  }
  args = {
    ONEC_VERSION = "${ONEC_VERSION}"
    NLS_ENABLED = "${NLS_ENABLED}"
  }
  secret = ["id=onec_username,env=ONEC_USERNAME", "id=onec_password,env=ONEC_PASSWORD"]
  tags = tags("onec-client", ONEC_VERSION)
  labels = labels("onec-client", "1C:Enterprise thick client ${ONEC_VERSION}")
  cache_from = cache_from("onec-client")
  cache_to = cache_to("onec-client")
}

target "thin-client" {
  dockerfile = "thin-client/Dockerfile"
  context = "."
  contexts = {
    "localhost/onec-installer:local" = "target:installer"
  }
  args = {
    ONEC_VERSION = "${ONEC_VERSION}"
    NLS_ENABLED = "${NLS_ENABLED}"
  }
  secret = ["id=onec_username,env=ONEC_USERNAME", "id=onec_password,env=ONEC_PASSWORD"]
  tags = tags("thin-client", ONEC_VERSION)
  labels = labels("thin-client", "1C:Enterprise thin client ${ONEC_VERSION}")
  cache_from = cache_from("thin-client")
  cache_to = cache_to("thin-client")
}

target "crs" {
  dockerfile = "crs/Dockerfile"
  context = "."
  contexts = {
    "localhost/onec-installer:local" = "target:installer"
  }
  args = {
    ONEC_VERSION = "${ONEC_VERSION}"
  }
  secret = ["id=onec_username,env=ONEC_USERNAME", "id=onec_password,env=ONEC_PASSWORD"]
  tags = tags("crs", ONEC_VERSION)
  labels = labels("crs", "1C:Enterprise CRS ${ONEC_VERSION}")
  cache_from = cache_from("crs")
  cache_to = cache_to("crs")
}

target "crs-apache" {
  dockerfile = "crs-apache/Dockerfile"
  context = "."
  contexts = {
    "localhost/crs:local" = "target:crs"
  }
  tags = tags("crs-apache", ONEC_VERSION)
  labels = labels("crs-apache", "1C:Enterprise CRS+Apache ${ONEC_VERSION}")
  cache_from = cache_from("crs-apache")
  cache_to = cache_to("crs-apache")
}

target "rac-gui" {
  dockerfile = "rac-gui/Dockerfile"
  context = "."
  contexts = {
    "localhost/onec-server:local" = "target:server"
  }
  tags = tags("rac-gui", ONEC_VERSION)
  labels = labels("rac-gui", "RAC GUI for 1C:Enterprise server ${ONEC_VERSION}")
  cache_from = cache_from("rac-gui")
  cache_to = cache_to("rac-gui")
}
