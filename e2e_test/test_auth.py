"""Cloud account chooser and session isolation."""
import pytest
from .cases import CASES

pytestmark = pytest.mark.artemis


@pytest.mark.parametrize('case_id', ['AUTH-01', 'AUTH-02'])
def test_google_auth(run_case, case_id):
    run_case(CASES[case_id])
