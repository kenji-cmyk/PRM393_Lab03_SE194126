"""Offline harness regressions: no daemon, ADB or model dependencies."""
import asyncio
import json
from types import SimpleNamespace

import pytest

from .cases import CASES
from .harness import ARTEMIS_COMMIT, Case, Runner, analytics_event_seen, assert_observed, parse_observed, summarize, validate_endpoint, verify_sdk_pin


@pytest.mark.parametrize('output', [
    {'observed': {'count': 1}}, '{"observed":{"count":1}}',
    '```json\n{"observed":{"count":1}}\n```',
])
def test_parse_real_sdk_output_forms(output):
    assert parse_observed(output) == {'count': 1}


@pytest.mark.parametrize('output', ['SUCCESS', {'status': 'success'}, {'observed': []}, None])
def test_status_alone_or_malformed_output_cannot_pass(output):
    with pytest.raises((AssertionError, ValueError)):
        parse_observed(output)


@pytest.mark.parametrize('actual', [{'count': True}, {'count': '1'}, {}, {'count': 2}])
def test_wrong_observation_and_type_cannot_pass(actual):
    with pytest.raises(AssertionError):
        assert_observed(actual, {'count': 1})


def test_skipped_cases_have_no_pass_rate_or_fake_duration():
    summary = summarize([{'case': 'one', 'outcome': 'skipped', 'seconds': 0.01}])
    assert summary['one']['pass_rate'] is None
    assert summary['one']['mean_seconds'] is None
    assert summary['one']['passed'] == 0
    assert summary['one']['needs_investigation'] is True


def test_pass_rate_excludes_skips_and_marks_failures():
    summary = summarize([
        {'case': 'one', 'outcome': 'passed', 'seconds': 10},
        {'case': 'one', 'outcome': 'failed', 'seconds': 20},
        {'case': 'one', 'outcome': 'skipped'},
    ])['one']
    assert summary['pass_rate'] == .5
    assert summary['mean_seconds'] == 15
    assert summary['skipped'] == 1


@pytest.mark.parametrize('endpoint', ['http://remote:8000', 'file:///tmp', 'https://user:secret@host', 'https://host?token=secret'])
def test_insecure_or_credentialed_daemon_url_rejected(endpoint):
    with pytest.raises(ValueError):
        validate_endpoint(endpoint)


def test_auth_proxy_and_local_tunnel_supported():
    assert validate_endpoint('http://127.0.0.1:8000/') == 'http://127.0.0.1:8000'
    assert validate_endpoint('https://daemon.example.test') == 'https://daemon.example.test'


def test_installed_sdk_provenance_must_match_pinned_commit():
    verify_sdk_pin(json.dumps({'vcs_info': {'commit_id': ARTEMIS_COMMIT}}))
    for metadata in [None, '{}', json.dumps({'vcs_info': {'commit_id': 'unverified'}})]:
        with pytest.raises(ValueError):
            verify_sdk_pin(metadata)


class Client:
    def __init__(self, *, failed=False, timeout=False):
        self.failed = failed
        self.timeout = timeout
        self.stopped = False
        self.submission = None

    async def submit(self, goal, **kwargs):
        self.submission = kwargs
        return SimpleNamespace(task_id='synthetic-offline-trace')

    async def wait_for_task(self, task_id, *, timeout):
        if self.timeout:
            raise TimeoutError('synthetic failure')
        return SimpleNamespace(done=True, succeeded=not self.failed,
                               status='failed' if self.failed else 'completed',
                               output={'observed': {'count': 1}, 'secret_extra': 'must not persist'})

    async def stop(self, task_id):
        self.stopped = True


def test_runner_asserts_structured_output_and_saves_trace(tmp_path):
    client = Client()
    runner = Runner(client, 'offline-device', 'test alias', tmp_path)
    runner.run(Case('OFFLINE', 'preview', 'Inspect counter.', {'count': 1}), 1)
    artifact = json.loads(next(tmp_path.glob('*.json')).read_text())
    assert artifact['outcome'] == 'passed'
    assert artifact['trace_id'] == 'synthetic-offline-trace'
    assert artifact['observed'] == {'count': 1}
    assert 'secret_extra' not in json.dumps(artifact)
    assert client.submission['enable_outputter'] is True
    assert client.submission['profile'] == 'flash'


def test_failed_task_is_not_a_pass_and_evidence_is_kept(tmp_path):
    runner = Runner(Client(failed=True), 'offline-device', 'alias', tmp_path)
    with pytest.raises(AssertionError):
        runner.run(Case('OFFLINE', 'preview', 'Inspect.', {'count': 1}), 1)
    assert runner.records[0]['outcome'] == 'failed'
    assert runner.records[0]['trace_id'] == 'synthetic-offline-trace'


def test_timed_out_task_is_stopped_and_recorded(tmp_path):
    client = Client(timeout=True)
    runner = Runner(client, 'offline-device', 'alias', tmp_path)
    with pytest.raises(TimeoutError):
        runner.run(Case('OFFLINE', 'preview', 'Inspect.', {'count': 1}), 1)
    assert client.stopped is True
    assert runner.records[0]['error_type'] == 'TimeoutError'


def test_catalogue_has_independent_cases_and_native_error_analytics_coverage():
    assert len(CASES) >= 10
    assert len({case.id for case in CASES.values()}) == len(CASES)
    assert CASES['PROFILE-01'].setup == 'welcome'
    assert CASES['NOTIFY-01'].mode == 'cloud'
    assert CASES['ANALYTICS-01'].analytics_event == 'meal_entry_start'


def test_analytics_log_requires_exact_event_and_actual_firebase_tag():
    assert analytics_event_seen(['11-09 10:00:00 D FA: Logging event: meal_entry_start'], 'meal_entry_start')
    assert not analytics_event_seen(['D FA: not_meal_entry_start'], 'meal_entry_start')
    assert not analytics_event_seen(['I unrelated: meal_entry_start'], 'meal_entry_start')


def test_analytics_rejects_stale_log_lines_even_if_agent_reports_success(tmp_path):
    log = tmp_path / 'logcat.txt'
    log.write_text('D FA: Logging event: meal_entry_start\n')
    runner = Runner(Client(), 'offline-device', 'alias', tmp_path / 'evidence', analytics_log=log)
    with pytest.raises(AssertionError, match='absent from new'):
        runner.run(Case('OFFLINE', 'cloud', 'Inspect.', {'count': 1}, analytics_event='meal_entry_start'), 1)
    assert runner.records[0]['outcome'] == 'failed'
