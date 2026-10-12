"""Local catalog files that are not valid JSON."""

from __future__ import annotations

import pytest

from skore_cli.skills._store import SkillStoreError, read_local_catalog


def test_read_local_catalog_rejects_malformed_json(tmp_path):
    catalog = tmp_path / ".catalog.json"
    catalog.write_text("{not json\n")

    with pytest.raises(SkillStoreError, match="could not parse"):
        read_local_catalog(tmp_path)
