def secrets_file(name: str) -> str:
    return name


def std_labels(title: str) -> dict[str, str]:
    return {
        "org.opencontainers.image.vendor": env("GITHUB_REPOSITORY_OWNER", "local"),
        "org.opencontainers.image.source": (
            "https://github.com/" + env("GITHUB_REPOSITORY", "")
            if env("GITHUB_REPOSITORY", "")
            else "local"
        ),
        "org.opencontainers.image.title": title,
    }


def cache_args(prefix: str, name: str) -> dict:
    if not prefix:
        return {}
    ref = prefix + "/" + name + ":main"
    return {
        "cache_to": {"type": "registry", "ref": ref, "mode": "max"},
        "cache_from": [{"type": "registry", "ref": ref}],
    }
