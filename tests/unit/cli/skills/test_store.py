"""Local catalog files that are not valid JSON."""

from __future__ import annotations

import pytest

from skore_cli.skills._store import (
    SkillStoreError,
    install_skill,
    installed,
    read_local_catalog,
)


def test_read_local_catalog_rejects_malformed_json(tmp_path):
    catalog = tmp_path / ".catalog.json"
    catalog.write_text("{not json\n")

    with pytest.raises(SkillStoreError, match="could not parse"):
        read_local_catalog(tmp_path)


def test_read_local_catalog_rejects_non_object(tmp_path):
    (tmp_path / ".catalog.json").write_text("[]\n")

    with pytest.raises(SkillStoreError, match="JSON object"):
        read_local_catalog(tmp_path)


def test_installed_rejects_sidecar_without_id(tmp_path):
    skill = tmp_path / "alpha"
    skill.mkdir()
    (skill / ".skore-skill.json").write_text("[]\n")

    with pytest.raises(SkillStoreError, match="object with an id"):
        list(installed(tmp_path))


def test_install_skill_keeps_existing_directory_when_copy_fails(tmp_path):
    target = tmp_path / "skills"
    destination = target / "alpha"
    destination.mkdir(parents=True)
    (destination / "SKILL.md").write_text("old")
    root = tmp_path / "release"
    root.mkdir()

    with pytest.raises(FileNotFoundError):
        install_skill(
            {"id": "alpha", "path": "missing", "hash": "h"},
            root,
            target,
            "v1",
            "owner/name",
        )

    assert (destination / "SKILL.md").read_text() == "old"
