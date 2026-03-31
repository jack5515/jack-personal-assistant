import unittest
from unittest import mock

from workbench_core import core, verify


class WorkbenchCoreTests(unittest.TestCase):
    def test_load_manifest_has_workbench_name(self):
        manifest = core.load_manifest()
        self.assertEqual(core.workbench_name(manifest), 'jack-personal-assistant')

    def test_runtime_patterns_include_state_and_delivery_rules(self):
        manifest = {
            'layers': {
                'state': ['memory/*-state.json', 'memory/channel-handoff.md'],
                'delivery': ['workfiles/*-latest.md'],
            }
        }
        patterns = core.runtime_patterns(manifest)
        self.assertIn(r'^logs/', patterns)
        self.assertIn(r'^memory/.*\-state\.json$', patterns)
        self.assertIn(r'^memory/channel\-handoff\.md$', patterns)
        self.assertIn(r'^workfiles/.*\-latest\.md$', patterns)

    @mock.patch('workbench_core.core.latest_log_line')
    @mock.patch('workbench_core.core.exists')
    def test_status_payload_contains_capabilities_and_logs(self, mock_exists, mock_latest_log_line):
        mock_exists.return_value = True
        mock_latest_log_line.return_value = 'ok'
        manifest = {
            'workbench': {'name': 'demo'},
            'coreFiles': [{'name': 'README', 'path': 'README.md'}],
            'layers': {'execution': ['a'], 'state': ['b'], 'knowledge': [], 'delivery': []},
            'capabilities': [
                {
                    'name': 'demo-cap',
                    'status': '已验证',
                    'entry': 'scripts/demo.sh',
                    'verify': 'scripts/workbench-verify.sh demo',
                    'logs': ['logs/demo.log'],
                }
            ],
        }
        payload = core.status_payload(manifest, 'now')
        self.assertEqual(payload['generatedAt'], 'now')
        self.assertTrue(payload['coreFiles']['README'])
        self.assertEqual(payload['capabilities']['demo-cap']['status'], '已验证')
        self.assertEqual(payload['recentLogs']['demo-cap']['logs/demo.log'], 'ok')

    @mock.patch('workbench_core.core.latest_log_line')
    @mock.patch('workbench_core.core.exists')
    def test_render_summary_mentions_capability_and_verify(self, mock_exists, mock_latest_log_line):
        mock_exists.return_value = True
        mock_latest_log_line.return_value = 'latest'
        manifest = {
            'workbench': {'name': 'demo'},
            'coreFiles': [{'name': 'README', 'path': 'README.md'}],
            'layers': {'execution': ['x'], 'state': [], 'knowledge': [], 'delivery': []},
            'capabilities': [
                {
                    'name': 'demo-cap',
                    'status': '部分可用',
                    'entry': 'scripts/demo.sh',
                    'verify': 'scripts/workbench-verify.sh demo',
                    'logs': ['logs/demo.log'],
                }
            ],
        }
        summary = core.render_summary(manifest)
        self.assertIn('Workbench: demo', summary)
        self.assertIn('demo-cap [部分可用]', summary)
        self.assertIn('verify: scripts/workbench-verify.sh demo', summary)
        self.assertIn('latest log: logs/demo.log: latest', summary)

    @mock.patch('subprocess.check_output')
    def test_runtime_residue_matches_filters_git_status(self, mock_check_output):
        mock_check_output.return_value = ' M memory/demo-state.json\n M README.md\n?? workfiles/demo-latest.md\n'
        manifest = {
            'layers': {
                'state': ['memory/*-state.json'],
                'delivery': ['workfiles/*-latest.md'],
            }
        }
        matches = core.runtime_residue_matches(manifest)
        self.assertEqual(matches, [' M memory/demo-state.json', '?? workfiles/demo-latest.md'])


class WorkbenchVerifyTests(unittest.TestCase):
    @mock.patch('workbench_core.verify.verify_docs')
    @mock.patch('workbench_core.verify.verify_dual_channel')
    @mock.patch('workbench_core.verify.verify_lenny')
    @mock.patch('workbench_core.verify.verify_stock_finance')
    @mock.patch('workbench_core.verify.verify_ai_trend')
    @mock.patch('workbench_core.verify.verify_vision')
    @mock.patch('workbench_core.verify.verify_summary')
    def test_verify_all_calls_all_handlers(
        self,
        mock_summary,
        mock_vision,
        mock_ai,
        mock_stock,
        mock_lenny,
        mock_dual,
        mock_docs,
    ):
        verify.verify('all')
        mock_docs.assert_called_once()
        mock_dual.assert_called_once()
        mock_lenny.assert_called_once()
        mock_stock.assert_called_once()
        mock_ai.assert_called_once()
        mock_vision.assert_called_once()
        mock_summary.assert_called_once()

    def test_verify_unknown_capability_raises(self):
        with self.assertRaises(verify.VerifyError):
            verify.verify('unknown')


if __name__ == '__main__':
    unittest.main()
