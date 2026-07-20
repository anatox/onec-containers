target "oscript" { inherits = ["oscript"] }
target "installer" { inherits = ["installer"] }
target "oscript-jdk" { inherits = ["oscript-jdk"] }
target "oscript-jdk-s6" { inherits = ["oscript-jdk-s6"] }
target "server" { inherits = ["server"] }
target "client" { inherits = ["client"] }
target "thin-client" { inherits = ["thin-client"] }
target "crs" { inherits = ["crs"] }
target "crs-apache" { inherits = ["crs-apache"] }
target "edt" { inherits = ["edt"] }
target "edt-s6" { inherits = ["edt-s6"] }
target "client-s6" { inherits = ["client-s6"] }
target "client-vnc" { inherits = ["client-vnc"] }
target "client-vnc-oscript" { inherits = ["client-vnc-oscript"] }
target "client-vnc-oscript-jdk" { inherits = ["client-vnc-oscript-jdk"] }
target "vanessa-automation" { inherits = ["vanessa-automation"] }
target "gitsync" { inherits = ["gitsync"] }
target "vanessa-runner" { inherits = ["vanessa-runner"] }
target "executor" { inherits = ["executor"] }

group "default" {
  targets = [
    "base-jenkins-agent",
    "client",
    "client-s6",
    "client-vnc",
    "client-vnc-oscript",
    "client-vnc-oscript-jdk",
    "coverage-agent",
    "crs",
    "crs-apache",
    "edt",
    "edt-agent",
    "edt-s6",
    "executor",
    "gitsync",
    "installer",
    "oscript",
    "oscript-agent",
    "oscript-jdk",
    "oscript-jdk-s6",
    "server",
    "thin-client",
    "vanessa-automation",
    "vanessa-runner",
  ]
}

group "publish" {
  targets = [
    "base-jenkins-agent",
    "client",
    "client-vnc",
    "coverage-agent",
    "crs",
    "crs-apache",
    "edt",
    "edt-agent",
    "executor",
    "gitsync",
    "installer",
    "oscript",
    "oscript-agent",
    "server",
    "thin-client",
    "vanessa-runner",
  ]
}
