target "edt" {
  target = "final"
  dockerfile = "edt/Dockerfile"
  context = "."
  contexts = {
    "localhost/onec-installer:local" = "target:installer"
  }
  args = {
    EDT_VERSION = "${EDT_VERSION}"
  }
  secret = ["id=onec_username,env=ONEC_USERNAME", "id=onec_password,env=ONEC_PASSWORD"]
  tags = tags("edt", EDT_VERSION)
  labels = labels("edt", EDT_VERSION, "1C:Enterprise Development Tools")
  description = jsonencode({"extra-srcs" = ["scripts/install-edt-jdk.sh", "scripts/install-edt-nginx.sh"]})
  cache_from = cache_from("edt")
  cache_to = cache_to("edt")
}

target "edt-s6" {
  dockerfile = "s6-overlay/Dockerfile"
  context = "."
  contexts = {
    "localhost/edt:local" = "target:edt"
  }
  args = {
    BASE_IMAGE = "localhost/edt:local"
    S6_OVERLAY_VERSION = "${S6_OVERLAY_VERSION}"
  }
  tags = tags("edt-s6", EDT_VERSION)
  labels = labels("edt-s6", EDT_VERSION, "1C:Enterprise Development Tools + s6 overlay")
  cache_from = cache_from("edt-s6")
  cache_to = cache_to("edt-s6")
}
