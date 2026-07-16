GIT_SHA = env("GIT_SHA", "")
GIT_SHA_SHORT = GIT_SHA[:7] if GIT_SHA else ""
NLS_ENABLED = env("NLS_ENABLED", "false")
PUBLISH_LATEST = env("PUBLISH_LATEST", "false")
CACHE_PREFIX = env("PANTS_DOCKER_CACHE_PREFIX", "")

files(name="context", sources=["entrypoint.sh", "logcfg.xml"])

for platform_version in PLATFORM_VERSIONS:
    docker_image(
        name=f"onec-server-{platform_version}",
        source="Containerfile",
        repository="onec-server",
        context_root=".",
        dependencies=[":context", "//distr:distr", "//scripts:installer", "//installer:onec-installer"],
        extra_build_args=[
            f"ONEC_VERSION={platform_version}",
            f"NLS_ENABLED={NLS_ENABLED}",
        ],
        secrets={"releases_env": secrets_file("releases.env")},
        image_tags=[platform_version]
            + ([f"{platform_version}-g{GIT_SHA_SHORT}"] if GIT_SHA_SHORT else ["local"])
            + (["latest"] if PUBLISH_LATEST == "true" and platform_version == max(PLATFORM_VERSIONS) else []),
        image_labels=std_labels("1C:Enterprise server"),
        **cache_args(CACHE_PREFIX, "onec-server"),
    )
