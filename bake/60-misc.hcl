target "gitsync" {
  dockerfile = "gitsync/Dockerfile"
  context = "."
  contexts = {
    "localhost/onec-client:local" = "target:client"
    "localhost/oscript:local" = "target:oscript"
  }
  args = {
    gitsync_ver = "${GITSYNC_VERSION}"
  }
  tags = tags("gitsync", GITSYNC_VERSION)
  labels = labels("gitsync", "GitSync ${GITSYNC_VERSION}")
  cache_from = cache_from("gitsync")
  cache_to = cache_to("gitsync")
}

target "vanessa-runner" {
  dockerfile = "vanessa-runner/Dockerfile"
  context = "."
  contexts = {
    "localhost/oscript:local" = "target:oscript"
  }
  args = {
    runner_ver = "${VANESSA_RUNNER_VERSION}"
  }
  tags = tags("vanessa-runner", VANESSA_RUNNER_VERSION)
  labels = labels("vanessa-runner", "Vanessa Runner ${VANESSA_RUNNER_VERSION}")
  cache_from = cache_from("vanessa-runner")
  cache_to = cache_to("vanessa-runner")
}

target "executor" {
  dockerfile = "executor/Dockerfile"
  context = "."
  args = {
    EXECUTOR_VERSION = "${EXECUTOR_VERSION}"
  }
  secret = ["id=dev1c_executor_api_key,env=DEV1C_EXECUTOR_API_KEY"]
  tags = tags("executor", EXECUTOR_VERSION)
  labels = labels("executor", "1C:Enterprise.Element Script executor ${EXECUTOR_VERSION}")
  cache_from = cache_from("executor")
  cache_to = cache_to("executor")
}
