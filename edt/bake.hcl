target "edt" {
  inherits = ["_defaults"]
  target = "final"
  dockerfile = "edt/Dockerfile"
  contexts = {
    "localhost/onec-installer:local" = "target:installer"
  }
  args = {
    EDT_VERSION = "${EDT_VERSION}"
  }
  secret = ["id=onec_username,env=ONEC_USERNAME", "id=onec_password,env=ONEC_PASSWORD"]
  tags = tags("edt", EDT_VERSION)
  labels = {
    "org.opencontainers.image.title" = "1C:Enterprise Development Tools"
    "org.opencontainers.image.version" = EDT_VERSION
  }
  description = jsonencode({"image" = "edt", "extra-srcs" = ["scripts/install-edt-jdk.sh", "scripts/install-edt-nginx.sh"]})
  cache_from = cache_from("edt")
  cache_to = cache_to("edt")
}

target "edt-toolbox" {
  inherits = ["_defaults"]
  target = "toolbox"
  dockerfile = "edt/Dockerfile"
  contexts = {
    "localhost/onec-installer:local" = "target:installer"
  }
  args = {
    EDT_VERSION = "${EDT_VERSION}"
  }
  secret = ["id=onec_username,env=ONEC_USERNAME", "id=onec_password,env=ONEC_PASSWORD"]
  tags = tags("edt-toolbox", EDT_VERSION)
  labels = {
    "org.opencontainers.image.title" = "1C:Enterprise Development Tools toolbox"
    "org.opencontainers.image.version" = EDT_VERSION
  }
  description = jsonencode({"image" = "edt-toolbox", "extra-srcs" = ["scripts/install-edt-jdk.sh", "scripts/install-edt-nginx.sh", "scripts/distrobox-shims.sh"]})
  cache_from = cache_from("edt-toolbox")
  cache_to = cache_to("edt-toolbox")
}

target "edt-toolbox-client" {
  inherits = ["_defaults"]
  dockerfile = "client/Dockerfile"
  target = "base"
  contexts = {
    "localhost/onec-installer:local" = "target:installer"
    "localhost/edt-toolbox:${EDT_VERSION}" = "target:edt-toolbox"
  }
  args = {
    BASE_IMAGE = "localhost/edt-toolbox:${EDT_VERSION}"
    ONEC_VERSION = "${ONEC_VERSION}"
    NLS_ENABLED = "${NLS_ENABLED}"
  }
  secret = ["id=onec_username,env=ONEC_USERNAME", "id=onec_password,env=ONEC_PASSWORD"]
  tags = tags("edt-toolbox", "${EDT_VERSION}-client${ONEC_VERSION}")
  labels = {
    "org.opencontainers.image.title" = "1C:Enterprise Development Tools + client"
    "org.opencontainers.image.version" = "${EDT_VERSION}-client${ONEC_VERSION}"
  }
  description = jsonencode({"image" = "edt-toolbox"})
  cache_from = cache_from("edt-toolbox")
  cache_to = cache_to("edt-toolbox")
}

target "edt-s6" {
  inherits = ["_defaults"]
  dockerfile = "s6-overlay/Dockerfile"
  contexts = {
    "localhost/edt:local" = "target:edt"
  }
  args = {
    BASE_IMAGE = "localhost/edt:local"
    S6_OVERLAY_VERSION = "${S6_OVERLAY_VERSION}"
  }
  tags = tags("edt-s6", EDT_VERSION)
  labels = {
    "org.opencontainers.image.title" = "1C:Enterprise Development Tools + s6 overlay"
    "org.opencontainers.image.version" = EDT_VERSION
  }
  description = jsonencode({"image" = "edt-s6"})
  cache_from = cache_from("edt-s6")
  cache_to = cache_to("edt-s6")
}
