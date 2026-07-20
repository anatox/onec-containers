variable "ONEC_VERSION" { default = "8.5.1.1343" }
variable "EDT_VERSION" { default = "2026.1.2" }

# renovate: datasource=github-releases depName=arkuznetsov/yard
variable "YARD_VERSION" { default = "1.12.0" }
# renovate: datasource=github-releases depName=EvilBeaver/OneScript
variable "ONESCRIPT_VERSION" { default = "2.1.0" }
# renovate: datasource=github-releases depName=oscript-library/ovm
variable "OVM_VERSION" { default = "1.6.2" }

variable "EXECUTOR_VERSION" { default = "3.0.2.2" }

# renovate: datasource=github-releases depName=1c-syntax/Coverage41C
variable "COVERAGE41C_VERSION" { default = "2.7.3" }
# renovate: datasource=java-version depName=java
variable "OPENJDK_VERSION" { default = "17" }
# renovate: datasource=github-releases depName=oscript-library/gitsync
variable "GITSYNC_VERSION" { default = "3.7.3" }
# renovate: datasource=github-releases depName=vanessa-opensource/vanessa-runner
variable "VANESSA_RUNNER_VERSION" { default = "1.7.0" }
# renovate: datasource=github-releases depName=just-containers/s6-overlay
variable "S6_OVERLAY_VERSION" { default = "3.2.2.0" }
# renovate: datasource=maven depName=jenkinsci/remoting packageName=org.jenkins-ci.main:remoting
variable "JENKINS_REMOTING_VERSION" { default = "3283.v92c105e0f819" }
# renovate: datasource=github-releases depName=tianon/gosu
variable "GOSU_VERSION" { default = "1.11" }
