target "vanessa-runner" {
  dockerfile = "vanessa-runner/Dockerfile"
  context = "."
  contexts = {
    "localhost/oscript:local" = "target:oscript"
  }
  args = {
    VANESSA_RUNNER_VERSION = "${VANESSA_RUNNER_VERSION}"
  }
  tags = tags("vanessa-runner", VANESSA_RUNNER_VERSION)
  labels = labels("vanessa-runner", "Vanessa Runner ${VANESSA_RUNNER_VERSION}")
  cache_from = cache_from("vanessa-runner")
  cache_to = cache_to("vanessa-runner")
}
