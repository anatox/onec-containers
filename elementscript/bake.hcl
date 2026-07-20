target "elementscript" {
  dockerfile = "elementscript/Dockerfile"
  context = "."
  args = {
    ELEMENTSCRIPT_VERSION = "${ELEMENTSCRIPT_VERSION}"
  }
  secret = ["id=elementscript_download_token,env=ELEMENTSCRIPT_DOWNLOAD_TOKEN"]
  tags = tags("elementscript", ELEMENTSCRIPT_VERSION)
  labels = labels("elementscript", "1C:Enterprise.Element Script ${ELEMENTSCRIPT_VERSION}")
  cache_from = cache_from("elementscript")
  cache_to = cache_to("elementscript")
}
