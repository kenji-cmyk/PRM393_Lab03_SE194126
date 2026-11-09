"""Profile validation, persistence and draft/back behavior."""
import pytest
from .cases import CASES

pytestmark = pytest.mark.artemis


@pytest.mark.parametrize('case_id', ['PROFILE-01', 'PROFILE-02', 'PROFILE-03'])
def test_onboarding_profile(run_case, case_id):
    run_case(CASES[case_id])
