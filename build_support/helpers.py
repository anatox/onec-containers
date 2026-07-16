def secrets_file(name: str) -> str:
    return name


def _git_remote_url() -> str:
    try:
        subprocess = __import__("subprocess")
        url = subprocess.run(
            ["git", "remote", "get-url", "origin"],
            capture_output=True, text=True, timeout=5,
        ).stdout.strip()
        if url:
            if url.startswith("git@"):
                url = "https://" + url.split("@")[1].replace(":", "/")
            if url.endswith(".git"):
                url = url[:-4]
            return url
    except Exception:
        pass
    return ""


def std_labels(title: str) -> dict[str, str]:
    labels: dict[str, str] = {"org.opencontainers.image.title": title}
    vendor = env("GIT_OWNER", "")
    if vendor:
        labels["org.opencontainers.image.vendor"] = vendor
    source = env("GIT_URL", "") or _git_remote_url()
    if source:
        labels["org.opencontainers.image.source"] = source
    return labels


def cache_args(prefix: str, name: str) -> dict:
    if not prefix:
        return {}
    ref = prefix + "/" + name + ":main"
    return {
        "cache_to": {"type": "registry", "ref": ref, "mode": "max"},
        "cache_from": [{"type": "registry", "ref": ref}],
    }
