import unittest

from validate_target_version_pr import PolicyError, validate


class DeliveryUnitNameTests(unittest.TestCase):
    def test_accepts_registered_delivery_unit_with_underscore(self):
        config = {
            "allowed_actor_prefixes": ["codex"],
            "delivery_units": {
                "agent_api_cli": {
                    "profile": "package-or-local",
                    "mode": "continuous",
                    "active_versions": ["0.1.0"],
                    "target_version_source": ".byungskerlab/release-lines.json",
                    "production_branch": "main",
                    "allowed_paths": ["agent-api/**"],
                },
            },
        }
        registry = {
            "delivery_units": {
                "agent_api_cli": {
                    "active_versions": ["0.1.0"],
                },
            },
        }
        result = validate(
            config,
            "codex/feature/agent_api_cli/0.1.0/contract",
            "main",
            "Target-Delivery-Unit: agent_api_cli\n"
            "Target-Version: 0.1.0\n"
            "Delivery-Profile: package-or-local\n",
            ["agent-api/README.md"],
            registry,
        )
        self.assertIn("agent_api_cli", result)

    def test_rejects_explicit_empty_version_path_override(self):
        config = {
            "allowed_actor_prefixes": ["codex"],
            "delivery_units": {
                "agent_api_cli": {
                    "profile": "package-or-local",
                    "mode": "continuous",
                    "active_versions": ["0.1.0"],
                    "target_version_source": ".byungskerlab/release-lines.json",
                    "production_branch": "main",
                    "allowed_paths": ["agent-api/**"],
                    "additional_allowed_paths_by_version": {"0.1.0": []},
                },
            },
        }
        registry = {
            "delivery_units": {
                "agent_api_cli": {
                    "active_versions": ["0.1.0"],
                },
            },
        }
        with self.assertRaisesRegex(
            PolicyError, "invalid additional paths for 0.1.0"
        ):
            validate(
                config,
                "codex/feature/agent_api_cli/0.1.0/contract",
                "main",
                "Target-Delivery-Unit: agent_api_cli\n"
                "Target-Version: 0.1.0\n"
                "Delivery-Profile: package-or-local\n",
                ["supabase/migrations/20260910000000_progress.sql"],
                registry,
            )


if __name__ == "__main__":
    unittest.main()
