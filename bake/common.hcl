variable "REGISTRY_PREFIX" { default = "" }
variable "GIT_SHA" { default = "" }
variable "PUBLISH_LATEST" { default = "false" }
variable "CACHE_PREFIX" { default = "" }
variable "CACHE_TO" { default = "" }
variable "NLS_ENABLED" { default = "true" }
variable "TEST_UTILS_EXTRA_PACKAGES" { default = "" }

function "shortver" {
  params = [v]
  result = join(".", slice(split(".", v), 0, length(split(".", v)) - 1))
}

function "tags" {
  params = [image, version]
  result = flatten([
    ["localhost/${image}:local", "localhost/${image}:${version}", "localhost/${image}:${shortver(version)}"],
    REGISTRY_PREFIX != "" ? ["${REGISTRY_PREFIX}/${image}:${version}", "${REGISTRY_PREFIX}/${image}:${shortver(version)}"] : [],
    REGISTRY_PREFIX != "" && GIT_SHA != "" ? ["${REGISTRY_PREFIX}/${image}:${version}-g${substr(GIT_SHA, 0, 7)}"] : [],
    REGISTRY_PREFIX != "" && PUBLISH_LATEST == "true" ? ["${REGISTRY_PREFIX}/${image}:latest"] : [],
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

function "labels" {
  params = [image, title]
  result = {
    "org.opencontainers.image.title" = title
    "org.opencontainers.image.authors" = "Anatolii Sereda <3011745+anatox@users.noreply.github.com>"
    "onec.image" = image
  }
}

function "agent_tags" {
  params = [image, version, platform]
  result = flatten([
    ["localhost/${image}:local-${platform}", "localhost/${image}:${version}-${platform}", "localhost/${image}:${shortver(version)}-${platform}"],
    REGISTRY_PREFIX != "" ? ["${REGISTRY_PREFIX}/${image}:${version}-${platform}", "${REGISTRY_PREFIX}/${image}:${shortver(version)}-${platform}"] : [],
    REGISTRY_PREFIX != "" && GIT_SHA != "" ? ["${REGISTRY_PREFIX}/${image}:${version}-g${substr(GIT_SHA, 0, 7)}-${platform}"] : [],
    REGISTRY_PREFIX != "" && PUBLISH_LATEST == "true" ? ["${REGISTRY_PREFIX}/${image}:${platform}"] : [],
  ])
}
