# pyright: reportUndefinedVariable=false

for platform_version in PLATFORM_VERSIONS:
    docker_image(
        name=f"onec-thin-client-{platform_version}",
        source="Containerfile",
        repository="onec-thin-client",
        context_root=".",
        dependencies=["//distr:distr", "//scripts:installer", "//installer:onec-installer"],
        extra_build_args=[
            f"ONEC_VERSION={platform_version}",
            f"NLS_ENABLED={env('NLS_ENABLED', 'false')}",
        ],
        secrets={"secrets_env": "secrets.env"},
        image_tags=[platform_version]
            + ([f"{platform_version}-g{GIT_SHA_SHORT}"] if GIT_SHA_SHORT else ["local"])
            + (["latest"] if PUBLISH_LATEST == "true" and platform_version == max(PLATFORM_VERSIONS) else []),
        image_labels=std_labels("1C:Enterprise thin client"),
        **cache_args(CACHE_PREFIX, "onec-thin-client"),
    )
