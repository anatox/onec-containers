variable "REGISTRY_PREFIX" { default = "" }
variable "GIT_SHA" { default = "" }
variable "PUBLISH_LATEST" { default = "false" }
variable "CACHE_PREFIX" { default = "" }
variable "CACHE_TO" { default = "" }
variable "NLS_ENABLED" { default = "true" }
variable "TEST_UTILS_EXTRA_PACKAGES" { default = "" }
variable "DEBUG_TRACE" { default = "0" }

function "shortver" {
  params = [v]
  result = join(".", slice(split(".", v), 0, length(split(".", v)) - 1))
}

function "tags" {
  params = [image, version]
  result = flatten([
    REGISTRY_PREFIX == "" ? ["localhost/${image}:local", "localhost/${image}:${version}", "localhost/${image}:${shortver(version)}"] : [],
    REGISTRY_PREFIX != "" ? ["${REGISTRY_PREFIX}/${image}:${version}", "${REGISTRY_PREFIX}/${image}:${shortver(version)}"] : [],
    GIT_SHA != "" ? ["${REGISTRY_PREFIX != "" ? REGISTRY_PREFIX : "localhost"}/${image}:${version}-sha-${substr(GIT_SHA, 0, 7)}"] : [],
    REGISTRY_PREFIX != "" && PUBLISH_LATEST == "true" ? ["${REGISTRY_PREFIX}/${image}:latest"] : [],
  ])
}

function "tags_suffixed" {
  params = [image, version, suffix]
  result = flatten([
    REGISTRY_PREFIX == "" ? ["localhost/${image}:local-${suffix}", "localhost/${image}:${version}-${suffix}", "localhost/${image}:${shortver(version)}-${suffix}"] : [],
    REGISTRY_PREFIX != "" ? ["${REGISTRY_PREFIX}/${image}:${version}-${suffix}", "${REGISTRY_PREFIX}/${image}:${shortver(version)}-${suffix}"] : [],
    GIT_SHA != "" ? ["${REGISTRY_PREFIX != "" ? REGISTRY_PREFIX : "localhost"}/${image}:${version}-${suffix}-sha-${substr(GIT_SHA, 0, 7)}"] : [],
    REGISTRY_PREFIX != "" && PUBLISH_LATEST == "true" ? ["${REGISTRY_PREFIX}/${image}:latest-${suffix}"] : [],
  ])
}

function "cache_from" {
  params = [name]
  result = REGISTRY_PREFIX != "" ? ["type=registry,ref=${REGISTRY_PREFIX}/cache/${name}:main"] : []
}

function "cache_to" {
  params = [name]
  result = CACHE_TO == "true" && REGISTRY_PREFIX != "" ? ["type=registry,ref=${REGISTRY_PREFIX}/cache/${name}:main,mode=max"] : []
}

# Placeholder so `inherits = ["docker-metadata-action"]` resolves for --print/plan
# purposes. In CI, docker/metadata-action's generated bake file (passed via -f
# after this one) supplies the real labels/annotations and overrides this stub.
target "docker-metadata-action" {}

# Shared build defaults every target inherits. Chains through
# docker-metadata-action so each real target only needs `inherits = ["_defaults"]`.
target "_defaults" {
  inherits = ["docker-metadata-action"]
  context = "."
  args = {
    DEBUG_TRACE = "${DEBUG_TRACE}"
  }
}
