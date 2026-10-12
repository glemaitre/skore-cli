"""Credential failures reported by the hub helper."""

from __future__ import annotations

from types import SimpleNamespace

import pytest

from skore_cli._credentials import HubError, mint_api_key


def test_mint_api_key_reports_an_existing_key(monkeypatch):
    key_exists = type("KeyExistsError", (Exception,), {})

    def generate(**kwargs):
        raise key_exists()

    monkeypatch.setattr(
        "skore_cli._credentials._hub_key",
        lambda: SimpleNamespace(KeyExistsError=key_exists, generate=generate),
    )

    with pytest.raises(HubError, match="already stored"):
        mint_api_key(
            host=None,
            workspace="ws-1",
            name=None,
            expires="never",
            timeout=1,
            force=False,
        )


def test_mint_api_key_reports_permission_errors(monkeypatch):
    def generate(**kwargs):
        raise PermissionError("denied")

    key_exists = type("KeyExistsError", (Exception,), {})
    monkeypatch.setattr(
        "skore_cli._credentials._hub_key",
        lambda: SimpleNamespace(KeyExistsError=key_exists, generate=generate),
    )

    with pytest.raises(HubError, match="denied"):
        mint_api_key(
            host=None,
            workspace="ws-1",
            name=None,
            expires="never",
            timeout=1,
            force=False,
        )
