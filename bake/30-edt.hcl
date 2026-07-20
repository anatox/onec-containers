target "edt" {
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
  labels = labels("edt", "1C:Enterprise Development Tools ${EDT_VERSION}")
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
  }
  tags = tags("edt-s6", EDT_VERSION)
  labels = merge(labels("edt-s6", "s6 overlay on EDT ${EDT_VERSION}"), {
    "onec.skip-publish" = "true"
  })
  cache_from = cache_from("edt-s6")
  cache_to = cache_to("edt-s6")
}
