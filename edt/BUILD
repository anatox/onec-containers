# pyright: reportUndefinedVariable=false

files(name="context", sources=["*.sh"])

files(name="runtime-deps", sources=["packages.txt"])

for edt_version in EDT_VERSIONS:
    docker_image(
        name=f"edt-{edt_version}",
        source="Containerfile",
        target_stage="edt",
        repository="edt",
        context_root=".",
        dependencies=[":context", ":runtime-deps", "//distr:distr", "//scripts:installer", "//installer:onec-installer"],
        extra_build_args=[f"EDT_VERSION={edt_version}"],
        secrets={"secrets_env": "secrets.env"},
        image_tags=[edt_version] + ([f"{edt_version}-g{git_sha_short()}"] if git_sha_short() else ["local"])
            + (["latest"] if docker_publish_latest() == "true" and edt_version == max(EDT_VERSIONS) else []),
        image_labels=std_labels("1C:EDT"),
        **cache_args(docker_cache_prefix(), "edt"),
    )
    for platform_version in PLATFORM_VERSIONS:
        docker_image(
            name=f"edt-toolbox-{edt_version}-client-{platform_version}",
            source="Containerfile",
            target_stage="toolbox-client",
            repository="edt-toolbox",
            context_root=".",
            dependencies=[":context", ":runtime-deps", "//distr:distr", "//scripts:installer",
                          "//scripts:distrobox-shims", "//installer:onec-installer",
                          "//client:runtime-deps", f"//client:onec-client-{platform_version}"],
            extra_build_args=[
                f"EDT_VERSION={edt_version}",
                "BASE_IMAGE=quay.io/toolbx/ubuntu-toolbox:26.04",
                f"CLIENT_IMAGE=client:onec-client-{platform_version}",
            ],
            secrets={"secrets_env": "secrets.env"},
            image_tags=[f"{edt_version}-client{platform_version}"]
                + ([f"{edt_version}-client{platform_version}-g{git_sha_short()}"] if git_sha_short() else ["local"])
                + (["latest"] if docker_publish_latest() == "true" and edt_version == max(EDT_VERSIONS)
                   and platform_version == max(PLATFORM_VERSIONS) else []),
            image_labels=std_labels("1C:EDT + client toolbox for distrobox/toolbx"),
            **cache_args(docker_cache_prefix(), "edt-toolbox"),
        )
