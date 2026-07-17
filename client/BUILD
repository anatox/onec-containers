# pyright: reportUndefinedVariable=false

files(name="context", sources=["configs/**"])

files(name="runtime-deps", sources=["packages.txt"])

for platform_version in PLATFORM_VERSIONS:
    docker_image(
        name=f"onec-client-{platform_version}",
        source="Containerfile",
        target_stage="client",
        repository="onec-client",
        context_root=".",
        dependencies=[":context", ":runtime-deps", "//distr:distr", "//scripts:installer", "//installer:onec-installer"],
        extra_build_args=[
            f"ONEC_VERSION={platform_version}",
            f"NLS_ENABLED={env('NLS_ENABLED', 'false')}",
        ],
        secrets={"secrets_env": "secrets.env"},
        image_tags=[platform_version]
            + ([f"{platform_version}-g{git_sha_short()}"] if git_sha_short() else ["local"])
            + (["latest"] if docker_publish_latest() == "true" and platform_version == max(PLATFORM_VERSIONS) else []),
        image_labels=std_labels("1C:Enterprise client"),
        **cache_args(docker_cache_prefix(), "onec-client"),
    )
    docker_image(
        name=f"client-toolbox-{platform_version}",
        source="Containerfile",
        target_stage="toolbox",
        repository="client-toolbox",
        context_root=".",
        dependencies=[":context", ":runtime-deps", "//distr:distr", "//scripts:installer",
                      "//scripts:distrobox-shims", "//installer:onec-installer"],
        extra_build_args=[
            f"ONEC_VERSION={platform_version}",
            f"NLS_ENABLED={env('NLS_ENABLED', 'false')}",
            "BASE_IMAGE=quay.io/toolbx/ubuntu-toolbox:26.04",
        ],
        secrets={"secrets_env": "secrets.env"},
        image_tags=[platform_version] + ([f"{platform_version}-g{git_sha_short()}"] if git_sha_short() else ["local"])
            + (["latest"] if docker_publish_latest() == "true" and platform_version == max(PLATFORM_VERSIONS) else []),
        image_labels=std_labels("1C:Enterprise client toolbox for distrobox/toolbx"),
        **cache_args(docker_cache_prefix(), "client-toolbox"),
    )
