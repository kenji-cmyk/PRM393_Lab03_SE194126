"""Native permission, Remote Config and independently captured Analytics."""
import pytest
from .cases import CASES

pytestmark = pytest.mark.artemis


@pytest.mark.parametrize('case_id', ['NOTIFY-01', 'CONFIG-01', 'CONFIG-02', 'ANALYTICS-01'])
def test_firebase_behavior(run_case, case_id):
    run_case(CASES[case_id])
